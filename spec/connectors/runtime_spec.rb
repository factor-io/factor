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
    
    @runtime.run([:action], foo:'bar')

    @runtime.expect_info 'info'
    @runtime.expect_warn 'warn'
    @runtime.expect_response a_hash_including(foo:'bar')
    @runtime.expect_response a_hash_including(bar:'bar')
    @runtime.expect_response a_hash_including(some_var: 'some_var')
  end

  it 'can fail an action' do
    # expect {
    #   @runtime.run([:action_fail])
    # }.to raise_error(Factor::Connector::Error)
  end
  
end
