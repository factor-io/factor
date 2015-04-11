# encoding: UTF-8

require 'factor/common/blocker'
require 'factor/commands/base'
require 'factor/workflow/runtime'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class WorkflowCommand < Factor::Commands::Command
      def initialize
        @runtimes = []
        super
      end

      def server(_args, options)
        config_settings = {}
        config_settings[:credentials] = options.credentials
        workflow_filename = File.expand_path(options.path || '.')
        @destination_stream = File.new(options.log, 'w+') if options.log

        load_config(config_settings)
        load_all_workflows(workflow_filename)
        
        logger.info 'Ctrl-c to exit'
        Factor::Common::Blocker.block_until_interrupt_or do
          @runtimes.all?{|r| r.stopped?}
        end

        logger.info "Sending stop signal"
        @runtimes.each {|r| r.unload if r.started? }
        Factor::Common::Blocker.block_until sleep:0.5 do 
          @runtimes.all?{|r| r.stopped?}
        end
        logger.info 'Good bye!'
      end

      private

      def load_all_workflows(workflow_filename)
        glob_ending = workflow_filename[-1] == '/' ? '' : '/'
        glob = "#{workflow_filename}#{glob_ending}*.rb"
        file_list = Dir.glob(glob)
        if !file_list.all? { |file| File.file?(file) }
          logger.error "#{workflow_filename} is neither a file or directory"
        elsif file_list.count == 0
          logger.error 'No workflows in this directory to run'
        else
          file_list.each { |filename| load_workflow(File.expand_path(filename)) }
        end
      end

      def load_workflow(workflow_filename)
        logger.info "Loading workflow from #{workflow_filename}"
        begin
          workflow_definition = File.read(workflow_filename)
        rescue => ex
          logger.error "Couldn't read file #{workflow_filename}", exception:ex
          return
        end

        load_workflow_from_definition(workflow_definition, File.basename(workflow_filename))
      end

      def load_workflow_from_definition(workflow_definition, filename)
        logger.info "Setting up workflow processor"
        begin
          credential_settings = configatron.credentials.to_hash
          runtime = Factor::Workflow::Runtime.new(credential_settings, logger: logger, workflow_filename: filename)
          @runtimes << runtime
        rescue => ex
          message = "Couldn't setup workflow process"
          logger.error message:message, exception:ex
        end

        begin
          logger.info "Starting workflow"
          runtime.load(workflow_definition)
        rescue => ex
          logger.error message: "Couldn't start workflow", exception: ex
        end
      end
    end
  end
end
