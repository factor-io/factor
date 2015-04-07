module Factor
  module Workflow
    class ServiceAddress < Array
      def initialize(service_ref)
        if service_ref.is_a?(String)
          service_map = service_ref.split('::')
          raise ArgumentError, 'Address must not be empty' if service_ref.empty?
          raise ArgumentError, 'Address must contain at least one value' unless service_map.count > 0
          raise ArgumentError, 'Address must contain at least one value' unless service_map.all?{|i| !i.empty?}
          super service_map
        elsif service_ref.is_a?(ServiceAddress) || service_ref.is_a?(Array)
          raise ArgumentError, 'All elements in array must be a string' unless service_ref.all?{|i| i.is_a?(String)}
          super service_ref
        else
          raise ArgumentError, 'Address must be a String, Array, or ServiceAddress'
        end
      end

      def workflow?
        self.service == 'workflow'
      end

      def service
        self.first
      end

      def namespace
        raise ArgumentError, 'Address must contain at least two parts' unless self.count >= 2
        self[0..-2].map{|k| k.to_sym}
      end

      def id
        self.last
      end

      def to_s
        self.join('::')
      end

      def require_path
        "factor/connector/#{self.namespace.join('_')}"
      end

      def workflow_address
        workflow_service_map = self[1..-1]
        ServiceAddress.new workflow_service_map
      end
    end
  end
end
