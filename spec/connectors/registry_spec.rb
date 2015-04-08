# encoding: UTF-8

require 'spec_helper'

require 'factor/connector/definition'
require 'factor/connector/registry'

describe Factor::Connector::Registry do
  before do
    class MyDef < Factor::Connector::Definition
      id :my_def
    end

  end

  it 'can load definition by ID' do
    definition = Factor::Connector::Registry.get(:my_def)
    expect(definition).to be_a(MyDef)
    expect(definition.class.superclass).to eq(Factor::Connector::Definition)
  end

  it 'fails on bad ID' do
    expect {
      Factor::Connector::Registry.get(:foo)
    }.to raise_error
  end

end
