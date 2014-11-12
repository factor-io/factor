# # encoding: UTF-8

# require 'websocket_manager'

# module Factor
#   # Class Listener for integrating with connector service
#   class Listener
#     def initialize(url)
#       @url = url
#     end

#     def listener(listener_id)
#       listen("#{@url}/listeners/#{listener_id}")
#     end

#     def action(action_id)
#       listen("#{@url}/actions/#{action_id}")
#     end

#     private

#     def listen(uri_path)
#       WebSocketManager.new(uri_path)
#     end
#   end
# end
