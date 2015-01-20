# encoding: UTF-8

require 'commander/import'

require 'factor/version'
require 'commands/workflow_command'
require 'commands/registry_command'
require 'commands/run_command'

program :name, 'Factor.io Server'
program :version, Factor::VERSION
program :description, 'Factor.io Server to run workflows'

command 'server' do |c|
  c.syntax = 'factor server [options]'
  c.description = 'Start the Factor.io Server in the current local directory'
  c.option '--log FILE', String, 'Log file path. Default is stdout.'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.option '--connectors FILE', String, 'connectors.yml file path'
  c.option '--path FILE', String, 'Path to workflows'
  c.when_called Factor::Commands::WorkflowCommand, :server
end

command 'run' do |c|
  c.syntax = 'factor run service_address params'
  c.description = 'Run a specific command.'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.option '--connectors FILE', String, 'connectors.yml file path'
  c.when_called Factor::Commands::RunCommand, :run
end

command 'cloud' do |c|
  c.syntax = 'factor host <account id> <workflow id> <api key>'
  c.description = 'Start the Factor.io Server using your workflows and credentials from Factor.io Cloud'
  c.option '--host URL', String, 'Use non-default Cloud service provider (e.g. pro server)'
  c.when_called Factor::Commands::WorkflowCommand, :cloud
end

command 'registry workflows' do |c|
  c.syntax = 'factor registry workflows'
  c.description = 'Get list of available workflow jumpstarts'
  c.when_called Factor::Commands::RegistryCommand, :workflows
end

command 'registry workflows add' do |c|
  c.syntax = 'factor registry workflow add <id>'
  c.description = 'Add a workflow to your working directory'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.option '--connectors FILE', String, 'connectors.yml file path'
  c.option '--path FILE', String, 'Path to workflows'
  c.option '--values \'{"api_key":"foo"}\'', String, "{}"
  c.when_called Factor::Commands::RegistryCommand, :add_workflow
end

command 'registry connectors' do |c|
  c.syntax = 'factor registry connectors'
  c.description = 'Get list of available connectors'
  c.when_called Factor::Commands::RegistryCommand, :connectors
end

command 'registry connectors add' do |c|
  c.syntax = 'factor registry connector add <id>'
  c.description = 'Get list of available connectors'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.option '--connectors FILE', String, 'connectors.yml file path'
  c.option '--values \'{"api_key":"foo"}\'', String, "{}"
  c.when_called Factor::Commands::RegistryCommand, :add_connector
end

alias_command 's', 'server'