# encoding: UTF-8

require 'spec_helper'

require 'factor/logger'

describe Factor::Logger do
  before :all do
    @logger = Factor::Logger.new
  end
  
  it 'logs with coloring' do
    expect { @logger.info('test')    }.to output(/\[37m.*\[0m/).to_stdout
    expect { @logger.success('test') }.to output(/\[32m.*\[0m/).to_stdout
    expect { @logger.warn('test')    }.to output(/\[33m.*\[0m/).to_stdout
    expect { @logger.error('test')   }.to output(/\[31m.*\[0m/).to_stdout
    expect { @logger.debug('test')   }.to output(/\[38;5;59m.*\[0m/).to_stdout
  end

  it 'logs even when type not recognized' do
    expect { @logger.log(:not_here, 'test') }.to output(/test/).to_stdout
  end

  it 'logs with the right format' do
    expect { @logger.info('test')}.to output(/\[[0-9]{2}\/[0-9]{2}\/[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}\]\s.*test\e\[0m\n/).to_stdout
  end

  it 'logs with indentation' do
    expect do
      @logger.indent 2 do
        @logger.info('test')
      end
    end.to output(/\s{4}\e\[37m.*\[0m/).to_stdout
  end
end
