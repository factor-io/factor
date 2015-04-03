# encoding: UTF-8

require 'codeclimate-test-reporter'
require 'stringio'

if ENV['CODECLIMATE_REPO_TOKEN']
  CodeClimate::TestReporter.start do
    add_filter '/spec/'
  end
end

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

def capture_stdout(&_block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end
