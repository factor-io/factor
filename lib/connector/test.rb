

module Factor
  module Connector
    class Runtime
      attr_accessor :responses, :last_message
      
      def wait_for_info
        set_callback
      end

      def wait_for_log
        set_callback
      end

      def wait_for_response
        set_callback
      end

      private
      def set_callback
        unless self.callback
          callback do |data|
            @responses << data
            @last_message = data
          end  
        end
      end
    end
  end
end