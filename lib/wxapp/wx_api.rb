require 'sinatra'
require 'redis'
require 'json'

set :bind, '0.0.0.0'

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
  json = @@redis.zrevrange('wx_service', 0, 0)
  if json.empty?
    [200, [].to_json]
  else
    [200, json]
  end
end
