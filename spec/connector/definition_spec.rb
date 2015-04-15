# encoding: UTF-8

require 'spec_helper'

require 'factor/connector/definition'

describe Factor::Connector::Definition do
  before do
    class MyDef < Factor::Connector::Definition
      id :my_def
      action :action_1 do
      end
      listener :listener_1 do
        start do |params|
        end
        stop do
        end
      end
      resource :nest_1 do
        action :action_nested_1 do
        end
        listener :listener_nested_1 do
          start do |params|
          end
          stop do |params|
          end
        end
        resource :nest_2 do
          action :action_nested_2 do
          end
          listener :listener_nested_2 do
            start do |params|
            end
            stop do |params|
            end
          end
        end
      end
    end
    @definition = MyDef.new
  end

  it 'can set the ID' do
    expect(@definition).to respond_to(:id)
    expect(@definition.id).to eq(:my_def)
  end

  it 'can define an action' do
    actions = @definition.class.instance_variable_get('@actions')
    expect_proc_in(actions,[:action_1])
  end

  it 'can define a listener' do
    listeners = @definition.class.instance_variable_get('@listeners')
    expect_proc_in(listeners,[:listener_1,:start])
    expect_proc_in(listeners,[:listener_1,:stop])
  end

  it 'can created nested actions and listeners' do
    actions = @definition.class.instance_variable_get('@actions')
    listeners = @definition.class.instance_variable_get('@listeners')
    
    expect_proc_in(actions,[:nest_1,:action_nested_1])
    expect_proc_in(actions,[:nest_1,:nest_2,:action_nested_2])
    expect_proc_in(listeners, [:nest_1, :listener_nested_1, :start])
    expect_proc_in(listeners, [:nest_1, :listener_nested_1, :stop])
    expect_proc_in(listeners, [:nest_1, :nest_2, :listener_nested_2, :start])
    expect_proc_in(listeners, [:nest_1, :nest_2, :listener_nested_2, :stop])
  end

  def expect_proc_in(method,key)
    expect(method).to_not be(nil)
    expect(method).to be_a(Hash)
    expect(method.keys).to include(key)
    expect(method[key]).to_not be(nil)
    expect(method[key]).to be_a(Proc)
  end
end
