module Factor
  module Runtime
    class ExecHandler
      attr_accessor :params, :service, :fail_block

      def initialize(service = nil, params = {})
        @service = service
        @params = params
      end

      def on_fail(&block)
        @fail_block = block
      end
    end
  end
end