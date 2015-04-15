# encoding: UTF-8

require 'spec_helper'

require 'factor/connector/definition'
require 'factor/connector/runtime'
require 'factor/connector/test'

describe Factor::Connector::Runtime do
  include Factor::Connector::Test

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

      expect(@runtime).to message info:'info'
      expect(@runtime).to message warn:'warn'
      expect(@runtime).to respond foo:'bar', bar:'bar', some_var:'some_var'
    end

    it 'can fail' do
      @runtime.run([:action_fail], foo:'bar')
      expect(@runtime).to fail 'Something broke'
    end
  end

  describe 'Listeners' do
    it 'can start, stop, trigger and handle parameters' do
      @runtime.start_listener([:listener], a:'b')
      expect(@runtime).to respond started:'foo', c:'b'
      expect(@runtime).to trigger foo:'bar', a:'b'
      @runtime.stop_listener
      expect(@runtime).to message info:'killing'
      expect(@runtime).to respond done:true
    end
  end
end
