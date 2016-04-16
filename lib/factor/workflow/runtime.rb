# encoding: UTF-8
require 'factor/workflow/dsl'

module Factor
  module Workflow
    class Runtime
      extend Forwardable

      def initialize(options={})
        @options = options
        @dsl = DSL.new(@options)
      end

      def_delegator :@dsl, :instance_eval, :load
    end
  end
end
