require 'faye/websocket'
require 'multi_json'
require 'amqp'

Faye::WebSocket.load_adapter('thin')


App = lambda do |env|
  connection           = AMQP.connect host: '127.0.0.1'
  channel              = AMQP::Channel.new connection
  chef_direct_exchange = channel.direct 'com.rakuten.chef.direct', durable: true

  dispatch_payload = ->(payload, reply_to) do
    chef_direct_exchange.publish payload,
                                 persistent: true,
                                 routing_key: 'restart_apache',
                                 reply_to: reply_to
  end

  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    queue = channel.queue '', exclusive: true

    ws.on :message do |event|
      payload  = event.data
      request  = MultiJson.load event.data
      identity = request['identity']

      queue.bind 'com.rakuten.chef.direct', routing_key: identity

      dispatch_payload.call payload, identity

      queue.subscribe do |metadata, payload|
        puts 'recieved process results'
        ws.send payload
      end

      ws.on :close do |event|
        puts "deleting queue: #{queue.name}"

        queue.delete
      end
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
