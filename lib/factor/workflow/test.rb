require 'rspec'
require 'rspec/expectations'
require 'rspec/matchers'
require 'wrong'

module Factor
  module Workflow
    module Test

      RSpec::Matchers.define :log do |expected|
        match do |actual|
          begin
            Wrong.eventually do
              actual.history.any? do |log|
                case expected.class.name
                when 'Hash'
                  status = expected.keys.first.to_s
                  message = expected.values.first
                  status_match = log[:status].to_s == status.to_s
                  message_match = log[:message].end_with? message
                  status_match && message_match
                when 'String'
                  log[:message].end_with? expected
                when 'Symbol'
                  log[:status].to_s == expected.to_s
                else
                  false
                end
              end
            end
            true
          rescue => ex
            false
          end
        end

        failure_message do
          case expected.class.name
          when 'Hash'
            status = expected.keys.first.to_s
            message = expected.values.first
            "expected #{actual.history} to log '#{status}' message '#{message}'"
          when 'Symbol'
            "expected #{actual.history} to log '#{expected}'"
          when 'String'
            "expected #{actual.history} to log message '#{expected}'"
          else
            "#{expected.class} is an unrecognizable matcher type"
          end
        end
      end
    end
  end
end