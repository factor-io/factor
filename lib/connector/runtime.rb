require 'observer'

module Factor
  module Connector
    class Runtime
      include Observable

      def initialize(connector)
        @connector = connector.new
        @connector.add_observer(self, :log)
      end

      def callback=(block)
        @callback = block if block
      end

      def callback(&block)
        @callback = block if block
      end

      def log(params)
        changed
        notify_observers params
        @callback.call(params) if @callback
      end

      def run(address, options={})
        actions = @connector.class.instance_variable_get('@actions')
        action  = actions[address]
        raise ArgumentError, "Action #{address} not found" unless action
        Thread.new do
          @connector.instance_exec(options,&action)
        end
      end
    end
  end
end