require 'factor/workflow/future'

module Factor
  module Workflow
    class ConnectorFuture < Future
      def initialize(action)
        @subscribers = {}
        @action = action
        @action.add_observer(self, :trigger)

        super() do
          @action.run
        end
      end

      def wait
        @promise.execute if @promise.unscheduled?
        begin
          @promise.wait
        rescue Interrupt
          @action.stop if @action.respond_to?(:stop)
        end
      end

      def trigger(type, data)
        @subscribers[type] ||= []
        @subscribers[type].each {|subscriber| subscriber.call(data)}
      end

      def on(type, &block)
        @subscribers[type] ||= []
        @subscribers[type] << block
      end
    end
  end
end