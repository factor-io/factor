# encoding: UTF-8

require 'json'
require 'securerandom'
require 'yaml'
require 'eventmachine'
require 'uri'
require 'faye/websocket'
require 'ostruct'

require 'listener'
require 'commands/base'

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

  class Runtime
    attr_accessor :logger, :name, :description, :id, :instance_id, :connectors, :credentials

    def initialize(connectors, credentials)
      @workflow_spec  = {}
      @sockets        = []
      @instance_id    = SecureRandom.hex(3)
      @reconnect      = true

      trap 'SIGINT' do
        info "Exiting '#{@instance_id}'"
        @reconnect = false
        @sockets.each { |s| s.close }
        exit
      end

      @connectors = {}
      flat_hash(connectors).each do |key, connector_url|
        @connectors[key] = Listener.new(connector_url)
      end

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

      ws = @connectors[service_key].listener(listener_id)

      handle_on_open(service_ref, 'Listener', ws, params)

      ws.on :close do
        error 'Listener disconnected'
        if @reconnect
          warn 'Reconnecting...'
          sleep 3
          ws.open
        end
      end

      ws.on :message do |event|
        listener_response = JSON.parse(event.data)
        case listener_response['type']
        when'start_workflow'
          success "Workflow '#{service_id}::#{listener_id}' triggered"
          error_handle_call(listener_response, &block)
        when 'return'
          success "Workflow '#{service_ref}' started"
        when 'fail'
          e.fail_block.call(action_response) if e.fail_block
          error "Workflow '#{service_ref}' failed to start"
        when 'log'
          listener_response['message'] = "  #{listener_response['message']}"
          log_message(listener_response)
        else
          error "Unknown listener response: #{listener_response}"
        end
      end

      ws.on :retry do |event|
        warn event[:message]
      end

      ws.on :error do |event|
        err = 'Error during WebSocket handshake: Unexpected response code: 401'
        if event.message == err
          error "Sorry but you don't have access to this listener,
            | either because your token is invalid or your plan doesn't
            | support this listener"
        else
          error 'Failure in WebSocket connection to connector service'
        end
      end

      ws.open

      @sockets << ws
      
      e
    end

    def run(service_ref, params = {}, &block)
      service_map = service_ref.split('::') 
      service_id = service_map.first
      action_id = service_map.last
      service_key = service_map[0..-2].map{|k| k.to_sym}

      ws = @connectors[service_key].action(action_id)

      e = ExecHandler.new(service_ref, params)

      handle_on_open(service_ref, 'Action', ws, params)

      ws.on :error do
        error 'Connection dropped while calling action'
      end

      ws.on :message do |event|
        action_response = JSON.parse(event.data)
        case action_response['type']
        when 'return'
          ws.close
          success "Action '#{service_ref}' responded"
          error_handle_call(action_response, &block)
        when 'fail'
          e.fail_block.call(action_response) if e.fail_block
          ws.close
          error "  #{action_response['message']}"
          error "Action '#{service_ref}' failed"
        when 'log'
          action_response['message'] = "  #{action_response['message']}"
          log_message(action_response)
        else
          error "Unknown action response: #{action_response}"
        end
      end

      ws.open

      @sockets << ws
      e
    end

    private

    class DeepStruct < OpenStruct
      def initialize(hash=nil)
        @table = {}
        @hash_table = {}

        if hash
          hash.each do |k,v|
            @table[k.to_sym] = (v.is_a?(Hash) ? self.class.new(v) : v)
            @hash_table[k.to_sym] = v

            new_ostruct_member(k)
          end
        end
      end

      def to_h
        @hash_table
      end

      def [](idx)
        hash = marshal_dump
        hash[idx.to_sym]
      end
    end

    def simple_object_convert(item)
      if item.is_a?(Hash)
        DeepStruct.new(item)
      elsif item.is_a?(Array)
        item.map do |i|
          simple_object_convert(i)
        end
      else
        item
      end
    end

    def flat_hash(h,f=[],g={})
      return g.update({ f=>h }) unless h.is_a? Hash
      h.each { |k,r| flat_hash(r,f+[k],g) }
      g
    end

    def handle_on_open(service_ref, dsl_type, ws, params)
      service_map = service_ref.split('::') 
      service_id = service_map.first

      ws.on :open do
        params.merge!(@credentials[service_id.to_sym] || {})
        success "#{dsl_type.capitalize} '#{service_ref}' called"
        ws.send(params.to_json)
      end
    end

    def error_handle_call(listener_response, &block)
      content = simple_object_convert(listener_response['payload'])
      block.call(content) if block
    rescue => ex
      error "Error in workflow definition: #{ex.message}"
      ex.backtrace.each do |line|
        error "  #{line}"
      end
    end

    def success(msg)
      log_message('type' => 'log', 'status' => 'success', 'message' => msg)
    end

    def warn(msg)
      log_message('type' => 'log', 'status' => 'warn', 'message' => msg)
    end

    def error(msg)
      log_message('type' => 'log', 'status' => 'error', 'message' => msg)
    end

    def info(msg)
      log_message('type' => 'log', 'status' => 'info', 'message' => msg)
    end

    def log_message(message_info)
      message_info['instance_id'] = @instance_id
      message_info['workflow_id'] = @id
      @logger.call(message_info) if @logger
    end
  end
end
