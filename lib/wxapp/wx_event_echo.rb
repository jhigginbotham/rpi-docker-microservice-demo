require "redis"

url = ENV['REDIS_PORT']
if url
  url = url.gsub('tcp', 'redis')
  puts "Using Redis on url: #{url}"
  redis = Redis.new(:url=>url)
else
  puts "Using Redis on localhost"
  redis = Redis.new(:host => "127.0.0.1", :port => 6379)
end

trap(:INT) { puts "Exiting..."; exit }

begin
  redis.subscribe(:wx_events) do |on|
    on.subscribe do |channel, subscriptions|
      puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
    end

    on.message do |channel, message|
      puts "##{channel}: #{message}"
      redis.unsubscribe if message == "stop"
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
