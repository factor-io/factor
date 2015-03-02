# encoding: UTF-8

require 'spec_helper'

require 'common/deep_struct'

describe Factor::Common::DeepStruct do
  it 'handles depth 1 Hash' do
    source = {
      a:'b'
    }

    result = Factor::Common.simple_object_convert source

    expect(result).to respond_to(:a)
    expect(result.a).to eq('b')
  end

  it 'handles depth n Hash' do
    source = {
      a:{
        b: 'c'
      }
    }

    result = Factor::Common.simple_object_convert source

    expect(result).to respond_to(:a)
    expect(result).to respond_to(:to_h)
    expect(result.a).to respond_to(:b, :to_h)
    expect(result.a.to_h).to eq(b:'c')
    expect(result.a.b).to eq('c')

  end

  it 'handles array of Hash' do
    source = [
      {a:'b'},
      {c:'d'}
    ]

    result = Factor::Common.simple_object_convert source

    expect(result).to be_a(Array)
    expect(result).to all(be_a(Factor::Common::DeepStruct))
    expect(result[0]).to respond_to(:a)
    expect(result[0].a).to eq('b')
    expect(result[1]).to respond_to(:c)
    expect(result[1].c).to eq('d')
  end
end
