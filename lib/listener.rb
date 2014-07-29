# encoding: UTF-8

require 'rest_client'
require 'websocket_manager'

module Factor
  # Class Listener for integrating with connector service
  class Listener
    def initialize(url)
      @url = url
    end

    def definition
      get("#{@url}/definition")
    end

    def listener(listener_id)
      listen("#{@url}/listeners/#{listener_id}")
    end

    def action(action_id)
      listen("#{@url}/actions/#{action_id}")
    end

    private

    def post(uri_path, payload)
      content = { 'payload' => MultiJson.dump(payload) }
      JSON.parse(RestClient.post(uri_path, content))
    end

    def get(uri_path)
      JSON.parse(RestClient.get(uri_path))
    end

    def delete(uri_path)
      JSON.parse(RestClient.delete(uri_path))
    end

    def listen(uri_path)
      WebSocketManager.new(uri_path)
    end
  end
end
