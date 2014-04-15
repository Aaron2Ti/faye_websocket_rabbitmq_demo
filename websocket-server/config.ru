require 'faye/websocket'
require 'multi_json'

Faye::WebSocket.load_adapter('thin')

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    ws.on :message do |event|
      request = MultiJson.load event.data

      puts request

      ws.send MultiJson.dump(progress: 2)
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]

      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    [200, {'Content-Type' => 'text/plain'}, ['Noops']]
  end
end

run App
