# encoding: UTF-8
require 'json'

require 'factor/commands/base'
require 'factor/connector'
# require 'factor/workflow/runtime'

module Factor
  module Commands
    class RunCommand < Factor::Commands::Command
      def run(args, options)
        address      = args[0]
        service_name = args[0].split('::')[0]
        parameters   = params(args[1..-1])

        if options.connector
          info "Loading #{options.connector}" if options.verbose
          require options.connector
        end

        load_settings(options)

        connector_class = Factor::Connector.get(address)

        raise ArgumentError, "Connector '#{address}' not found" unless connector_class

        info "Running '#{address}(#{parameters})'" if options.verbose
        connector = connector_class.new(parameters.merge(settings[service_name] || {}))
        connector.add_observer(self, :events) if options.verbose
        response = connector.run

        success "Run complete:" if options.verbose
        @logger.indent options.verbose ? 1 : 0 do 
          info response
        end
        success 'Done!' if options.verbose
      end

      def events(type, content)
        if type==:log
          @logger.indent {
            @logger.log(content[:type], content[:message])
          }
        end
      end
    end
  end
end
