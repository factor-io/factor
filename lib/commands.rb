# encoding: UTF-8

require 'commander/import'

require 'factor/version'
require 'factor/commands/workflow_command'
require 'factor/commands/run_command'

program :name, 'Factor.io Server'
program :version, Factor::VERSION
program :description, 'Factor.io Server to run workflows'

command 'workflow' do |c|
  c.syntax = 'factor workflow workflow_file'
  c.description = 'Start the Factor.io Server in the current local directory'
  c.option '--settings FILE', String, 'factor.yml file path.'
  c.option '--verbose', 'Verbose logging'
  c.when_called Factor::Commands::WorkflowCommand, :run
end

command 'run' do |c|
  c.syntax = 'factor run service_address params'
  c.description = 'Run a specific command.'
  c.option '--connector FILE', String, 'file to require for loading method'
  c.option '--verbose', 'Verbose logging'
  c.option '--settings FILE', String, 'factor.yml file path.'
  c.when_called Factor::Commands::RunCommand, :run
end

alias_command 'w', 'workflow'
alias_command 'r', 'run'