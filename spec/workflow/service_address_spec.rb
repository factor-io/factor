# encoding: UTF-8

require 'spec_helper'

require 'factor/workflow/service_address'

describe Factor::Workflow::ServiceAddress do

  it 'fails on empty' do
    expect {
      Factor::Workflow::ServiceAddress.new('')
    }.to raise_error
  end

  it 'fails on no namespace' do
    expect {
      Factor::Workflow::ServiceAddress.new('foo')
    }.to raise_error
  end

  it 'fails on empty reference' do
    expect{
      Factor::Workflow::ServiceAddress.new('::::')
    }.to raise_error
  end

  it 'can identify namespace' do
    address = Factor::Workflow::ServiceAddress.new('a::b')
    expect(address.namespace).to eq([:a])
  end

  it 'can identify deep namespace' do
    address = Factor::Workflow::ServiceAddress.new('a::b::c')
    expect(address.namespace).to eq([:a,:b])
  end

  it 'can identify service name' do
    address = Factor::Workflow::ServiceAddress.new('a::b::c')
    expect(address.service).to eq(:a)
  end

  it 'can identify action/listener id' do
    address = Factor::Workflow::ServiceAddress.new('a::b::c')
    expect(address.id).to eq(:c)
  end

  it 'can the resource path' do
    address = Factor::Workflow::ServiceAddress.new('a::b::c::d')
    expect(address.resource).to eq([:b,:c])
  end

  it 'fails to get resource path if undefined' do
    address = Factor::Workflow::ServiceAddress.new('a::b')
    expect{
      address.resource
    }.to raise_error
  end

  it 'can initialize with array and convert to string' do
    address = ''
    expect {
      address = Factor::Workflow::ServiceAddress.new([:a, :b, :c])
    }.to_not raise_error
    expect(address.to_s).to eq('a::b::c')
  end
end
