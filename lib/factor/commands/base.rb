# encoding: UTF-8

require 'configatron'
require 'yaml'
require 'fileutils'
require 'factor/logger/basic'

module Factor
  module Commands
    # Base command with common methods used by all commands
    class Command
      attr_accessor :logger

      DEFAULT_FILENAME = {
        credentials:  File.expand_path('./credentials.yml')
      }

      def initialize
        @logger = Factor::Log::BasicLogger.new
      end

      def load_config(options = {})
        load_config_data :credentials, options
      end

      def save_config(options={})
        credentials_relative_path = options[:credentials] || DEFAULT_FILENAME[:credentials]
        credentials_absolute_path = File.expand_path(credentials_relative_path)
        credentials = Hash[stringify(configatron.credentials.to_h).sort]

        File.write(credentials_absolute_path,YAML.dump(credentials))
      end

      private

      def stringify(hash)
        hash.inject({}) do |options, (key, value)|
          options[key.to_s] = value.is_a?(Hash) ? stringify(value) : value
          options
        end
      end

      def load_config_data(config_type, options = {})
        relative_path = options[config_type] || DEFAULT_FILENAME[config_type]
        absolute_path = File.expand_path(relative_path)
        begin
          data = YAML.load(File.read(absolute_path))
        rescue
          data = {}
        end
        configatron[config_type].configure_from_hash(data)
      rescue => ex
        logger.error "Couldn't load #{config_type} from #{absolute_path}", exception:ex
      end
    end
  end
end
