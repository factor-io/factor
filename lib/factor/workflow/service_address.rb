module Factor
  module Workflow
    class ServiceAddress < Array
      def initialize(service_ref)
        if service_ref.is_a?(String)
          service_map = service_ref.split('::').map {|i| i.to_sym}
          raise ArgumentError, 'Address must not be empty' if service_ref.empty?
          raise ArgumentError, 'Address must contain at least the service name and action' unless service_map.count > 1
          raise ArgumentError, 'Address must not contain empty references' unless service_map.all?{|i| !i.empty?}
          super service_map
        elsif service_ref.is_a?(ServiceAddress) || service_ref.is_a?(Array)
          raise ArgumentError, 'All elements in array must be a string' unless service_ref.all?{|i| i.is_a?(String) || i.is_a?(Symbol)} 
          super service_ref
        else
          raise ArgumentError, 'Address must be a String, Array, or ServiceAddress'
        end
      end

      def workflow?
        self.service == :workflow
      end

      def service
        self.first
      end

      def namespace
        raise ArgumentError, 'Address must contain at least two parts' unless self.count >= 2
        self[0..-2]
      end

      def id
        self.last
      end

      def to_s
        self.join('::')
      end

      def resource
        raise "No resource path defined, address must contain at least three parts" unless self.length >= 3
        self[1..-2]
      end

      def path
        self[1..-1]
      end
    end
  end
end
