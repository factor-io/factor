require 'websocket_manager'
require 'eventmachine'

module Factor
  module Runtime
    class ServiceCaller
      attr_accessor :reconnect, :retry_period

      def initialize(connector_url, options = {})
        @url = connector_url
        @subscribers = {}
        @reconnect = options[:reconnect] || true
        @retry_period = options[:retry_period] || 5
        @retry_count = 0
        @offline_duration = 0
      end

      def listen(listener_id, params={})
        @reconnect = true
        call("#{@url}/listeners/#{listener_id}", params)
      end

      def action(action_id, params={})
        @reconnect = false
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

      def start(params)
        @ws.open
        @ws.send(params)
      end

      def retry_connection(params)
        @retry_count += 1
        notify :retry, count: @retry_count, offline_duration: @offline_duration
        @offline_duration += @retry_period

        EM.next_tick{
          sleep @retry_period
          start(params)
        }
      end

      def call(url, params={})
        @ws = Factor::WebSocketManager.new(url)

        @ws.on :open do
          @retry_count = 0
          @offline_duration = 0
          notify :open
        end

        @ws.on :close do
          notify :close if @retry_count == 0
          retry_connection(params) if @reconnect
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
            notify :start_workflow, action_response['payload']
          else
            notify :log, status:'error', message: "Unknown action response: #{action_response}"
          end
        end

        start(params)
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
