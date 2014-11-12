# encoding: UTF-8

require 'securerandom'
require 'yaml'
require 'eventmachine'
require 'uri'
require 'faye/websocket'

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
      @callers        = []
      @workflows      = {}
      @instance_id    = SecureRandom.hex(3)
      @reconnect      = true
      @logger         = options[:logger] if options[:logger]

      @connectors = Factor::Common.flat_hash(connectors)
      @credentials = credentials
    end

    def load(workflow_definition)
      begin
        EM.run do
          instance_eval(workflow_definition)
        end
      rescue Interrupt
      end
    end

    def listen(service_ref, params = {}, &block)
      service_map = service_ref.split('::') 
      service_id = service_map.first
      listener_id = service_map.last
      service_key = service_map[0..-2].map{|k| k.to_sym}

      e = ExecHandler.new(service_ref, params)

      connector_url = @connectors[service_key]

      if !connector_url
        error "Listener '#{service_ref}' not found"
        e.fail_block.call({}) if e.fail_block
      else
        caller = Factor::Runtime::ServiceCaller.new(connector_url)

        caller.on :close do
          error "Listener '#{service_ref}' disconnected"
        end

        caller.on :open do
          info "Listener '#{service_ref}' starting"
        end

        caller.on :retry do
          warn "Listener '#{service_ref}' reconnecting"
        end

        caller.on :error do
          error "Listener '#{service_ref}' dropped the connection"
        end

        caller.on :return do |data|
          success "Listener '#{service_ref}' started"
        end

        caller.on :start_workflow do |data|
          success "Listener '#{service_ref}' triggered"
          block.call(Factor::Common.simple_object_convert(data))
        end

        caller.on :fail do |info|
          error "Listener '#{service_ref}' failed"
          e.fail_block.call(action_response) if e.fail_block
        end

        caller.on :log do |log_info|
          @logger.log log_info[:status], log_info
        end

        caller.listen(listener_id,params)
        @callers << caller
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
          success "Workflow '#{workflow_id}' starting"
          content = Factor::Common.simple_object_convert(params)
          workflow.call(content)
          success "Workflow '#{workflow_id}' started"
        else
          error "Workflow '#{workflow_id}' not found"
          e.fail_block.call({}) if e.fail_block
        end
      else
        service_key = service_map[0..-2].map{|k| k.to_sym}

        connector_url = @connectors[service_key]

        caller = Factor::Runtime::ServiceCaller.new(connector_url)

        caller.on :open do
          info "Action '#{service_ref}' starting"
        end

        caller.on :error do
          error 'Connection dropped while calling action'
        end

        caller.on :return do |data|
          success "Action '#{service_ref}' responded"
          caller.close
          block.call(Factor::Common.simple_object_convert(data))
        end

        caller.on :fail do |info|
          error "Action '#{service_ref}' failed"
          caller.close
          e.fail_block.call(action_response) if e.fail_block
        end

        caller.on :log do |log_info|
          @logger.log log_info[:status], log_info
        end

        caller.action(action_id,params)
        @callers << caller
      end
      e
    end

    def success(message)
      @logger.success message
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
  end
end
