require 'amqp'

EM.run {
  connection = AMQP.connect host: '127.0.0.1'
  channel    = AMQP::Channel.new(connection)

  queue = channel.queue('com.rakuten.chef.direct.apaches', durable: true)

  queue.bind('com.rakuten.chef.direct', routing_key: 'com.rakuten.chef.restart_apache')

  queue.subscribe do |metadata, payload|
    puts "Queue #{queue.name} received: #{payload} -- #{metadata.reply_to}"
  end
}
