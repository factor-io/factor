# encoding: UTF-8

require 'colored'
require 'configatron'
require 'yaml'
require 'fileutils'

module Factor
  module Commands
    # Base command with common methods used by all commands
    class Command
      DEFAULT_FILENAME = {
        connectors:   File.expand_path('./connectors.yml'),
        credentials:  File.expand_path('./credentials.yml')
      }

      attr_accessor :destination_stream

      def info(options = {})
        log_line :info, options
      end

      def error(options = {})
        log_line :error, options
      end

      def warn(options = {})
        log_line :warn, options
      end

      def success(options = {})
        log_line :success, options
      end

      def exception(message, exception)
        error 'message' => message
        error 'message' => "  #{exception.message}"
        exception.backtrace.each do |line|
          error 'message' => "    #{line}"
        end
      end

      def load_config(options = {})
        load_config_data :credentials, options
        load_config_data :connectors, options
      end

      private

      def load_config_data(config_type, options = {})
        relative_path = options[config_type] || DEFAULT_FILENAME[config_type]
        absolute_path = File.expand_path(relative_path)
        info message: "Loading #{config_type} from #{absolute_path}"
        data = YAML.load(File.read(absolute_path))
        configatron[config_type].configure_from_hash(data)
      rescue => ex
        exception "Couldn't load #{config_type} from #{absolute_path}", ex
      end

      def log_line(section, options = {})
        options       = { message: options } if options.is_a?(String)
        tag           = tag(options)
        message       = options['message'] || options[:message]
        section_text  = format_section(section)
        write "[ #{section_text} ] [#{time}]#{tag} #{message}" if message
      end

      def format_section(section)
        formated_section = section.to_s.upcase.center(10)
        case section
        when :error then formated_section.red
        when :info then formated_section.bold
        when :warn then formated_section.yellow
        when :success then formated_section.green
        else formated_section
        end
      end

      def tag(options)
        primary = options['service_id'] || options['instance_id']
        secondary = if options['service_id'] && options['instance_id']
                      ":#{options['instane_id']}"
                    else
                      ''
                    end
        primary ? "[#{primary}#{secondary}]" : ''
      end

      def time
        Time.now.localtime.strftime('%m/%d/%y %T.%L')
      end

      def write(message)
        stream = @destination_stream || $stdout
        stream.puts(message)
        stream.flush
      end
    end
  end
end
