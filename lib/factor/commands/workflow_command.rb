# encoding: UTF-8

require 'factor/commands/base'
require 'factor/workflow/runtime'
require 'factor/logger'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class WorkflowCommand < Factor::Commands::Command
      def run(args, options)
        
        if options.settings
          info "Loading settings from #{options.settings}" if options.verbose
          load_settings(options) 
        end

        workflow_filename = File.expand_path(args[0])
        info "Loading workflow from '#{workflow_filename}'" if options.verbose
        workflow_definition = File.read(workflow_filename)

        info "Starting workflow runtime..." if options.verbose
        @logger.indent += 1 if options.verbose
        runtime = Factor::Workflow::Runtime.new(settings: settings, logger:@logger, verbose: options.verbose)
        runtime.load workflow_definition, workflow_filename
        @logger.indent -= 1 if options.verbose

        success "Workflow completed" if options.verbose
      end
    end
  end
end
