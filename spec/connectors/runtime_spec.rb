# encoding: UTF-8

require 'spec_helper'

require 'connector/definition'
require 'connector/runtime'
require 'connector/test'

describe Factor::Connector::Runtime do
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
        start do |params|
        end
        stop do
        end
      end
    end
    @runtime = Factor::Connector::Runtime.new(MyDef)
  end


  it 'can run action and handle parameters' do
    
    # @runtime.run([:action], foo:'bar')

    # sleep 2
    # wait_for(@runtime.last_message[:message]).to eq('info')

    # expect(response).to be_a(Hash)
    # expect(response.keys).to include(:foo)
    # expect(response.keys).to include(:bar)
    # expect(response.keys).to include(:some_var)
    # expect(response[:foo]).to eq('bar')
    # expect(response[:bar]).to eq('bar')
    # expect(response[:some_var]).to eq('some_var')
  end

  it 'can fail an action' do
    # expect {
    #   @runtime.run([:action_fail])
    # }.to raise_error(Factor::Connector::Error)
  end
  
end
