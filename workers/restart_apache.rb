require 'amqp'

EM.run {
  connection = AMQP.connect host: '127.0.0.1'
  channel    = AMQP::Channel.new(connection)

  q1 = channel.queue('com.rakuten.chef.direct.apaches', durable: true)

  q1.bind('com.rakuten.chef.direct', routing_key: 'com.rakuten.chef.restart_apache')

  q1.subscribe do |payload|
    puts "Queue #{q1.name} received: #{payload}"
  end
}
