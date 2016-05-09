# encoding: UTF-8

require 'spec_helper'

require 'factor/workflow/dsl'
require 'factor/connector'
require 'factor/workflow/connector_future'

describe Factor::Workflow::DSL do
  it 'can log' do
    logger = double('logger', log: true)

    dsl = Factor::Workflow::DSL.new(logger:logger)
    
    log_methods = %w{info debug warn error success}

    log_methods.each do |method|
      message = "#{method} test"
      expect(logger).to receive(:log).with(method.to_sym, message)
      dsl.send(method.to_sym, message)
    end
  end

  it 'can initialize via run' do
    class Sample < Factor::Connector
      attr_accessor :test_param
      def initialize(options={})
        @test_param = options[:test]
      end
    end

    Factor::Connector.register(Sample)

    dsl = Factor::Workflow::DSL.new

    connector_future = dsl.run('sample', test:'foo')

    expect(connector_future).to be_a(Factor::Workflow::ConnectorFuture)
    expect(connector_future.action).to be_a(Sample)
    expect(connector_future.action.test_param).to eq('foo')
  end
end
