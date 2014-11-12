require_relative './logger.rb'

module Factor
  module Log
    class BasicLogger  < Factor::Log::Logger

      attr_accessor :destination_stream

      def log(section, options={})
        options       = { message: options } if options.is_a?(String)
        tag           = tag(options)
        message       = options['message'] || options[:message]
        section_text  = format_section(section)
        write "[ #{section_text} ] [#{time}]#{tag} #{message}" if message
        exception options[:exception] if options[:exception]
      end

      def info(options = {})
        log :info, options
      end

      def warn(options = {})
        log :warn, options
      end

      def error(options = {})
        log :error, options
      end 

      def success(options = {})
        log :success, options
      end

      private

      def exception(exception)
        error message: "  #{exception.message}"
        exception.backtrace.each do |line|
          error message: "    #{line}"
        end
      end

      def format_section(section)
        formated_section = section.to_s.upcase.center(10)
        case section.to_sym
        when :error then formated_section.red
        when :info then formated_section.bold
        when :warn then formated_section.yellow
        when :success then formated_section.green
        else formated_section
        end
      end

      def tag(options)
        primary = options['service_id'] || options['instance_id']
        secondary = ":#{options['instane_id']}" if options['service_id'] && options['instance_id']
        primary ? "[#{primary}#{secondary || ''}]" : ''
      end

      def write(message)
        stream = @destination_stream || $stdout
        stream.puts(message)
        stream.flush
      end

    end
  end
end