require 'faye/websocket'
require 'multi_json'
require 'uuid'

port = ARGV[0] || 3000

uuid = UUID.new

EM.run {
  url = "ws://localhost:#{port}/"
  ws  = Faye::WebSocket::Client.new url, nil

  identity = uuid.generate

  puts "Connecting to #{ws.url}"

  ws.onopen = lambda do |event|
    p [:open]

    payload = MultiJson.dump identity: identity,
                             job_id: 'J-1',
                             job_type: 'restart_apache'

    ws.send payload
  end

  ws.onmessage = lambda do |event|
    p [:message, event.data]
    # ws.close
  end

  ws.onclose = lambda do |event|
    p [:close, event.code, event.reason]

    EM.stop
  end
}
