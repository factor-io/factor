# encoding: UTF-8

require 'securerandom'
require 'yaml'
require 'eventmachine'
require 'uri'
require 'faye/websocket'

require 'listener'
require 'commands/base'
require 'common/deep_struct'
require 'runtime/service_caller'

module Factor
  # Runtime class is the magic of the server

  class ExecHandler
    attr_accessor :params, :service, :fail_block

    def initialize(service = nil, params = {})
      @service = service
      @params = params
    end

    def on_fail(&block)
      @fail_block = block
    end
  end

  class Workflow
    attr_accessor :name, :description, :id, :instance_id, :connectors, :credentials

    def initialize(connectors, credentials, options={})
      @workflow_spec  = {}
      @sockets        = []
      @workflows      = {}
      @instance_id    = SecureRandom.hex(3)
      @reconnect      = true
      @logger         = options[:logger] if options[:logger]

      trap 'SIGINT' do
        @logger.info "Exiting '#{@instance_id}'"
        @reconnect = false
        @sockets.each { |s| s.close }
        exit
      end

      # @connectors = {}
      # Factor::Common.flat_hash(connectors).each do |key, connector_url|
      #   @connectors[key] = Listener.new(connector_url)
      # end
      @connectors = Factor::Common.flat_hash(connectors)

      @credentials = {}
      credentials.each do |connector_id, credential_settings|
        @credentials[connector_id] = credential_settings
      end
    end

    def load(workflow_definition)
      EM.run do
        instance_eval(workflow_definition)
      end
    end

    def listen(service_ref, params = {}, &block)
      service_map = service_ref.split('::') 
      service_id = service_map.first
      listener_id = service_map.last
      service_key = service_map[0..-2].map{|k| k.to_sym}

      e = ExecHandler.new(service_ref, params)

      service = @connectors[service_key]

      if !service
        @logger.error "Listener '#{service_ref}' not found"
        e.fail_block.call({}) if e.fail_block
      else
        ws = service.listener(listener_id)

        handle_on_open(service_ref, 'Listener', ws, params)

        ws.on :close do
          @logger.error 'Listener disconnected'
          if @reconnect
            @logger.warn 'Reconnecting...'
            sleep 3
            ws.open
          end
        end

        ws.on :message do |event|
          listener_response = JSON.parse(event.data)
          case listener_response['type']
          when'start_workflow'
            @logger.success "Workflow '#{service_id}::#{listener_id}' triggered"
            error_handle_call(listener_response, &block)
          when 'return'
            @logger.success "Workflow '#{service_ref}' started"
          when 'fail'
            e.fail_block.call(action_response) if e.fail_block
            @logger.error "Workflow '#{service_ref}' failed to start"
          when 'log'
            listener_response['message'] = "  #{listener_response['message']}"
            @logger.log listener_response
          else
            @logger.error "Unknown listener response: #{listener_response}"
          end
        end

        ws.on :retry do |event|
          @logger.warn event[:message]
        end

        ws.on :error do |event|
          err = 'Error during WebSocket handshake: Unexpected response code: 401'
          if event.message == err
            @logger.error "Sorry but you don't have access to this listener,
              | either because your token is invalid or your plan doesn't
              | support this listener"
          else
            @logger.error 'Failure in WebSocket connection to connector service'
          end
        end

        ws.open

        @sockets << ws
      end
      
      e
    end

    def workflow(service_ref, &block)
      service_map = service_ref.split('::')
      @workflows ||= {}
      @workflows[service_map] = block
    end

    def run(service_ref, params = {}, &block)
      service_map = service_ref.split('::') 
      service_id = service_map.first
      action_id = service_map.last      

      e = ExecHandler.new(service_ref, params)

      if service_id == 'workflow'
        workflow_index = service_map[1..-1]
        workflow_id = workflow_index.join('::')
        workflow = @workflows[workflow_index]
        if workflow
          @logger.success "Workflow '#{workflow_id}' starting"
          content = simple_object_convert(params)
          workflow.call(content)
          @logger.success "Workflow '#{workflow_id}' started"
        else
          @logger.error "Workflow '#{workflow_id}' not found"
          e.fail_block.call({}) if e.fail_block
        end
      else
        service_key = service_map[0..-2].map{|k| k.to_sym}
        # service = @connectors[service_key]
        # if service
        #   ws = service.action(action_id)

        #   handle_on_open(service_ref, 'Action', ws, params)

        #   ws.on :error do
        #     @logger.error 'Connection dropped while calling action'
        #   end

        #   ws.on :message do |event|
        #     action_response = JSON.parse(event.data)
        #     case action_response['type']
        #     when 'return'
        #       ws.close
        #       @logger.success "Action '#{service_ref}' responded"
        #       error_handle_call(action_response, &block)
        #     when 'fail'
        #       e.fail_block.call(action_response) if e.fail_block
        #       ws.close
        #       @logger.error "  #{action_response['message']}"
        #       @logger.error "Action '#{service_ref}' failed"
        #     when 'log'
        #       action_response['message'] = "  #{action_response['message']}"
        #       @logger.log action_response
        #     else
        #       @logger.error "Unknown action response: #{action_response}"
        #     end
        #   end

        #   ws.open

        #   @sockets << ws
        # end

        connector_url = @connectors[service_key]

        caller = Factor::Runtime::ServiceCaller.new(connector_url)

        caller.on :open do
          @logger.info "Action '#{service_ref}' starting"
        end

        caller.on :error do
          @logger.error 'Connection dropped while calling action'
        end

        caller.on :return do |data|
          @logger.success "Action '#{service_ref}' responded"
          block.call(simple_object_convert(data))
        end

        caller.on :fail do |info|
          @logger.error "Action '#{service_ref}' failed"
          e.fail_block.call(action_response) if e.fail_block
        end

        caller.on :log do |log_info|
          @logger.log log_info[:status], log_info
        end

        caller.action(action_id,params)
      end
      e
    end

    def info(message)
      @logger.info message
    end

    def warn(message)
      @logger.warn message
    end

    def error(message)
      @logger.error message
    end

    private

    def handle_on_open(service_ref, dsl_type, ws, params)
      service_map = service_ref.split('::') 
      service_id = service_map.first

      ws.on :open do
        params.merge!(@credentials[service_id.to_sym] || {})
        @logger.success "#{dsl_type.capitalize} '#{service_ref}' called"
        ws.send(params)
      end
    end

    def error_handle_call(listener_response, &block)
      content = simple_object_convert(listener_response['payload'])
      block.call(content) if block
    rescue => ex
      @logger.error "Error in workflow definition: #{ex.message}", exception: ex
    end

  end
end
