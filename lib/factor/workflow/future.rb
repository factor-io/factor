require 'concurrent'

module Factor
  module Workflow
    class Future
      extend Forwardable

      def initialize(promise=nil, &block)
        raise ArgumentError, "promise or block required" unless promise || block
        raise ArgumentError, "promise and block can't both be provided" if promise && block
        raise ArgumentError, "promise must be a Concurrent::Promise" if promise && !promise.is_a?(Concurrent::Promise)

        @promise = promise || Concurrent::Promise.new(&block)
      end

      def_delegator :@promise, :state, :state
      def_delegator :@promise, :pending?, :pending?
      def_delegator :@promise, :rejected?, :rejected?
      def_delegator :@promise, :fulfilled?, :fulfilled?
      def_delegator :@promise, :unscheduled?, :unscheduled?
      def_delegator :@promise, :reason, :reason
      def_delegator :@promise, :value, :value
      def_delegator :@promise, :fail, :fail

      def completed?
        @promise.fulfilled? || @promise.rejected?
      end

      def then(&block)
        Future.new(@promise.then(&block))
      end

      def execute
        Future.new(@promise.execute)
      end

      def rescue(&block)
        Future.new(@promise.rescue(&block))
      end

      def wait
        @promise.execute if @promise.unscheduled?
        @promise.wait
      end

      def self.all(*handlers, &block)
        block ||= lambda {|v| true}
        Future.new do
          handlers.each {|handler| handler.execute if handler.unscheduled?}
          completed = handlers.map do |handler|
            handler.wait
            handler
          end
          worked = completed.all? { |handler| handler.fulfilled? && block.call(handler.value) }

          raise StandardError, "At least one event failed" unless worked

          worked
        end
      end

      def self.any(*handlers, &block)
        block ||= lambda {|v| true}
        Future.new do
          handlers.each {|handler| handler.execute if handler.unscheduled?}
          completed = handlers.map do |handler|
            handler.wait
            handler
          end
          worked = completed.any? { |handler| handler.fulfilled? && block.call(handler.value) }

          raise StandardError, "There were no successful events" unless worked

          worked
        end
      end
    end
  end
end