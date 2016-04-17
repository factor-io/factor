# encoding: UTF-8

require 'configatron'
require 'yaml'
require 'fileutils'
require 'factor/logger'

module Factor
  module Commands
    # Base command with common methods used by all commands
    class Command
      attr_accessor :logger

      DEFAULT_FILENAME = File.expand_path('./settings.yml')


      def load_settings(options = {})
        relative_path = options.settings || DEFAULT_FILENAME
        absolute_path = File.expand_path(relative_path)
        content       = File.read(absolute_path)
        data          = YAML.load(content)
        configatron[:settings].configure_from_hash(data)
      end

      def settings
        configatron.settings.to_hash
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
