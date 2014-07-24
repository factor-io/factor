require "codeclimate-test-reporter"
require 'stringio'

CodeClimate::TestReporter.start do
  add_filter "/spec/"
end

$:.unshift File.dirname(__FILE__) + '/../lib'

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end