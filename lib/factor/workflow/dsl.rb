require 'factor/workflow/connector_future'

module Factor
  module Workflow
    class DSL
      def initialize(options={})
        @logger = options[:logger]
      end

      # Creates a new ConnectorFuture with the Connector action defined by the address
      # @param address [String] reference to the connector
      # @param options [Hash] Options to pass to the Connector
      # @return [Factor::Workflow::ConnectorFuture] A future to execute the connector action
      def run(address, options={})
        connector_class = Factor::Connector.get(address)
        connector       = connector_class.new(options)

        Factor::Workflow::ConnectorFuture.new(connector)
      end

      def all(*events, &block)
        Future.all(*events, &block)
      end

      def any(*events, &block)
        Future.any(*events, &block)
      end

      # Logs a debug message
      # @param message [String] message to log
      def debug(message)
        log(:debug, message)
      end

      # Logs a informational message
      # @param message [String] message to log
      def info(message)
        log(:info, message)
      end

      # Logs a warning message
      # @param message [String] message to log
      def warn(message)
        log(:warn, message)
      end

      # Logs an error message
      # @param message [String] message to log
      def error(message)
        log(:error, message)
      end

      # Logs a success message
      # @param message [String] message to log
      def success(message)
        log(:success, message)
      end

      # Logs a string message of any type
      # @param type [Symbol] type of message to log (:debug, :info, :warn, :error, :success)
      # @param message [String] message to log
      def log(type, message)
        @logger.log(type, message) if @logger
      end

      def on(type, *actions, &block)
        raise ArgumentError, "All actions must be an ConnectorFuture" unless actions.all? {|a| a.is_a?(ConnectorFuture) }
        actions.each {|a| a.on(type, &block) }
      end
    end
  end
end