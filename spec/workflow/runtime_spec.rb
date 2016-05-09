# encoding: UTF-8

require 'spec_helper'

require 'factor/workflow/runtime'
require 'factor/connector'

describe Factor::Workflow::Runtime do
  it 'can initialize and load a DSL and execute the workflow' do
    class Sample < Factor::Connector
      attr_accessor :test_param
      def initialize(options={})
        @test_param = options[:test]
      end

      def run
        "It worked: #{@test_param}"
      end
    end
    Factor::Connector.register(Sample)

    runtime = Factor::Workflow::Runtime.new

    result = runtime.load do
      r = run 'sample', test:'something'
      r.wait
      r.value
    end

    expect(result).to eq('It worked: something')
  end
end
