# encoding: UTF-8

require 'factor/commands/base'
require 'factor/workflow/runtime'
require 'factor/logger'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class WorkflowCommand < Factor::Commands::Command
      def run(args, options)
        load_settings(options)

        workflow_filename = File.expand_path(args[0])
        info "Loading workflow from '#{workflow_filename}'" if options.verbose
        workflow_definition = File.read(workflow_filename)

        info "Starting workflow runtime..." if options.verbose
        @logger.indent options.verbose ? 1 : 0 do
          runtime = Factor::Workflow::Runtime.new(settings: settings, logger:@logger, verbose: options.verbose)
          runtime.load workflow_definition, workflow_filename
        end

        success "Workflow completed" if options.verbose
      end
    end
  end
end
