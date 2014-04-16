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
                                 routing_key: 'com.rakuten.chef.restart_apache',
                                 reply_to: reply_to
  end

  identity = 'an_uniq_key' # TODO

  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    ws.on :message do |event|
      request = MultiJson.load event.data

      case request['job_type']
      when 'restart_apache'
        payload = MultiJson.dump request

        dispatch_payload.call payload, identity
      end

      queue = channel.queue '', auto_delete: true
      queue.bind 'com.rakuten.chef.rpc.fanout', routing_key: identity

      queue.subscribe do |metadata, payload|
        ws.send payload
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
