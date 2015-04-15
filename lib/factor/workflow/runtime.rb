# encoding: UTF-8
require 'forwardable'

require 'factor/workflow/definition'

module Factor
  module Workflow
    class Runtime
      extend Forwardable

      def initialize(credentials, options={})
        @definition = Factor::Workflow::Definition.new(credentials, options)
      end

      def_delegator :@definition, :instance_eval, :load
      def_delegator :@definition, :run, :run
      def_delegator :@definition, :stop, :unload
      def_delegator :@definition, :state, :state
      def_delegator :@definition, :started?, :started?
      def_delegator :@definition, :starting?, :starting?
      def_delegator :@definition, :stopped?, :stopped?
      def_delegator :@definition, :stopping?, :stopping?

    end
  end
end
