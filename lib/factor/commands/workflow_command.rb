# encoding: UTF-8

require 'factor/commands/base'
require 'factor/workflow/runtime'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class WorkflowCommand < Factor::Commands::Command
      def run(args, options)
        workflow_filename = File.expand_path(args[0])
        
        load_settings(options) if options.settings
        load_workflow_from_file(workflow_filename)
      end

      private

      def load_workflow_from_file(workflow_filename)
        workflow_definition = File.read(workflow_filename)
        runtime = Factor::Workflow::Runtime.new(settings)
        runtime.load workflow_definition, workflow_filename
      end
    end
  end
end
