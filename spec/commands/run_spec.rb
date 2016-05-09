# encoding: UTF-8

require 'spec_helper'

require 'factor/commands/run_command'
require 'factor/connector'
require 'ostruct'

describe Factor::Commands::RunCommand do
  it 'can run a connector from the commandline' do
    logger = double('logger', log: true, indent: true)

    class Sample < Factor::Connector
      attr_accessor :test_param
      def initialize(options={})
        @test_param = options[:test]
      end

      def run
        'Hello'
      end
    end

    Factor::Connector.register(Sample)

    run_command = Factor::Commands::RunCommand.new(logger: logger)

    expect(logger).to receive(:log).with(:info, /Using default '.*' settings file/)
    expect(logger).to receive(:log).with(:warn, /Couldn\'t open the settings file '.*', continuing without settings/)
    expect(logger).to receive(:log).with(:info, "Running 'sample({})'")
    expect(logger).to receive(:log).with(:success, "Response:")

    run_command.run(['sample'],OpenStruct.new(verbose: true))
  end
end
