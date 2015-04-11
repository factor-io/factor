# encoding: UTF-8
require 'json'

require 'factor/commands/base'
require 'factor/workflow/runtime'

module Factor
  module Commands
    class RunCommand < Factor::Commands::Command
      def initialize
        @workflows = {}
        super
      end

      def run(args, options)
        config_settings = {}
        config_settings[:credentials] = options.credentials
        load_config(config_settings)

        credential_settings = configatron.credentials.to_hash
        runtime = Factor::Workflow::Runtime.new(credential_settings, logger: logger)

        begin
          params = JSON.parse(args[1] || '{}')
        rescue => ex
          logger.error "'#{args[1]}' can't be parsed as JSON"
          exit
        end

        done = false
        
        begin
          runtime.run(args[0],params) do |response_info|
            data = response_info.is_a?(Array) ? response_info.map {|i| i.marshal_dump} : response_info.marshal_dump
            JSON.pretty_generate(data).split("\n").each do |line|
              logger.info line
            end
            done = true
          end.on_fail do
            done = true
          end
        rescue => ex
          logger.error ex.message
          done = true
        end

        Factor::Common::Blocker.block_until { done }

        logger.info 'Good bye!'
      end
    end
  end
end
