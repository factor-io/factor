require 'rainbow'

module Factor
  class Logger
    attr_accessor :indentation
    
    def initialize
      @indentation = 0
    end

    def indent(indentation=1, &block)
      @indentation += indentation
      block.call
      @indentation -= indentation
    end

    def log(log_level, message)
      puts "[#{time}] #{'  ' * @indentation}#{color(log_level, message)}"
    end

    def debug(message)
      log :debug, message
    end

    def info(message)
      log :info, message
    end

    def warn(message)
      log :warn, message
    end

    def error(message)
      log :error, message
    end 

    def success(message)
      log :success, message
    end

    private

    def color(log_level, text)
      case log_level.to_sym
      when :debug then Rainbow(text).color(43,43,43)
      when :error then Rainbow(text).red
      when :info then Rainbow(text).white.bright
      when :warn then Rainbow(text).yellow
      when :success then Rainbow(text).green
      else text
      end
    end

    def time
      Time.now.localtime.strftime('%m/%d/%y %T.%L')
    end
  end
end