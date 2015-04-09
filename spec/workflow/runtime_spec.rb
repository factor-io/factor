# encoding: UTF-8

require 'spec_helper'

require 'factor/workflow/runtime'
require 'factor/connector/definition'
require 'factor/connector/registry'

describe Factor::Workflow::Runtime do
  before do
    class MyDef < Factor::Connector::Definition
      id :my_def
      def initialize
        @some_var='some_var'
      end
      action :action do |data|
        info "info"
        warn "warn"
        error "error"
        respond foo: data[:foo], bar:'bar', some_var: @some_var
      end
      action :action_fail do |data|
        fail "Something broke"
        respond foo:'test'
      end
      listener :listener do
        t=nil
        start do |data|
          t = Thread.new do
            begin
              sleep 0.1
              trigger foo:'bar', a:data[:a]
              sleep 5
            end while true
          end

          respond started:'foo', c:data[:a]
        end
        stop do
          info 'killing'
          t.kill
          respond done:true
        end
      end
    end
  end

  it 'can run a connector action' do
    logger = Factor::Log::BasicLogger.new
    runtime = Factor::Workflow::Runtime.new({}, logger:logger)

    runtime.run 'my_def::action', foo:'sweet'

    # Here we need to have the expect blocks that listen for the output of runtime.run
  end

  it 'can run a workflow' do
  end
end
