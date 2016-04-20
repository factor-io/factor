require 'rainbow'

module Factor
  class Logger
    attr_accessor :indent
    
    def initialize
      @indent = 0
    end

    def log(log_level, message)
      puts "[#{time}] #{'  ' * @indent}#{color(log_level, message)}"
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