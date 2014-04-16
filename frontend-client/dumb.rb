# {{{
require 'faye/websocket'
require 'multi_json'
require 'uuid'

port = ARGV[0] || 3000

uuid = UUID.new

identity = uuid.generate

new_job = ->(job_type) do
  {
    job_id:   uuid.generate,
    job_type: job_type,
    args:     'whatever...'
  }
end

fake_job_payload = ->(job_type) do
  MultiJson.dump new_job.call(job_type)
end

send_job = ->(ws, payload) do
  puts "Send a job to the websocket server: #{payload}"

  ws.send payload
end
# }}}

EM.run {
  url = "ws://localhost:#{port}/?identity=#{identity}"
  ws  = Faye::WebSocket::Client.new url, nil

  puts "Connecting to #{ws.url}"

  ws.onopen = lambda do |event|
    send_job.call ws, fake_job_payload.call('restart_apache')
    send_job.call ws, fake_job_payload.call('gracefully_kill_it')
    send_job.call ws, fake_job_payload.call('recent_5_current_time')
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

# vim: foldmethod=marker
