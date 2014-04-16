require 'amqp'
require 'multi_json'

EM.run {
  connection = AMQP.connect host: '127.0.0.1'
  channel    = AMQP::Channel.new(connection)

  queue = channel.queue 'com.rakuten.chef.direct.apaches', durable: true

  queue.bind 'com.rakuten.chef.direct', routing_key: 'restart_apache'

  exchange = channel.direct 'com.rakuten.chef.direct', durable: true

  process_result = ->(job, i) do
    if i == 4
      "Job #{job['job_type']} is processed: 100%"
    else
      "Job #{job['job_type']} is processed: #{i * 20 + rand(20)}%"
    end
  end

  queue.subscribe do |metadata, payload|
    job = MultiJson.load payload

    EM.add_timer(2) {
      exchange.publish process_result.(job, 1), routing_key: metadata.reply_to

      EM.add_timer(2) {
        exchange.publish process_result.(job, 2), routing_key: metadata.reply_to

        EM.add_timer(2) {
          exchange.publish process_result.(job, 3), routing_key: metadata.reply_to

          EM.add_timer(2) {
            exchange.publish process_result.(job, 4), routing_key: metadata.reply_to
          }
        }
      }
    }
  end
}
