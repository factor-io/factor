require 'observer'

module Factor
  class Connector
    include Observable
    def self.register(connector)
      if connector.superclass != Factor::Connector
        raise ArgumentError, "Connector must be a Factor::Connector"
      end

      @@paths ||= {}
      @@paths[underscore(connector.name)] = connector
    end

    def self.get(path)
      @@paths ||= {}
      @@paths[path]
    end

    
    def run
    end

    protected

    def trigger(data)
      changed
      notify_observers(:trigger, data)
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
