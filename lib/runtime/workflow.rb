# encoding: UTF-8

require 'securerandom'
require 'eventmachine'

require 'commands/base'
require 'common/deep_struct'
require 'runtime/service_caller'
require 'runtime/service_address'
require 'runtime/exec_handler'

module Factor
  module Runtime
    class Workflow
      attr_accessor :name, :description, :id, :instance_id, :connectors, :credentials

      def initialize(connectors, credentials, options={})
        @workflow_spec  = {}
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
        address = ServiceAddress.new(service_ref)
        e = ExecHandler.new(service_ref, params)
        connector_url = @connectors[address.namespace]

        if !connector_url
          error "Listener '#{address}' not found"
          e.fail_block.call({}) if e.fail_block
        else
          caller = ServiceCaller.new(connector_url)

          caller.on :close do
            error "Listener '#{address}' disconnected"
          end

          caller.on :open do
            info "Listener '#{address}' starting"
          end

          caller.on :retry do |retry_info|
            if retry_info
              details = " ("
              details << "retry #{retry_info[:count]}"
              details << ", offline for #{retry_info[:offline_duration]} seconds" if retry_info[:offline_duration] > 0
              details << ")"
            end
            warn "Listener '#{address}' reconnecting#{details || ''}"
          end

          caller.on :error do
            error "Listener '#{address}' dropped the connection"
          end

          caller.on :return do |data|
            success "Listener '#{address}' started"
          end

          caller.on :start_workflow do |data|
            success "Listener '#{address}' triggered"
            block.call(Factor::Common.simple_object_convert(data)) if block
          end

          caller.on :fail do |info|
            error "Listener '#{address}' failed"
            e.fail_block.call(action_response) if e.fail_block
          end

          caller.on :log do |log_info|
            @logger.log log_info[:status], log_info
          end

          caller.listen(address.id,params)
        end
        e
      end

      def workflow(service_ref, &block)
        address = ServiceAddress.new(service_ref)
        @workflows ||= {}
        @workflows[address] = block
      end

      def run(service_ref, params = {}, &block)
        address = ServiceAddress.new(service_ref)
        e = ExecHandler.new(service_ref, params)

        if address.workflow?
          workflow_address = address.workflow_address
          workflow = @workflows[workflow_address]

          if workflow
            success "Workflow '#{workflow_address}' starting"
            content = Factor::Common.simple_object_convert(params)
            workflow.call(content)
            success "Workflow '#{workflow_address}' started"
          else
            error "Workflow '#{workflow_address}' not found"
            e.fail_block.call({}) if e.fail_block
          end
        else
          connector_url = @connectors[address.namespace]
          caller = ServiceCaller.new(connector_url)

          caller.on :open do
            info "Action '#{address}' starting"
          end

          caller.on :error do
            error "Action '#{address}' dropped the connection"
          end

          caller.on :return do |data|
            success "Action '#{address}' responded"
            caller.close
            block.call(Factor::Common.simple_object_convert(data['payload']))
          end

          caller.on :close do
            error "Action '#{address}' disconnected"
            e.fail_block.call(action_response) if e.fail_block
          end

          caller.on :fail do |info|
            error "Action '#{address}' failed"
            e.fail_block.call(action_response) if e.fail_block
          end

          caller.on :log do |log_info|
            @logger.log log_info[:status], log_info
          end

          caller.action(address.id,params)
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
end
