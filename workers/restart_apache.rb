require 'amqp'

EM.run {
  connection = AMQP.connect host: '127.0.0.1'
  channel    = AMQP::Channel.new(connection)

  queue = channel.queue 'com.rakuten.chef.direct.apaches', durable: true

  queue.bind 'com.rakuten.chef.direct', routing_key: 'restart_apache'

  exchange = channel.direct 'com.rakuten.chef.direct', durable: true

  queue.subscribe do |metadata, payload|
    EM.add_timer(5) {
      puts 'send message' + metadata.reply_to
      exchange.publish "processed: 25", routing_key: metadata.reply_to

      EM.add_timer(5) {
        exchange.publish "processed: 50", routing_key: metadata.reply_to

        EM.add_timer(5) {
          exchange.publish "processed: 75", routing_key: metadata.reply_to

          EM.add_timer(5) {
            exchange.publish "processed: 100", routing_key: metadata.reply_to
          }
        }
      }
    }
  end
}
