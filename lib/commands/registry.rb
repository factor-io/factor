# encoding: UTF-8

require 'yaml'
require 'rest-client'
require 'erubis'
require 'json'

require 'commands/base'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class Registry < Factor::Commands::Command

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
        setup_connector args[0].to_s, options
      end

      def add_workflow(args, options)
        list          = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/workflows.yml'
        workflow_id   = args[0].to_s
        workflow_info = list[workflow_id]
        config_url    = workflow_info['config']

        load_config(credentials:options.credentials, connectors:options.connectors)

        config = get_json_data(config_url)

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

        template = RestClient.get(config['template'])

        eruby = Erubis::Eruby.new(template)

        workflow_content = eruby.result(variables)

        workflow_filename = "workflow-#{workflow_id}.rb"
        File.write(workflow_filename, workflow_content)

      end
    
      private

      def setup_connector(connector_id, options)
        list = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/connectors.yml'
        
        connector_info = list[connector_id]
        new_connectors = connector_info['connectors']
        required_credentials = connector_info['credentials']

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
          credentials[connector_id][credential_id.to_s] ||= ask("#{credential_info['name'].bold}#{' (optional)' if credential_info['optional']}: ").to_s
        end

        configatron[:credentials].configure_from_hash(credentials)
        configatron[:connectors].configure_from_hash(connectors)

        save_config(credentials:options.credentials, connectors:options.connectors)
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
