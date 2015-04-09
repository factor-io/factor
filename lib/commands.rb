# encoding: UTF-8

require 'commander/import'

require 'factor/version'
require 'factor/commands/workflow_command'
require 'factor/commands/run_command'

program :name, 'Factor.io Server'
program :version, Factor::VERSION
program :description, 'Factor.io Server to run workflows'

command 'server' do |c|
  c.syntax = 'factor server [options]'
  c.description = 'Start the Factor.io Server in the current local directory'
  c.option '--log FILE', String, 'Log file path. Default is stdout.'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.option '--path FILE', String, 'Path to workflows'
  c.when_called Factor::Commands::WorkflowCommand, :server
end

command 'run' do |c|
  c.syntax = 'factor run service_address params'
  c.description = 'Run a specific command.'
  c.option '--credentials FILE', String, 'credentials.yml file path.'
  c.when_called Factor::Commands::RunCommand, :run
end

command 'cloud' do |c|
  c.syntax = 'factor host <account id> <workflow id> <api key>'
  c.description = 'Start the Factor.io Server using your workflows and credentials from Factor.io Cloud'
  c.option '--host URL', String, 'Use non-default Cloud service provider (e.g. pro server)'
  c.when_called Factor::Commands::WorkflowCommand, :cloud
end

alias_command 's', 'server'