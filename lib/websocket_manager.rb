# encoding: UTF-8

require 'faye/websocket'
require 'uri'

# class for managing the web socket connections
class WebSocketManager
  attr_accessor :keep_open, :events, :state

  def initialize(uri, headers = {})
    u                     = URI(uri)
    u.scheme              = 'wss' if u.scheme == 'https'
    @uri                  = u.to_s
    @settings             = { ping: 10, retry: 5 }
    @settings[:headers]   = headers if headers && headers != {}
    @state                = :closed
    @events               = {}
  end

  def open
    if closed?
      @state = :opening
      connect
    end
    @state
  end

  def close
    if open?
      @state = :closing
      @ws.close
    end
    @state
  end

  def on(event, &block)
    @events[event] = block
  end

  def open?
    @state == :open
  end

  def opening?
    @state == :opening
  end

  def closed?
    @state == :closed
  end

  def closing?
    @state == :closing
  end

  def send(msg)
    @ws.send(msg)
  end

  private

  def call_event(event, data)
    @events[event].call(data) if @events[event]
  end

  def connect
    EM.run do
      begin
        @ws = Faye::WebSocket::Client.new(@uri, nil, @settings)

        @ws.on :close do |event|
          @state = :closed
          call_event :close, event
        end

        @ws.on :message do |msg|
          call_event :message, msg
        end

        @ws.on :open do |event|
          @state = :open
          call_event :open, event
        end

        @ws.on :error do |event|
          call_event :error, event
        end
      rescue => ex
        call_event :fail, ex.message
      end
    end
  end

end