# encoding: UTF-8

require 'coveralls'
require 'stringio'

Coveralls.wear!

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
