require 'factor/logger/logger'

module Factor
  module Log
    class TestLogger  < Factor::Log::Logger

      attr_reader :history

      def initialize
        @history = []
      end

      def log(section, message='')
        history << {status: section, message:message}
      end

      def info(message = '')
        log :info, message
      end

      def warn(message = '')
        log :warn, message
      end

      def error(message = '')
        log :error, message
      end 

      def success(message = '')
        log :success, message
      end

      def clear
        @history=[]
      end
    end
  end
end