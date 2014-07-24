require "codeclimate-test-reporter"
require 'stringio'

CodeClimate::TestReporter.start do
  add_filter "/spec/"
end

$:.unshift File.dirname(__FILE__) + '/../lib'

def mock_terminal
  @input = StringIO.new
  @output = StringIO.new
  $terminal = HighLine.new @input, @output
end