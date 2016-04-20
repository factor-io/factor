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
        parameters = params(args[1..-1])

        if options.connector
          info "Loading #{options.connector}" if options.verbose
          require options.connector
        end

        connector_class = Factor::Connector.get(address)

        raise ArgumentError, "Connector '#{address}' not found" unless connector_class

        info "Running '#{address}(#{parameters})'" if options.verbose
        connector = connector_class.new(parameters)
        connector.add_observer(self, :events) if options.verbose
        response = connector.run

        @logger.indent += 1
        info response
        @logger.indent -= 1
        success 'Done!'
      end

      def events(type, content)
        if type==:log
          @logger.indent += 1
          @logger.log(content[:type], content[:message])
          @logger.indent -= 1
        end
      end
    end
  end
end
