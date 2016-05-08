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
end
