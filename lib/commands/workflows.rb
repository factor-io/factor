# encoding: UTF-8

require 'configatron'

require 'commands/base'
require 'runtime'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class Workflow < Factor::Commands::Command
      def initialize
        @workflows = {}
      end

      def server(_args, options)
        config_settings = {}
        config_settings[:credentials] = options.credentials
        config_settings[:connectors]  = options.connectors
        workflow_filename = File.expand_path(options.path || '.')
        @destination_stream = File.new(options.log, 'w+') if options.log

        load_config(config_settings)
        load_all_workflows(workflow_filename)
        block_until_interupt
        info 'Good bye!'
      end

      private

      def load_all_workflows(workflow_filename)
        glob_ending = workflow_filename[-1] == '/' ? '' : '/'
        glob = "#{workflow_filename}#{glob_ending}*.rb"
        file_list = Dir.glob(glob)
        if !file_list.all? { |file| File.file?(file) }
          error "#{workflow_filename} is neither a file or directory"
        elsif file_list.count == 0
          error 'No workflows in this directory to run'
        else
          file_list.each { |filename| load_workflow(filename) }
        end
      end

      def block_until_interupt
        info 'Ctrl-c to exit'
        begin
          loop do
            sleep 1
          end
        rescue Interrupt
          info 'Exiting app...'
        ensure
          @workflows.keys.each { |filename| unload_workflow(filename) }
        end
      end

      def load_workflow(filename)
        workflow_filename = File.expand_path(filename)
        info "Loading workflow from #{workflow_filename}"
        begin
          workflow_definition = File.read(workflow_filename)
        rescue => ex
          exception "Couldn't read file #{workflow_filename}", ex
          return
        end

        @workflows[workflow_filename] = load_workflow_from_definition(workflow_definition)
        begin
          connector_settings = configatron.connectors.to_hash
          credential_settings = configatron.credentials.to_hash
          runtime = Runtime.new(connector_settings, credential_settings)
          runtime.logger = method(:log_message)
        rescue => ex
          message = "Couldn't setup workflow process for #{workflow_filename}"
          exception message, ex
        end

        @workflows[workflow_filename] = fork do
          begin
            info "Starting workflow"
            runtime.load(workflow_definition)
          rescue => ex
            exception "Couldn't load #{workflow_filename}", ex
          end
        end
      end

      def unload_workflow(filename)
        workflow_filename = File.expand_path(filename)
        info "Stopping #{workflow_filename}"
        Process.kill('SIGINT', @workflows[workflow_filename])
      end

      def log_message(message_info)
        case message_info['status']
        when 'info' then info message_info
        when 'success' then success message_info
        when 'warn' then warn message_info
        else error message_info
        end
      end
    end
  end
end
