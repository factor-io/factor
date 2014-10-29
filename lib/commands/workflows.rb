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

      def cloud(args, options)
        account_id, workflow_id, api_key = args
        host        = (options.host || "https://factor.io").sub(/(\/)+$/,'')

        if !api_key || !workflow_id || !account_id
          error "API Key, Worklfow ID and Acount ID are all required"
          exit
        end

        info "Getting workflow (#{workflow_id}) from Factor.io Cloud"
        begin
          workflow_url = "#{host}/#{account_id}/workflows/#{workflow_id}.json?auth_token=#{api_key}"
          raw_content = RestClient.get(workflow_url)
          workflow_info = JSON.parse(raw_content)
        rescue => ex
          error "Couldn't retreive workflow: #{ex.message}"
          exit
        end

        workflow_definition = workflow_info["workflow_definition"]

        info "Getting credentials from Factor.io Cloud"
        begin
          credential_url = "#{host}/#{account_id}/credentials.json?auth_token=#{api_key}"
          raw_content = RestClient.get(credential_url)
          credentials = JSON.parse(raw_content)
        rescue => ex
          error "Couldn't retreive workflow: #{ex.message}"
          exit
        end

        configatron[:credentials].configure_from_hash(credentials)

        info "Getting connectors from Factor.io Cloud"
        connectors = {}
        begin
          connectors_url = "#{host}/#{account_id}/connectors.json?auth_token=#{api_key}"
          raw_content = RestClient.get(connectors_url)
          raw_connectors = JSON.parse(raw_content)

          raw_connectors.each do |connector_id,connector_info|
            connectors[connector_id] = connector_info['connectors'].values.first
          end
        rescue => ex
          error "Couldn't retreive workflow: #{ex.message}"
          exit
        end

        configatron[:connectors].configure_from_hash(connectors)

        @workflows[workflow_id] = load_workflow_from_definition(workflow_definition)

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
          file_list.each { |filename| load_workflow(File.expand_path(filename)) }
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
          @workflows.keys.each { |workflow_id| unload_workflow(workflow_id) }
        end
      end

      def load_workflow(filename)
        # workflow_filename = File.expand_path(filename)
        info "Loading workflow from #{workflow_filename}"
        begin
          workflow_definition = File.read(workflow_filename)
        rescue => ex
          exception "Couldn't read file #{workflow_filename}", ex
          return
        end

        @workflows[workflow_filename] = load_workflow_from_definition(workflow_definition)
      end

      def load_workflow_from_definition(workflow_definition)
        info "Setting up workflow processor"
        begin
          connector_settings = configatron.connectors.to_hash
          credential_settings = configatron.credentials.to_hash
          runtime = Runtime.new(connector_settings, credential_settings)
          runtime.logger = method(:log_message)
        rescue => ex
          message = "Couldn't setup workflow process for #{workflow_filename}"
          exception message, ex
        end

        workflow_thread = fork do
          begin
            info "Starting workflow"
            runtime.load(workflow_definition)
          rescue => ex
            exception "Couldn't workflow", ex
          end
        end

        workflow_thread
      end

      def unload_workflow(workflow_id)
        info "Stopping #{workflow_id}"
        Process.kill('SIGINT', @workflows[workflow_id])
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
