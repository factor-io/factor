# encoding: UTF-8

require 'spec_helper'

require 'factor/workflow/future'

describe Factor::Workflow::Future do
  it 'can run transition through successful states' do

    future = Factor::Workflow::Future.new do
      sleep 0.1
      'test'
    end

    expect(future.state).to eq(:unscheduled)
    expect(future.pending?).to be false
    expect(future.rejected?).to be false
    expect(future.fulfilled?).to be false
    expect(future.unscheduled?).to be true

    future.execute

    expect(future.state).to eq(:pending)
    expect(future.pending?).to be true
    expect(future.rejected?).to be false
    expect(future.fulfilled?).to be false
    expect(future.unscheduled?).to be false
    sleep 0.2

    expect(future.state).to eq(:fulfilled)
    expect(future.pending?).to be false
    expect(future.rejected?).to be false
    expect(future.fulfilled?).to be true
    expect(future.unscheduled?).to be false

    expect(future.value).to eq('test')
  end

  it 'can return a value' do
    future = Factor::Workflow::Future.new { 'test' }

    future.execute
    future.wait
    expect(future.state).to eq(:fulfilled)
  end

  it 'can wait' do
    future = Factor::Workflow::Future.new do
      sleep 0.1
      'test'
    end

    future.wait
    expect(future.value).to eq('test')
  end

  it 'can handle failures' do
    future = Factor::Workflow::Future.new do
      raise ArgumentError, 'test'
    end

    future.wait
    expect(future.state).to eq(:rejected)
    expect(future.pending?).to be false
    expect(future.rejected?).to be true
    expect(future.fulfilled?).to be false
    expect(future.unscheduled?).to be false

    expect(future.reason).to be_a(ArgumentError)
  end
end
