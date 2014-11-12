require 'websocket_manager'
require 'eventmachine'

module Factor
  module Runtime
    class ServiceCaller
      def initialize(connector_url)
        @url = connector_url
        @subscribers = {}
      end

      def listen(listener_id, params={})
        call("#{@url}/listeners/#{listener_id}", params)
      end

      def action(action_id, params={})
        call("#{@url}/actions/#{action_id}", params)
      end

      def close
        @ws.close
      end

      def on(event, &block)
        @subscribers ||= {}
        @subscribers[event.to_sym] ||= []
        @subscribers[event.to_sym] << block
      end

      private

      def call(url, params={})
        @ws = Factor::WebSocketManager.new(url)

        @ws.on :open do
          notify :open
        end

        @ws.on :close do
          notify :close
        end

        @ws.on :error do
          notify :fail, message: 'Connection dropped while calling action'
        end

        @ws.on :message do |event|
          action_response = JSON.parse(event.data)
          case action_response['type']
          when 'return'
            notify :return, action_response['payload']
          when 'fail'
            @ws.close
            notify :log, status:'error', message: "  #{action_response['message']}"
            notify :fail
          when 'log'
            message = "  #{action_response['message']}"
            notify :log, status: action_response['status'], message: message
          when 'start_workflow'
            notify :start_workflow, action_response
          else
            notify :log, status:'error', message: "Unknown action response: #{action_response}"
          end
        end

        @ws.open
        @ws.send(params)
      end

      def notify(event, params={})
        if @subscribers[event]
          @subscribers[event].each do |block|
            EM.next_tick { block.call(params) }
          end
        end
      end
    end
  end
end
