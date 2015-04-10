# encoding: UTF-8

require 'factor/commands/base'
require 'factor/common/deep_struct'
require 'factor/workflow/service_address'
require 'factor/workflow/exec_handler'
require 'factor/connector/runtime'
require 'factor/connector/registry'
require 'factor/connector/definition'

module Factor
  module Workflow
    class Runtime
      attr_accessor :name, :description, :credentials

      def initialize(credentials, options={})
        @workflow_spec = {}
        @workflows     = {}
        @logger        = options[:logger] if options[:logger]
        @credentials   = credentials
        @workflow_filename = options[:workflow_filename]
      end

      def load(workflow_definition, take_nap=true)
        instance_eval(workflow_definition)

        nap if take_nap
      end

      def listen(service_ref, params = {}, &block)
        address, connector_runtime, exec, params_and_creds = initialize_connector_runtime(service_ref,params)
        line = caller.first.split(":")[1]
        file_id = @workflow_filename ? "#{@workflow_filename}:#{line}" : "line:#{line}"
        id = "#{service_ref}(#{file_id})"

        connector_runtime.callback = proc do |response|
          message = response[:message]
          type    = response[:type]
          
          case type
          when 'trigger'
            payload = response[:payload]

            success "[#{id}] Triggered"
            block.call(Factor::Common.simple_object_convert(payload)) if block

          when 'log'
            log_callback("  [#{id}] #{message}",response[:status])
          when 'fail'
            message = response[:message] || 'unkonwn error'
            error "[#{id}] Failed: #{message}"
            
            exec.fail_block.call(message) if exec.fail_block
          end
        end

        success "[#{id}] Starting"
        listener_instance = connector_runtime.start_listener(address.path, params)

        success "[#{id}] Stopped"
        exec
      end

      def run(service_ref, params = {}, &block)
        address, connector_runtime, exec, params_and_creds = initialize_connector_runtime(service_ref,params)
        line = caller.first.split(":")[1]
        file_id = @workflow_filename ? "#{@workflow_filename}:#{line}" : "line:#{line}"
        id = "#{service_ref}(#{file_id})"

        connector_runtime.callback = Proc.new do |response|
          message = response[:message]
          type    = response[:type]

          case type
          when 'log'
            log_callback("  [#{id}] #{message}",response[:status])
          when 'fail'
            error_message = response[:message] || "unknown error"
            error "[#{id}] Failed: #{error_message}"
            exec.fail_block.call(message) if exec.fail_block
          when 'response'
            success "[#{id}] Completed"
            payload = response[:payload] || {}
            block.call(Factor::Common.simple_object_convert(payload)) if block
          end
        end

        success "[#{id}] Starting"
        listener_instance = connector_runtime.run(address.path, params_and_creds)
        exec
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

      private

      def initialize_connector_runtime(service_ref, params={})
        address             = Factor::Workflow::ServiceAddress.new(service_ref)
        service_credentials = @credentials[address.service.to_sym] || {}
        exec                = Factor::Workflow::ExecHandler.new(service_ref, params)
        connector_class     = Factor::Connector::Registry.get(address.service)
        connector_runtime   = Factor::Connector::Runtime.new(connector_class)
        params_and_creds    = Factor::Common::DeepStruct.new(params.merge(service_credentials)).to_h

        [address, connector_runtime, exec, params_and_creds]
      end

      def nap
        begin
          begin
            sleep 0.1
          end while true
        rescue Interrupt
        end
      end

      def log_callback(message,status)
        case status
        when 'info' then info message
        when 'warn' then warn message
        when 'error' then error message
        when 'debug' then error message
        end
      end
    end
  end
end
