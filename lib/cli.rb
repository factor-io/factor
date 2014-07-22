# encoding: UTF-8

require 'commander/import'

require 'commands/workflows'

program :name, 'Factor.io Server'
program :version, Factor::VERSION
program :description, 'Factor.io Server to run workflows'

command 'server' do |c|
  c.syntax = 'factor server [options]'
  c.description = 'Start the Factor.io Server in the current local directory'
  c.option '--log FILE', String, 'File location of where to log output. Default is stdout.'
  c.option '--credentials FILE', String, 'File location of credentials.yml'
  c.option '--connectors FILE', String, 'File location of connectors.yml'
  c.option '--path FILE', String, 'Path to workflows'
  c.when_called Factor::Commands::Workflow, :server
end

alias_command 's', 'server'