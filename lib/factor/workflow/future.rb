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

      def depth
        count = 0
        begin
          parent=@promise.parent
          count +=1 if parent
        end while parent
        count
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
          completed.all? do |future|
            future.fulfilled? && block.call(future.value)
          end
        end
      end

      def self.any(number=1, *handlers, &block)
        
      end
    end
  end
end