require 'socket'
require 'redis'
require 'json'

class WxCollector
  DIRECTIONS = ['north', 'east', 'south', 'west']
  def initialize
    @running = true
    @start_time = Time.now
    @current_temp = (70 + Random.rand(5)).to_f + Random.rand(10).to_f * 0.1
    @current_wind_speed = 2 + Random.rand(6)
    @current_wind_direction = DIRECTIONS[Random.rand(4)]

    url = ENV['REDIS_PORT']
    if url
      url = url.gsub('tcp', 'redis')
      puts "Using Redis on url: #{url}"
      @redis = Redis.new(:url=>url)
    else
      puts "Using Redis on localhost"
      @redis = Redis.new(:host => "127.0.0.1", :port => 6379)
    end
  end

  def run
    while (@running)
      data = generate_telemetry
      save_data(data)
      publish_event(data)
      sleep 1
    end
  end

  def generate_telemetry(now=Time.now)
    data = { }
    if now.sec == 0
      @current_temp += ((Random.rand(2)+1).to_f * 0.1).round(1)
    end
    if now.sec % 3 == 0
      @current_wind_speed = 2 + Random.rand(6)
    end
    data[:hostname] = Socket.gethostname
    data[:timestamp] = now.to_i
    data[:temp_fahrenheit] = ('%.1f' % @current_temp).to_f
    data[:wind_speed_mph] = @current_wind_speed
    data[:wind_direction] = @current_wind_direction
    data
  end

  def save_data(data)
      json = data.to_json
      puts "#{json}"
    @redis.zadd('wx_service', data[:timestamp], json)
  end

  def publish_event(data)
      json = data.to_json
    @redis.publish('wx_events', json)
  end
end

service = WxCollector.new
service.run
