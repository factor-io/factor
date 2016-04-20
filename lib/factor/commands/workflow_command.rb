# encoding: UTF-8

require 'factor/commands/base'
require 'factor/workflow/runtime'
require 'factor/logger'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class WorkflowCommand < Factor::Commands::Command
      def run(args, options)
        workflow_filename = File.expand_path(args[0])
        
        load_settings(options) if options.settings

        workflow_definition = File.read(workflow_filename)
        logger = Factor::Logger.new()
        runtime = Factor::Workflow::Runtime.new(settings: settings, logger:logger)
        runtime.load workflow_definition, workflow_filename
      end
    end
  end
end
