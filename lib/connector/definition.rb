require 'observer'

require 'connector/error'

module Factor
  module Connector
    class Definition
      include Observable

      def self.id(id)
        raise ArgumentError, "ID must be a sym" unless id.is_a?(Symbol)
        instance_variable_set('@id',id)
        define_method :id do
          id
        end
      end

      def self.resource(resource,&block)
        resources = instance_variable_get('@resources') || []
        resources.push resource
        instance_variable_set('@resources',resources)

        block.call

        resources.pop
        instance_variable_set('@resources',resources)
        remove_instance_variable('@resources') if resources.count == 0
      end

      def self.action(action,&block)
        resources = @resources || []
        address   = resources + [action]
        actions   = instance_variable_get('@actions') || {}

        actions[address] = block
        instance_variable_set('@actions', actions)
      end

      def self.listener(listener,&block)
        resources     = @resources || []
        address       = resources + [listener]
        start_address = resources + [listener] + [:start]
        stop_address  = resources + [listener] + [:stop]

        instance_variable_set('@listener', listener)

        block.call

        listeners = instance_variable_get('@listeners') || {}
        raise ArgumentError, "Start block must be defined in listener '#{address.join('::')}'" unless listeners[start_address]
        raise ArgumentError, "Stop block must be defined in listener '#{address.join('::')}'" unless listeners[stop_address]

        remove_instance_variable('@listener')
      end

      def self.start(&block)
        listener = instance_variable_get('@listener')
        raise ArgumentError, 'Start block must be defined within a Listener' unless listener
        resources = @resources || []
        address = resources + [listener] + [:start]

        listeners = instance_variable_get('@listeners') || {}
        listeners[address] = block
        instance_variable_set('@listeners', listeners)
      end

      def self.stop(&block)
        listener = instance_variable_get('@listener')
        raise ArgumentError, 'Stop block must be defined within a Listener' unless listener
        resources = @resources || []
        address = resources + [listener] + [:stop]

        listeners = instance_variable_get('@listeners') || {}
        listeners[address] = block
        instance_variable_set('@listeners', listeners)
      end

      def trigger(data)
        changed
        notify_observers type:'trigger', data:data
      end

      def respond(data)
        changed
        notify_observers type:'response', data: data
      end

      def info(message)
        log 'info', message
      end

      def error(message)
        log 'error', message
      end

      def warn(message)
        log 'warn', message
      end

      def debug(message)
        log 'debug', message
      end

      def fail(message,params={})
        changed
        notify_observers type:'fail', message: message
        raise Factor::Connector::Error, exception:params[:exception], message:message if !params[:throw]
      end

      def log(status, message)
        changed
        notify_observers type: 'log', status: status, message: message
      end
    end
  end
end