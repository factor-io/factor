# encoding: UTF-8

module Factor
  module Connector
    class Error < StandardError
      attr_accessor :state, :exception

      def initialize(params = {})
        @exception = params[:exception]
        super(params[:message] || '')
      end
    end
  end
end