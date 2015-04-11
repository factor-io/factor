# encoding: UTF-8

require 'spec_helper'

require 'factor/workflow/runtime'
require 'factor/workflow/test'
require 'factor/connector/definition'
require 'factor/connector/registry'
require 'factor/logger/test'

describe Factor::Workflow::Runtime do
  before :all do
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
          info 'i am starting'
          t = Thread.new do
            begin
              trigger foo:'bar', a:data[:a]
              sleep 5
            end while true
          end
        end
        stop do
          info 'killing'
          t.kill
          respond done:true
        end
      end
    end
    @logger  = Factor::Log::TestLogger.new
    @runtime = Factor::Workflow::Runtime.new({}, logger:@logger)
  end

  before :each do
    @logger.clear
  end

  it 'can run a connector action' do
    @runtime.run 'my_def::action', foo:'sweet'

    expect(@logger).to log success:'Starting'
    expect(@logger).to log info:'info'
    expect(@logger).to log warn:'warn'
    expect(@logger).to log error:'error'
    expect(@logger).to log success:'Completed'
  end

  it 'can fail a connector action' do
    @runtime.run 'my_def::action_fail', foo:'sweet'

    expect(@logger).to log error:'Failed: Something broke'
  end

  it 'can run a workflow' do
    workflow_definition = "
      listen 'my_def::listener' do
        info 'sweet'
      end
    "
    @runtime.load(workflow_definition)
     
    expect(@logger).to log success:'Starting'
    expect(@logger).to log info:'i am starting'
    expect(@logger).to log success: 'Triggered'
    expect(@logger).to log info: 'sweet'
    expect(@logger).to log success:'Started'

    @runtime.unload

    expect(@logger).to log success:'Stopping'
    expect(@logger).to log success:'Stopped'

  end
end
