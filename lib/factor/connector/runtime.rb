require 'observer'

module Factor
  module Connector
    class Runtime
      include Observable
      attr_reader :logs, :state

      def initialize(connector)
        @connector = connector.new
        @connector.add_observer(self, :log)
        @logs = []
        @state = :stopped
      end

      def started?
        @state == :started
      end

      def starting?
        @state == :starting
      end

      def stopped?
        @state == :stopped
      end

      def stopping?
        @state == :stopping
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
          begin
            @connector.instance_exec(options,&action)
          rescue => ex
            log type:'fail', message: ex.message
          end
        end
      end

      def start_listener(address, options={})
        @address = address
        listeners = @connector.class.instance_variable_get('@listeners')
        listener  = listeners[address + [:start]]
        raise ArgumentError, "Listener #{address} not found" unless listener
        @start_listener_thread = Thread.new do
          @state = :starting
          begin
            @connector.instance_exec(options, &listener)
            @state = :started
          rescue => ex
            @state = :stopped
            log type:'fail', message: ex.message
          end
        end
      end

      def stop_listener
        listeners = @connector.class.instance_variable_get('@listeners')
        listener  = listeners[@address + [:stop]]
        raise ArgumentError, "Listener #{address} not found" unless listener

        Thread.new do 
          @state = :stopping
          begin
            @connector.instance_eval(&listener)
          ensure
            @state = :stopped
          end
        end
      end
    end
  end
end