require 'rspec'
require 'rspec/expectations'
require 'rspec/matchers'
require 'wrong/adapters/rspec'

module Factor
  module Connector


    class Runtime
      include Wrong
      include RSpec::Matchers

      attr_accessor :responses, :last_message

      def expect_log(message)
        expect_hash(type:'log', message:message)
      end

      def expect_info(message)
        expect_hash(type:'log', status:'info', message:message)
      end

      def expect_warn(message)
        expect_hash(type:'log', status:'warn', message:message)
      end

      def expect_error(message)
        expect_hash(type:'log', status:'error', message:message)
      end

      def expect_response(data={})
        expect_hash(type:'response', data:data)
      end

      def expect_fail(message=nil)
        hash = {type:'fail'}
        hash[:message] = message if message
        expect_hash(hash)
      end

      def expect_hash(hash={})
        set_callback
        
        eventually do
          expect(@responses).to include( a_hash_including(hash) )
        end
      end

      def expect_eventually(options, something)
        set_callback
        
        options={}
        eventually(options) do
          expect(@responses).to include( something )
        end
      end

      private

      def set_callback
        @responses ||= []
        @last_message ||= ''
        unless self.callback
          callback do |data|
            @responses << data
            @last_message = data
          end  
        end
      end
    end
  end
end