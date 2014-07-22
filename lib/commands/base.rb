# encoding: UTF-8

require 'colored'
require 'configatron'
require 'yaml'
require 'fileutils'

module Factor
  module Commands

    # Base command with common methods used by all commands
    class Command
      DEFAULT_CREDENTIALS_FILENAME  = File.expand_path('./credentials.yml')
      DEFAULT_CONNECTORS_FILENAME   = File.expand_path('./connectors.yml')

      attr_accessor :destination_stream

      def info(options = {})
        options['section']      ||= 'INFO'
        options['section_text']   = options['section'].center(10).bold
        log_line options
      end

      def error(options = {})
        options['section']      ||= 'ERROR'
        options['section_text']   = options['section'].center(10).red
        log_line options
      end

      def warn(options = {})
        options['section']      ||= 'WARNING'
        options['section_text']   = options['section'].center(10).yellow
        log_line options
      end

      def success(options = {})
        options['section']      ||= 'SUCCESS'
        options['section_text']   = options['section'].center(10).green
        log_line options
      end

      def debug(options = {})
      end

      def exception(message, exception)
        error 'message' => message
        error 'message' => "  #{exception.message}"
        exception.backtrace.each do |line|
          error 'message' => "    #{line}"
        end
      end

      def load_config(options = {})
        load_credentials options
        load_connectors options
      end

      private

      def load_credentials(options = {})
        relative_path = options[:credentials] || DEFAULT_CREDENTIALS_FILENAME
        credentials_filename = File.expand_path(relative_path)
        info message: "Loading credentials from #{credentials_filename}"
        credentials_data = YAML.load(File.read(credentials_filename))
        configatron.credentials.configure_from_hash(credentials_data)
      rescue => ex
        exception "Couldn't load credentials from #{credentials_filename}", ex
      end

      def load_connectors(options = {})
        relative_path = options[:connectors] || DEFAULT_CONNECTORS_FILENAME
        connectors_filename = File.expand_path(relative_path)
        info message: "Loading connectors from #{connectors_filename}"
        connectors_data = YAML.load(File.read(connectors_filename))
        configatron.connectors.configure_from_hash(connectors_data)
      rescue => ex
        exception "Couldn't load credentials from #{connectors_filename}", ex
      end

      def log_line(options = {})
        options       = { message: options } if options.is_a?(String)
        tag           = tag(options)
        message       = options['message'] || options[:message]
        section_text  = options['section_text'] || 'INFO'
        write "[ #{section_text} ] [#{time}]#{tag} #{message}" if message
      end

      def tag(options)
        tag = ''
        if options['workflow_id'] && options['instance_id']
          tag = "[#{options['workflow_id']}:#{options['instance_id']}]"
        elsif options['workflow_id'] && !options['instance_id']
          tag = "[#{options['workflow_id']}]"
        elsif !options['workflow_id'] && options['instance_id']
          tag = "[#{options['instance_id']}]"
        end
        tag
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