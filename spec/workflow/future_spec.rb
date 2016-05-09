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
    expect(future.completed?).to be false

    future.execute

    expect(future.state).to eq(:pending)
    expect(future.pending?).to be true
    expect(future.rejected?).to be false
    expect(future.fulfilled?).to be false
    expect(future.unscheduled?).to be false
    expect(future.completed?).to be false
    sleep 0.2

    expect(future.state).to eq(:fulfilled)
    expect(future.pending?).to be false
    expect(future.rejected?).to be false
    expect(future.fulfilled?).to be true
    expect(future.unscheduled?).to be false
    expect(future.completed?).to be true

    expect(future.value).to eq('test')
  end

  it 'can wait' do
    future = Factor::Workflow::Future.new { 'test' }

    future.execute
    future.wait
    expect(future.state).to eq(:fulfilled)
    expect(future.completed?).to be true
    expect(future.fulfilled?).to be true
  end

  it 'can return a value' do
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
    expect(future.completed?).to be true

    expect(future.reason).to be_a(ArgumentError)
  end

  it 'can handle failures with rescue' do
    failure_future = Factor::Workflow::Future.new do
      raise ArgumentError, 'test'
    end.rescue do |error|
      "type: #{error.class}, message: #{error.message}"
    end

    failure_future.wait
    expect(failure_future.value).to eq('type: ArgumentError, message: test')
  end

  it 'can pass on to #then' do
    then_future = Factor::Workflow::Future.new do
      'Bob'
    end.then do |name|
      "Hello, #{name}"
    end

    then_future.wait
    expect(then_future.value).to eq('Hello, Bob')
  end

  describe 'aggregations' do
    it 'can pass on all' do
      f1 = Factor::Workflow::Future.new { 'a' }
      f2 = Factor::Workflow::Future.new { 'a' }

      f_all = Factor::Workflow::Future.all(f1,f2) { |f| f == 'a' }
      f_all.wait

      expect(f_all.value).to be true
    end

    it 'can fail on all' do
      f1 = Factor::Workflow::Future.new { 'a' }
      f2 = Factor::Workflow::Future.new { 'b' }

      f_all = Factor::Workflow::Future.all(f1,f2) { |f| f == 'a' }
      f_all.wait

      expect(f_all.state).to be :rejected
      expect(f_all.reason).to be_a(StandardError)
      expect(f_all.reason.message).to eq('There were no successful events')
    end

    it 'can pass on any with all true' do
      f1 = Factor::Workflow::Future.new { 'a' }
      f2 = Factor::Workflow::Future.new { 'a' }

      f_any = Factor::Workflow::Future.any(f1,f2) { |f| f == 'a' }
      f_any.wait

      expect(f_any.value).to be true
    end

    it 'can pass on any with one true' do
      f1 = Factor::Workflow::Future.new { 'a' }
      f2 = Factor::Workflow::Future.new { 'b' }

      f_any = Factor::Workflow::Future.any(f1,f2) { |f| f == 'a' }
      f_any.wait

      expect(f_any.value).to be true
    end

    it 'can fail on any' do
      f1 = Factor::Workflow::Future.new { 'b' }
      f2 = Factor::Workflow::Future.new { 'b' }

      f_any = Factor::Workflow::Future.any(f1,f2) { |f| f == 'a' }
      f_any.wait

      expect(f_any.state).to be :rejected
      expect(f_any.reason).to be_a(StandardError)
      expect(f_any.reason.message).to eq('There were no successful events')
    end
  end
end
