# encoding: UTF-8

require 'securerandom'

require 'commands/base'
require 'common/deep_struct'
require 'runtime/service_address'
require 'runtime/exec_handler'

module Factor
  module Runtime
    class Workflow
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
      end

      def listen(service_ref, params = {}, &block)
          end




      end

      def workflow(service_ref, &block)
        address = ServiceAddress.new(service_ref)
        @workflows ||= {}
        @workflows[address] = block
      end

      def run(service_ref, params = {}, &block)
          end
        end
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
