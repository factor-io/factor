# encoding: UTF-8

require 'yaml'
require 'rest-client'

require 'commands/base'

module Factor
  module Commands
    # Workflow is a Command to start the factor runtime from the CLI
    class Registry < Factor::Commands::Command

      def workflows(args,options={})
        list = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/workflows.yml'

        list.each do |id, values|
          puts "#{values['name'].bold} (#{id}): #{values['description']}"
        end
      end

      def connectors(args,options={})
        list = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/connectors.yml'

        list.each do |id, values|
          puts "#{values['name'].bold} (#{id})"
        end
      end

      def add_connector(args,options={})
        list = get_yaml_data 'https://raw.githubusercontent.com/factor-io/index/master/connectors.yml'
        connector_id = args[0].to_s
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
          credentials[connector_id][credential_id.to_s] = ask("#{credential_info['name'].bold}#{' (optional)' if credential_info['optional']}: ").to_s
        end

        configatron[:credentials].configure_from_hash(credentials)
        configatron[:connectors].configure_from_hash(connectors)

        save_config(credentials:options.credentials, connectors:options.connectors)
      end
    
      private

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
