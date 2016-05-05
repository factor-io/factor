# encoding: UTF-8

require 'configatron'
require 'yaml'
require 'fileutils'
require 'factor/logger'

module Factor
  module Commands
    # @abstract Subclass to implement new command line commands powered by 
    #   commander. Subclasses use this to get access to protected methods for
    #   logging and get access to settings. Used by {RunCommand} and
    #   {WorkflowCommand}
    class Command
      # @attribute [rw] logger
      #   @return [Factor::Logger] logger for accepting logs
      attr_accessor :logger

      # The default relative path to the settings file.
      DEFAULT_SETTINGS_FILENAME = File.expand_path('./.factor.yml')

      # @param [Hash] options the options containing settings for a new command
      # @option options [Factor::Logger] logger to be used for logging, by default
      #   createas a new instance
      def initialize(options={})
        @logger = options[:logger] || Factor::Logger.new
      end

      # Loads settings from a YAML settings file
      # @param [Hash] options the options to select the file/default value
      # @option options [Boolean] :verbose (false) whether the method should emit verbose logs
      # @option options [String] :settings ('./.factor.yaml') the path to the YAML settings file
      # @return [Hash] the settings loaded from the file, also avilable by calling {#settings}
      def load_settings(options)
        settings_file = DEFAULT_SETTINGS_FILENAME
        settings = {}
        if options.settings
          info "Using '#{options.settings}' settings file" if options.verbose
          settings_file = options.settings
        else
          info "Using default '#{DEFAULT_SETTINGS_FILENAME}' settings file" if options.verbose
        end

        begin
          absolute_path = File.expand_path(settings_file)
          content = File.read(absolute_path)
        rescue
          warn "Couldn't open the settings file '#{settings_file}', continuing without settings"
        end

        begin
          settings = YAML.load(content) if content
        rescue
          warn "Couldn't process the configuration file, continuing without settings"
        end

        configatron[:settings].configure_from_hash(settings)
      end

      # Gets the current settings that were loaded from the settings file.
      # @return [Hash] the settings loaded from the settings file via {#load_settings}
      def settings
        configatron.settings.to_hash.inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}
      end

      protected

      def debug(message)
        log(:debug, message)
      end

      def info(message)
        log(:info, message)
      end

      def warn(message)
        log(:warn, message)
      end

      def error(message)
        log(:error, message)
      end

      def success(message)
        log(:success, message)
      end

      def log(type, message)
        @logger.log(type, message) if @logger
      end

      private

      def try_json(value)
        new_value = value
        begin
          new_value = JSON.parse(value, symbolize_names: true)
        rescue JSON::ParserError
        end
        new_value
      end


      def params(args = [])
        request_options = {}
        args.each do |arg|
          key,value = arg.split(/:/,2)
          raise ArgumentError, "Option '#{arg}' is not a valid option" unless key && value
          request_options[key.to_sym] = try_json(value)
        end
        request_options
      end
    end
  end
end
