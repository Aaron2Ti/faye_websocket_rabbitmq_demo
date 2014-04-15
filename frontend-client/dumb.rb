require 'faye/websocket'
require 'multi_json'

port = ARGV[0] || 3000

EM.run {
  url = "ws://localhost:#{port}/"
  ws  = Faye::WebSocket::Client.new url, nil

  puts "Connecting to #{ws.url}"

  ws.onopen = lambda do |event|
    p [:open]

    ws.send MultiJson.dump(job_id: 'J-1', job_type: 'restart_apache')
  end

  ws.onmessage = lambda do |event|
    p [:message, MultiJson.load(event.data)]

    ws.close
  end

  ws.onclose = lambda do |event|
    p [:close, event.code, event.reason]
    EM.stop
  end
}
