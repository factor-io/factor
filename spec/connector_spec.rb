# encoding: UTF-8

require 'spec_helper'

require 'factor/commands/run_command'

describe Factor::Connector do

  it 'can register and retreive a class' do
    class Sample < Factor::Connector
    end

    registered = Factor::Connector.register(Sample)
    found_class = Factor::Connector.get('sample')

    expect(registered).to eq(Sample)
    expect(found_class).to be(Sample)
  end

  it 'can handle logs' do
    logger = double('logger', log:true, trigger:true)
    class Sample < Factor::Connector
      def run
        debug 'debug'
        info 'i talk a lot'
        warn 'careful'
        success 'good news'
        error 'bad news'
      end
    end
    
    connector = Sample.new
    connector.add_observer(logger, :trigger)

    expect(logger).to receive(:trigger).with(:debug, 'debug')
    expect(logger).to receive(:trigger).with(:info, 'i talk a lot')
    expect(logger).to receive(:trigger).with(:warn, 'careful')
    expect(logger).to receive(:trigger).with(:success, 'good news')
    expect(logger).to receive(:trigger).with(:error, 'bad news')

    connector.run
  end

  it 'can handle triggers' do
    logger = double('logger', log:true, trigger:true)
    class Sample < Factor::Connector
      def run
        trigger this:'is useful'
      end
    end

    connector = Sample.new
    connector.add_observer(logger, :trigger)

    expect(logger).to receive(:trigger).with(:trigger, this:'is useful')

    connector.run
  end

  it 'recgonizes deeper inheritence to Factor::Connector on initialize' do
    module X
      module Y
        class Z < Factor::Connector
        end
      end
    end
    expect{Factor::Connector.register(X::Y::Z)}.not_to raise_error
  end

  it 'raises if not inherited from Factor::Connector on initialize' do
    class FailClass
    end
    expect{Factor::Connector.register(FailClass)}.to raise_error(ArgumentError)
  end
end
