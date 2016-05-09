require 'observer'

module Factor
  # @abstract Subclass and override {#run} to implement a connector, optionally also implement #stop
  class Connector
    include Observable

    # Registers the Connector so that it can be accessed via get
    # @param connector [Factor::Connector] Connector to register
    def self.register(connector)
      raise ArgumentError, "Connector must be a Factor::Connector" unless connector.ancestors.include?(self)

      @@paths ||= {}
      @@paths[underscore(connector.name)] = connector
    end

    # Retreives a previously register Connector by a string name
    # @param path [String] the reference to the class name
    def self.get(path)
      @@paths ||= {}
      @@paths[path]
    end

    # Method to override to add the core functionality of the connector.
    # @return [Hash] value after executing the connector
    def run
    end

    protected

    def trigger(data)
      changed
      notify_observers(:trigger, data)
    end

    def debug(message)
      log(:debug, message)
    end

    def info(message)
      log(:info, message)
    end

    def warn(message)
      log(:warn, message)
    end

    def success(message)
      log(:success, message)
    end

    def error(message)
      log(:error, message)
    end

    def log(type, message)
      changed
      notify_observers(:log, {type: type, message:message})
      changed
      notify_observers(type, message)
    end

    private

    def self.underscore(string)
      word = string.dup
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end
end
