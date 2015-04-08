# encoding: UTF-8

require 'securerandom'

require 'factor/commands/base'
require 'factor/common/deep_struct'
require 'factor/workflow/service_address'
require 'factor/workflow/exec_handler'

module Factor
  module Workflow
    class Runtime
      attr_accessor :name, :description, :id, :credentials

      def initialize(credentials, options={})
        @workflow_spec  = {}
        @workflows      = {}
        @reconnect      = true
        @logger         = options[:logger] if options[:logger]

        @credentials = credentials
      end

      def load(workflow_definition)
        instance_eval(workflow_definition)

        nap
      end

      def listen(service_ref, params = {}, &block)
        address, service_instance, exec, params_and_creds = initialize_service_instance(service_ref,params)
        id = SecureRandom.hex(4)

        service_instance.callback = proc do |response|
          message = response[:message]
          type    = response[:type]
          
          case type
          when 'return'
            success "[#{id}] Listener Started '#{address}'"
          when 'start_workflow'
            payload = response[:payload]

            success "[#{id}] Listener Triggered '#{address}'"
            block.call(Factor::Common.simple_object_convert(payload)) if block

          when 'log'
            log_callback("  [#{id}] #{message}",response[:status])
          when 'fail'
            message = response[:message] || 'unkonwn error'
            error "[#{id}] Listener Failed '#{address}': #{message}"
            
            exec.fail_block.call(message) if exec.fail_block
          end
        end

        success "[#{id}] Listener Starting '#{address}'"
        listener_instance = service_instance.start_listener(address.id, params)

        success "[#{id}] Listener Stopped '#{address}'"
        exec
      end

      def run(service_ref, params = {}, &block)
        address, service_instance, exec, params_and_creds = initialize_service_instance(service_ref,params)
        id = SecureRandom.hex(4)

        service_instance.callback = Proc.new do |response|
          message = response[:message]
          type    = response[:type]

          case type
          when 'log'
            log_callback("  [#{id}] #{message}",response[:status])
          when 'fail'
            error_message = response[:message] || "unknown error"
            error "[#{id}] Action Failed '#{address}': #{error_message}"
            exec.fail_block.call(message) if exec.fail_block
            Thread.new do
              service_instance.stop_action(address.id)
            end
          when 'return'
            success "[#{id}] Action Completed '#{address}'"
            payload = response[:payload] || {}
            block.call(Factor::Common.simple_object_convert(payload)) if block
            
            Thread.new do
              service_instance.stop_action(address.id)
            end
          end
        end

        success "[#{id}] Action Starting '#{address}'"
        listener_instance = service_instance.call_action(address.id, params_and_creds)
        
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

      def initialize_service_instance(service_ref, params={})
        address             = ServiceAddress.new(service_ref)
        service_credentials = @credentials[address.service.to_sym] || {}
        exec                = ExecHandler.new(service_ref, params)

        info "Loading #{address.to_s} (#{address.require_path})"
        load_connector(address)

        service_manager = Factor::Connector.get_service_manager(address.service)
        service_instance = service_manager.instance

        params_and_creds = Factor::Common::DeepStruct.new(params.merge(service_credentials)).to_h

        [address, service_instance, exec, params_and_creds]
      end

      def nap
        begin
          begin
            sleep 0.1
          end while true
        rescue Interrupt
        end
      end

      def load_connector(address)
        if ENV['FACTOR_LOCAL_CONNECTORS_PATH']
          require_relative File.expand_path("../connector-#{address.service}/lib/#{address.require_path}.rb")
        else
          require address.require_path
        end
      rescue
        error "No such Listener, #{address.to_s}"
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
