require 'observer'

module Factor
  module Connector
    class Runtime
      include Observable
      attr_accessor :logs

      def initialize(connector)
        @connector = connector.new
        @connector.add_observer(self, :log)
        @logs = []
      end

      def callback=(block)
        @callback = block if block
      end

      def callback(&block)
        @callback = block if block
      end

      def log(params)
        @logs << params
        changed
        notify_observers params
        @callback.call(params) if @callback
      end

      def run(address, options={})
        raise ArgumentError, "Address must be an Array" unless address.is_a?(Array)
        raise ArgumentError, "Address must be an Array of Symbols" unless address.all?{|a| a.is_a?(Symbol)}
        raise ArgumentError, "Address must not be empty" unless address.length > 0
        @address = address
        actions = @connector.class.instance_variable_get('@actions')
        action  = actions[address]
        raise ArgumentError, "Action #{address} not found" unless action
        Thread.new do
          @connector.instance_exec(options,&action)
        end
      end

      def start_listener(address, options={})
        @address = address
        listeners = @connector.class.instance_variable_get('@listeners')
        listener  = listeners[address + [:start]]
        raise ArgumentError, "Listener #{address} not found" unless listener
        Thread.new do
          @connector.instance_exec(options, &listener)
        end
      end

      def stop_listener
        listeners = @connector.class.instance_variable_get('@listeners')
        listener  = listeners[@address + [:stop]]
        raise ArgumentError, "Listener #{address} not found" unless listener

        Thread.new do 
          @connector.instance_eval(&listener)
        end
      end
    end
  end
end