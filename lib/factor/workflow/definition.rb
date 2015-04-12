# encoding: UTF-8

require 'factor/commands/base'
require 'factor/common/deep_struct'
require 'factor/common/blocker'
require 'factor/workflow/service_address'
require 'factor/workflow/exec_handler'
require 'factor/connector/runtime'
require 'factor/connector/registry'
require 'factor/connector/definition'

module Factor
  module Workflow
    class Definition
      attr_reader :state

      def initialize(credentials, options={})
        @logger             = options[:logger] if options[:logger]
        @credentials        = credentials
        @workflow_filename  = options[:workflow_filename]
        @unload             = false
        @connector_runtimes = []
      end

      def stop
        @state = :stopping
        @unload = true
      end

      def state
        empty        = @connector_runtimes.count == 0
        all_started  = @connector_runtimes.all? {|r| r.started? }
        all_stopped  = @connector_runtimes.all? {|r| r.stopped? }
        any_stopping = @connector_runtimes.any? {|r| r.stopping? }
        any_starting = @connector_runtimes.any? {|r| r.starting? }

        if empty || all_stopped
          :stopped
        elsif all_started
          :started
        elsif any_stopping
          :stopping
        elsif any_starting
          :starting
        else
          :stopped
        end
      end

      def started?
        state == :started
      end

      def starting?
        state == :starting
      end

      def stopped?
        state == :stopped
      end

      def stopping?
        state == :stopping
      end

      def listen(service_ref, params = {}, &block)
        address, connector_runtime, exec, params_and_creds = initialize_connector_runtime(service_ref,params)
        line = caller.first.split(":")[1]
        @context = @workflow_filename ? "#{service_ref}(#{@workflow_filename}:#{line})" : "#{service_ref}"
        @connector_runtimes << connector_runtime

        done = false

        connector_runtime.callback do |response|
          message = response[:message]
          type    = response[:type]
          
          case type
          when 'trigger'
            success "Triggered"
            block.call(Factor::Common.simple_object_convert(response[:payload])) if block
          when 'log'
            log_callback(message,response[:status])
          when 'fail'
            message = response[:message] || 'unkonwn error'
            error "Failed: #{message}"
            exec.fail_block.call(message) if exec.fail_block
            done = true
          end
        end

        success "Starting"
        connector_runtime.start_listener(address.path, params)

        Thread.new do
          Factor::Common::Blocker.block_until { done || @unload }

          success "Stopping"
          connector_runtime.stop_listener
          success "Stopped"
          @connector_runtimes.delete(connector_runtimes)
        end

        exec
      end

      def run(service_ref, params = {}, &block)
        address, connector_runtime, exec, params_and_creds = initialize_connector_runtime(service_ref,params)
        line = caller.first.split(":")[1]
        @context = @workflow_filename ? "#{service_ref}(#{@workflow_filename}:#{line})" : "#{service_ref}"

        connector_runtime.callback do |response|
          message = response[:message]
          type    = response[:type]

          case type
          when 'log'
            log_callback(message,response[:status])
          when 'fail'
            error_message = response[:message] || "unknown error"
            error "Failed: #{error_message}"
            exec.fail_block.call(message) if exec.fail_block
          when 'response'
            success "Completed"
            payload = response[:payload] || {}
            block.call(Factor::Common.simple_object_convert(payload)) if block
          end
        end

        success "Starting"
        listener_instance = connector_runtime.run(address.path, params_and_creds)
        exec
      end

      def success(message)
        @logger.success @context ? "[#{@context}] #{message}" : message
      end

      def info(message)
        @logger.info @context ? "[#{@context}] #{message}" : message
      end

      def warn(message)
        @logger.warn @context ? "[#{@context}] #{message}" : message
      end

      def error(message)
        @logger.error @context ? "[#{@context}] #{message}" : message
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
