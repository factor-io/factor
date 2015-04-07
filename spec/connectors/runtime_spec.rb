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
    @runtime = Factor::Connector::Runtime.new(MyDef)
  end

  describe 'Actions' do
    it 'can run and handle parameters' do
      
      @runtime.run([:action], foo:'bar')

      @runtime.expect_info 'info'
      @runtime.expect_warn 'warn'
      @runtime.expect_response a_hash_including(foo:'bar')
      @runtime.expect_response a_hash_including(bar:'bar')
      @runtime.expect_response a_hash_including(some_var: 'some_var')
    end

    it 'can fail' do
      @runtime.run([:action_fail], foo:'bar')
      @runtime.expect_fail('Something broke')
    end
  end

  describe 'Listeners' do
    it 'can start and stop' do
      @runtime.start_listener([:listener], a:'b')
      @runtime.expect_response started:'foo', c:'b'
      @runtime.expect_trigger foo:'bar', a:'b'
      @runtime.stop_listener
      @runtime.expect_info 'killing'
      @runtime.expect_response done:true
    end
  end
  
end
