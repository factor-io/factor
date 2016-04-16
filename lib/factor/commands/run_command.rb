# encoding: UTF-8
require 'json'

require 'factor/commands/base'
require 'factor/connector'
# require 'factor/workflow/runtime'

module Factor
  module Commands
    class RunCommand < Factor::Commands::Command
      def run(args, options)

        address = args[0]
        request_options = parse_data(args[1..-1])

        require options.require if options.require

        connector_class = Factor::Connector.get(address)

        raise ArgumentError, "Connector '#{address}' not found" unless connector_class

        connector = connector_class.new(request_options)
        response = connector.run

        puts response
      end
    end
  end
end
