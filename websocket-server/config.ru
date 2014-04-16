require 'faye/websocket'
require 'multi_json'
require 'amqp'
require 'pry'

Faye::WebSocket.load_adapter('thin')

App = lambda do |env|

  # {{{
  connection           = AMQP.connect host: '127.0.0.1'
  channel              = AMQP::Channel.new connection
  chef_direct_exchange = channel.direct 'com.rakuten.chef.direct', durable: true
  # }}}

  # {{{
  dispatch_payload = ->(payload, reply_to) do
    chef_direct_exchange.publish payload,
                                 persistent: true,
                                 routing_key: 'restart_apache',
                                 reply_to: reply_to
  end
  # }}}

  # {{{
  ws_handler = ->(env) do
    ws = Faye::WebSocket.new(env)

    req      = Rack::Request.new env
    identity = req.params['identity']

    process_result_queue = channel.queue '', exclusive: true

    process_result_queue.bind 'com.rakuten.chef.direct', routing_key: identity

    process_result_queue.subscribe do |metadata, payload|
      puts "Send the processing result to client #{payload}"

      ws.send payload
    end

    ws.on :message do |event|
      request  = MultiJson.load event.data
      payload  = event.data

      dispatch_payload.call payload, identity
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      puts "deleting queue: #{process_result_queue.name}"

      process_result_queue.delete

      ws = nil
    end

    # Return async Rack response
    ws.rack_response
  end
  # }}}

  if Faye::WebSocket.websocket?(env)
    ws_handler.call env

  else
    # Normal HTTP request
    [200, {'Content-Type' => 'text/plain'}, ['Noops']]
  end
end

run App

# vim: foldmethod=marker
