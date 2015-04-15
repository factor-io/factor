
module Factor
  module Log

    class Logger

      def log
        raise NotImplemented
      end

      def info
        raise NotImplemented
      end

      def warn
        raise NotImplemented
      end

      def error
        raise NotImplemented
      end

      def time
        Time.now.localtime.strftime('%m/%d/%y %T.%L')
      end
    end
  end
end