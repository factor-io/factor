# encoding: UTF-8

require 'yaml'
require 'rest-client'
require 'liquid'
require 'json'

require 'commands/base'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class RegistryCommand < Factor::Commands::Command

      def workflows(args, options)
        list = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/workflows.yml'

        list.each do |id, values|
          puts "#{values['name'].bold} (#{id}): #{values['description']}"
        end
      end

      def connectors(args, options)
        list = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/connectors.yml'

        list.each do |id, values|
          puts "#{values['name'].bold} (#{id})"
        end
      end

      def add_connector(args, options)
        puts "Workflow ID is required (factor registry connector add --help)".red unless args[0]

        setup_connector args[0].to_s, options if args[0]
      end

      def add_workflow(args, options)
        begin
          list          = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/workflows.yml'
        rescue
          puts "Couldn't connect to the server to get connector information".red
          exit
        end

        unless args[0]
          puts "Workflow ID is required".red
          exit
        end

        begin
          workflow_id   = args[0].to_s
          workflow_info = list[workflow_id]
          config_url    = workflow_info['config']
          workflow_name = workflow_info['name']
        rescue
          puts "Couldn't find information for #{workflow_id}".red
          exit
        end

        load_config(credentials:options.credentials, connectors:options.connectors)

        begin
          config = get_json_data(config_url)
        rescue
          puts "Couldn't pull up configuration information from #{config_url}".red
          exit
        end

        if !config['required-connectors'] || !config['required-connectors'].is_a?(Array) || !config['variables'] || !config['variables'].is_a?(Hash)
          puts "Configuration information for the workflow is missing information"
          exit
        end

        config['required-connectors'].each do |connector_id|
          if configatron.credentials.to_hash[connector_id.to_sym]
            puts "#{connector_id} already configured".green
          else
            setup_connector(connector_id,options)
          end
        end

        variables = {}
        config['variables'].each do |var_id,var_info|
          puts var_info['description'] if var_info['description']
          values = begin
            JSON.parse(options.values)
          rescue 
            {}
          end
          variables[var_id] = values[var_id]
          variables[var_id] ||= ask("#{var_info['name'].bold}#{' (optional)' if var_info['optional']}: ").to_s
        end

        begin
          template = RestClient.get(config['template'])
        rescue
          puts "Couldn't find a template at #{config['template']}".red
          exit
        end

        begin
          liquid = Liquid::Template.parse(template)
          workflow_content = liquid.render variables
        rescue
          puts "Failed to generate template".red
          exit
        end

        workflow_filename = "workflow-#{workflow_id}.rb"
        begin
          File.write(workflow_filename, workflow_content)
        rescue
          puts "Failed to write the file to disk. Check permissions.".red
          exit
        end


        puts "Created #{workflow_name} successfully".green
      end
    
      private

      def setup_connector(connector_id, options)
        begin
          list = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/connectors.yml'
        rescue
          puts "Couldn't connect to the server to get connector information".red
          exit
        end


        begin
          connector_info = list[connector_id]
          connector_name = connector_info['name']
          new_connectors = connector_info['connectors']
          required_credentials = connector_info['credentials']
        rescue
          puts "Couldn't find information for '#{connector_id}'".red
          exit
        end

        unless connector_name && new_connectors && required_credentials
          puts "Couldn't find information for '#{connector_id}'".red
          exit
        end

        load_config(credentials:options.credentials, connectors:options.connectors)
        connectors =  configatron.connectors.to_hash
        credentials = configatron.credentials.to_hash
        
        connectors[connector_id] = new_connectors
        
        required_credentials.each do |credential_id, credential_info|
          puts credential_info['description'] if credential_info['description']
          credentials[connector_id] ||= {}
          values = begin
            JSON.parse(options.values)
          rescue 
            {}
          end
          credentials[connector_id][credential_id.to_s] = values[credential_id.to_s]
          credentials[connector_id][credential_id.to_s] ||= ask("#{connector_name.bold} #{credential_info['name'].bold}#{' (optional)' if credential_info['optional']}: ").to_s
        end

        configatron[:credentials].configure_from_hash(credentials)
        configatron[:connectors].configure_from_hash(connectors)

        save_config(credentials:options.credentials, connectors:options.connectors)

        puts "Setup #{connector_name} successfully".green
      end

      def get_yaml_data(url)
        raw_content = RestClient.get(url)
        list = YAML.parse(raw_content).to_ruby
        list
      end

      def get_json_data(url)
        raw_content = RestClient.get(url)
        data = JSON.parse(raw_content)
        data
      end
    end
  end
end
