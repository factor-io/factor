require 'rainbow'

module Factor
  class Logger
    attr_accessor :indent
    
    def initialize
      @indent = 0
    end

    def log(log_level, message)
      log_level_text  = format_log_level(log_level)
      puts "[ #{log_level_text} ] [#{time}] #{'  ' * @indent}#{message}"
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

    def format_log_level(log_level)
      formated_log_level = log_level.to_s.upcase.center(10)
      case log_level.to_sym
      when :error then Rainbow(formated_log_level).red
      when :info then Rainbow(formated_log_level).white.bright
      when :warn then Rainbow(formated_log_level).yellow
      when :success then Rainbow(formated_log_level).green
      else formated_log_level
      end
    end

    def time
      Time.now.localtime.strftime('%m/%d/%y %T.%L')
    end
  end
end