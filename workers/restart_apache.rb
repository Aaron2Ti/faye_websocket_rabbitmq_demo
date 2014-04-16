require 'amqp'

EM.run {
  connection = AMQP.connect host: '127.0.0.1'
  channel    = AMQP::Channel.new(connection)

  queue = channel.queue 'com.rakuten.chef.direct.apaches', durable: true

  queue.bind 'com.rakuten.chef.direct', routing_key: 'com.rakuten.chef.restart_apache'

  queue.subscribe do |metadata, payload|
    exchange = channel.fanout 'com.rakuten.chef.rpc.fanout', auto_delete: true

    EventMachine.add_timer(1) {
      5.times do |i|
        exchange.publish "processed: #{25 * i}", routing_key: metadata.reply_to
      end
    }
  end
}
