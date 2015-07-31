require 'sinatra'
require 'redis'
require 'json'

set :bind, '0.0.0.0'

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
  @@redis = Redis.new(:url=>url)
else
  puts "Using Redis on localhost"
  @@redis = Redis.new(:host => "127.0.0.1", :port => 6379)
end

before do
  content_type 'application/json'
end

get '/' do
  [200, "Hello"]
end

get '/conditions' do
  json = @@redis.zrevrange('solar_service', 0, 0)
  if json.empty?
    [200, [].to_json]
  else
    [200, json]
  end
end

get '/aggregated' do
  json = @@redis.zrevrange('solar_service_aggregated', 0, 0)
  if json.empty?
    [200, [].to_json]
  else
    [200, json]
  end
end
