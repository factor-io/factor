# encoding: UTF-8

require 'json'
require 'securerandom'
require 'yaml'
require 'eventmachine'
require 'uri'
require 'faye/websocket'

require 'listener'
require 'commands/base'

module Factor
  # Runtime class is the magic of the server
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
      connectors.each do |connector_id, connector_url|
        @connectors[connector_id] = Listener.new(connector_url)
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

    def listen(service_id, listener_id, params = {}, &block)
      ws = @connectors[service_id.to_sym].listener(listener_id)

      handle_on_open(service_id, listener_id, 'Listener', ws, params)

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
        when 'started'
          success "Workflow '#{service_id}::#{listener_id}' started"
        when 'fail'
          error "Workflow '#{service_id}::#{listener_id}' failed to start"
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
    end

    def run(service_id, action_id, params = {}, &block)
      ws = @connectors[service_id.to_sym].action(action_id)

      handle_on_open(service_id, action_id, 'Action', ws, params)

      ws.on :error do
        error 'Connection dropped while calling action'
      end

      ws.on :message do |event|
        action_response = JSON.parse(event.data)
        case action_response['type']
        when 'return'
          ws.close
          success "Action '#{service_id}::#{action_id}' responded"
          error_handle_call(action_response, &block)
        when 'fail'
          ws.close
          error "  #{action_response['message']}"
          error "Action '#{service_id}::#{action_id}' failed"
        when 'log'
          action_response['message'] = "  #{action_response['message']}"
          log_message(action_response)
        else
          error "Unknown action response: #{action_response}"
        end
      end

      ws.open

      @sockets << ws
    end

    private

    def handle_on_open(service_id, action_id, dsl_type, ws, params)
      ws.on :open do
        params.merge!(@credentials[service_id.to_sym] || {})
        success "#{dsl_type.capitalize} '#{service_id}::#{action_id}' called"
        ws.send(params.to_json)
      end
    end

    def error_handle_call(listener_response, &block)
      block.call(listener_response['payload']) if block
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
