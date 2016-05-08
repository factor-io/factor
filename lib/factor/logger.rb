require 'rainbow'

module Factor
  # Default text logger used by Factor. Displays logs with timestamps, indentation, and coloring
  class Logger
    attr_accessor :indentation
    
    def initialize
      @indentation = 0
    end

    # Given an indentation level all messages logged inside of the provided block
    # will be indented to the defined depth.
    # @param indentation [Integer] the depth to indent
    def indent(indentation=1, &block)
      @indentation += indentation
      block.call
      @indentation -= indentation
    end

    # Logs a string message to standard output using the format `[<time>] <message>` with
    # appropriate coloring (:debug => grey, :error => red, :info => white, :warn=> yellow
    # :success => green) and indentation
    # @param type [Symbol] type of message to log (:debug, :info, :warn, :error, :success)
    # @param message [String] message to log
    def log(log_level, message)
      puts "[#{time}] #{'  ' * @indentation}#{color(log_level, message)}"
    end

    # Logs a debug message to standard output with formatting
    # @param message [String] message to log
    def debug(message)
      log :debug, message
    end

    # Logs a info message to standard output with formatting
    # @param message [String] message to log
    def info(message)
      log :info, message
    end

    # Logs a warn message to standard output with formatting
    # @param message [String] message to log
    def warn(message)
      log :warn, message
    end

    # Logs a error message to standard output with formatting
    # @param message [String] message to log
    def error(message)
      log :error, message
    end 

    # Logs a success message to standard output with formatting
    # @param message [String] message to log
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