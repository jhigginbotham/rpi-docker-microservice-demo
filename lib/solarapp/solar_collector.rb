require 'socket'
require 'redis'
require 'json'

class SolarCollector
  def initialize
    @running = true
    @start_time = Time.now
    @current_batt_temp = (70 + Random.rand(5)).to_f + Random.rand(10).to_f * 0.1
    @current_total_charge = 70 + Random.rand(30) + Random.rand(10).to_f * 0.1
    @current_total_watts = 200 + Random.rand(30) + Random.rand(10).to_f * 0.1
    @current_operating_time_hours = 100 + Random.rand(30) + Random.rand(10).to_f * 0.1

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
      @current_batt_temp += ((Random.rand(2)+1) * 0.1).round(1)
    @current_batt_temp.round(1)
      @current_operating_time_hours += 0.1
    end
    if now.sec % 3 == 0
      @current_total_charge = 70 + Random.rand(30)
      @current_total_watts = 200 + Random.rand(30)
    end
    data[:hostname] = Socket.gethostname
    data[:timestamp] = now.to_i
    data[:batt_temp_fahrenheit] = ('%.1f' % @current_batt_temp).to_f
    data[:total_charge] = @current_total_charge
    data[:total_watts] = @current_total_watts
    data[:operating_time_hours] = ('%.1f' % @current_operating_time_hours).to_f
    data
  end

  def save_data(data)
    json = data.to_json
    puts "#{json}"
    @redis.zadd('solar_service', data[:timestamp], json)
  end

  def publish_event(data)
    json = data.to_json
    @redis.publish('solar_events', json)
  end
end

service = SolarCollector.new
service.run
