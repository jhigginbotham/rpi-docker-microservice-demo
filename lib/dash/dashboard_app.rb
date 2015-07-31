require 'sinatra'
require 'net/http'
require 'json'

set :bind, '0.0.0.0'

set :views, settings.root + '/templates'

set :public_folder, Proc.new { File.join(root, "static") }

url = ENV['WX_API_PORT']
if url
  url = url.gsub('tcp', 'http')
  puts "Using WX Service on url: #{url}"
  @@wx_url = url
else
  puts "Using WX Service on localhost:4567"
  @@wx_url = 'http://127.0.0.1:4567'
end

url = ENV['SOLAR_API_PORT']
if url
  url = url.gsub('tcp', 'http')
  puts "Using SOLAR Service on url: #{url}"
  @@solar_url = url
else
  puts "Using SOLAR Service on localhost:4568"
  @@solar_url = 'http://127.0.0.1:4568'
end

get '/' do
  uri = URI(@@wx_url)
  res = Net::HTTP.get_response(uri+'/conditions')
  wx_latest = JSON.parse(res.body)
  puts "wx_latest=#{wx_latest.inspect}"

  uri = URI(@@solar_url)
  res = Net::HTTP.get_response(uri+'/conditions')
  solar_latest = JSON.parse(res.body)
  puts "solar_latest=#{solar_latest.inspect}"

  res = Net::HTTP.get_response(uri+'/aggregated')
  solar_aggregated = JSON.parse(res.body)
  puts "solar_aggregated=#{solar_aggregated.inspect}"

  erb :dashboard, :locals=>{ :wx_latest=>wx_latest, :solar_latest=>solar_latest, :solar_aggregated=>solar_aggregated}
end
