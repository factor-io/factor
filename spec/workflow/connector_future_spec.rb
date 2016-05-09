# encoding: UTF-8

require 'spec_helper'

require 'factor/workflow/connector_future'
require 'factor/connector'

describe Factor::Workflow::ConnectorFuture do
  it 'can handle triggers' do
    logger = double('logger', log:true, trigger:true)
    class Sample < Factor::Connector
      def run
        trigger this:'is useful'
      end
    end

    connector        = Sample.new
    connector_future = Factor::Workflow::ConnectorFuture.new(connector)

    connector_future.on(:trigger) do |data|
      logger.trigger(data)
    end

    expect(logger).to receive(:trigger).with(this:'is useful')

    connector_future.wait
  end

  it 'can handle logs' do
    logger = double('logger', info: true)
    class Sample < Factor::Connector
      def run
        info 'Hi'
      end
    end

    connector        = Sample.new
    connector_future = Factor::Workflow::ConnectorFuture.new(connector)

    connector_future.on(:info) do |data|
      logger.info(data)
    end

    expect(logger).to receive(:info).with('Hi')

    connector_future.wait
  end
end
