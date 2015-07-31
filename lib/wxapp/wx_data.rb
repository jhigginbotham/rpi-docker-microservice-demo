require 'socket'
require 'redis'
require 'json'

url = ENV['REDIS_PORT']
if url
  url = url.gsub('tcp', 'redis')
  puts "Using Redis on url: #{url}"
  redis = Redis.new(:url=>url)
else
  puts "Using Redis on localhost"
  redis = Redis.new(:host => "127.0.0.1", :port => 6379)
end

data = redis.zrevrange('wx_service', 0, 9)
data.each do |record|
  puts "#{JSON.parse(record)}"
end
