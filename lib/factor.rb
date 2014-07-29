# encoding: UTF-8

require 'commander/import'

require 'factor/version'
require 'commands/workflows'

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
  c.when_called Factor::Commands::Workflow, :server
end

alias_command 's', 'server'
