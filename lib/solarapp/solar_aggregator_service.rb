require "redis"
require "json"

# Note: By linking containers using the name redis, we get the following ENV:
#
# REDIS_NAME=/sleepy_galileo/redis
# REDIS_PORT_6379_TCP_ADDR=172.17.0.14
# REDIS_PORT_6379_TCP_PORT=6379
# REDIS_PORT_6379_TCP=tcp://172.17.0.14:6379
# REDIS_PORT=tcp://172.17.0.14:6379

url = ENV['REDIS_PORT']
if url
  url = url.gsub('tcp', 'redis')
  puts "Using Redis on url: #{url}"
  redis_sub = Redis.new(:url=>url)
  redis = Redis.new(:url=>url)
else
  puts "Using Redis on localhost"
  redis_sub = Redis.new(:host => "127.0.0.1", :port => 6379)
  redis = Redis.new(:host => "127.0.0.1", :port => 6379)
end

trap(:INT) { puts "Exiting..."; exit }

begin
  redis_sub.subscribe(:solar_events) do |on|
    on.subscribe do |channel, subscriptions|
      puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
    end

    on.message do |channel, message|
      # puts "##{channel}: #{message}"
      redis_sub.unsubscribe if message == "stop"
      data = redis.zrevrange('solar_service', 0, 99)
      puts "Found #{data.length} records for aggregation"
      # calc the average total charge for the last sample set
      total_charge_values = data.collect { |record| JSON.parse(record)['total_charge'] }
      average_total_charge = total_charge_values.inject(0.0) { |sum, el| sum + el } / total_charge_values.size

      # calc the average watts
      total_watts_values = data.collect { |record| JSON.parse(record)['total_watts'] }
      average_total_watts = total_watts_values.inject(0.0) { |sum, el| sum + el } / total_watts_values.size

      now = Time.now
      parsed = JSON.parse(data[0])
      hostname = parsed['hostname']
      json = { :hostname=>hostname, :timestamp=>now.to_i, :average_total_charge=>average_total_charge, :average_total_watts=>average_total_watts}.to_json
      redis.zadd('solar_service_aggregated', now.to_i, json)
    end

    on.unsubscribe do |channel, subscriptions|
      puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
    end
  end
rescue Redis::BaseConnectionError => error
  puts "#{error}, retrying in 1s"
  sleep 1
  retry
end
