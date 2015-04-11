# encoding: UTF-8

require 'factor/workflow/definition'

module Factor
  module Workflow
    class Runtime
      def initialize(credentials, options={})
        @definition = Factor::Workflow::Definition.new(credentials, options)
      end

      def load(workflow_definition)
        @definition.instance_eval(workflow_definition)
      end

      def run(service_ref, params = {}, &block)
        @definition.run(service_ref, params, &block)
      end

      def unload
        @definition.stop
      end
    end
  end
end
