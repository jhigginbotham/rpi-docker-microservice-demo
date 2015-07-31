# Introduction

This is a simple application that demostrates how to deploy microservices on the Raspberry Pi 2 using Docker.

The demonstration was part of a talk I gave at Gluecon 2015. View the slidedeck here: http://www.slideshare.net/launchany/microservices-on-the-edge

The application has a dashboard that displays data obtained via a simple JSON-based web API. Collector services simulate readings from actual hardware, store the data into Redis, then publish event messages for other services to process. All code is built to run as Ruby 2.x using Sinatra to be as tiny as possible. Each service is deployed to a separate container. 

Note: The following steps can be replaced by Docker compose, assuming it is installed on your rpi. I tried to make this process easy but manual so that the magic doen't hide valuable learning, and to ensure that all containers are started in the proper order. Redis takes the longest to start and can cause service containers to fail if it hasn't started fully yet. 

# Raspberry Pi preparation

Download and install the Hypriot rpi image with Docker pre-installed: http://blog.hypriot.com/downloads/

# Building a new Docker image with pre-installed Rubygems:

The following instructions will prepare a reusable container image with the necessary Ruby gems:

1. docker run -t -i hypriot/rpi-ruby /bin/bash

2. Make gem installation go faster by not generating documentation for the gems:

echo "gem: --no-document" > ~/.gemrc

3. Install gems:

gem install redis
gem install sinatra
gem install erubis
gem install faraday
exit

4. Create a new docker image with the gems preinstalled, to save time as we launch new containers for the demo:

sudo docker commit -m "Pre-install gems" <container instance ID> launchany/rpi-docker-microservice-demo

5. Verify everything looks good:

docker run -t -i launchany/rpi-docker-microservice-demo gem list

(should see the list of gems installed above)

6. On the docker host, clone the git repo for this demo:

Note: After you SSH to your rpi host as the pi user, you will be in /home/pi. We'll share this out as /services so that each container doesn't have to fetch the repo itself.

git clone git@github.com:jhigginbotham/rpi-docker-microservice-demo.git

# Running the demo (first time)

1. Start Redis container with the name 'redis' (used for container linking, below), exporting port 6379 to the container's host

docker run -d --name redis -p 6379:6379 hypriot/rpi-redis

2. Start the WX Collector Service:

docker  run -d --name wx_collector -v /home/pi/rpi-docker-microservice-demo:/services --link redis:redis launchany/rpi-docker-microservice-demo ruby /services/lib/wxapp/wx_collector.rb

a. Mounts the local source tree on the Pi to /services within the container
b. Also links the Redis container as 'redis', exposing the URL with port as environment variables that our code can reference

3. Start the Solar Collector Service:

docker run -d --name solar_collector -v /home/pi/rpi-docker-microservice-demo:/services --link redis:redis launchany/rpi-docker-microservice-demo ruby /services/lib/solarapp/solar_collector.rb

4. Start the Solar Aggregator Service:

docker run -d --name solar_aggregator -it -v /home/pi/rpi-docker-microservice-demo:/services --link redis:redis launchany/rpi-docker-microservice-demo ruby /services/lib/solarapp/solar_aggregator_service.rb

5. Start the WX API Service:

docker run -d --name wx_api -p 4567:4567 -it -v /home/pi/rpi-docker-microservice-demo:/services --link redis:redis launchany/rpi-docker-microservice-demo ruby /services/lib/wxapp/wx_api.rb

6. Start the Solar API Service:

docker run -d --name solar_api -p 4568:4567 -it -v /home/pi/rpi-docker-microservice-demo:/services --link redis:redis launchany/rpi-docker-microservice-demo ruby /services/lib/solarapp/solar_api.rb

7. Start the Dashboard App:

docker run --name dashboard -p 8080:4567 -it -v /home/pi/rpi-docker-microservice-demo:/services --link wx_api:wx_api --link solar_api:solar_api launchany/rpi-docker-microservice-demo ruby /services/lib/dash/dashboard_app.rb

docker run -d --name dashboard -p 8080:4567 -v /home/pi/rpi-docker-microservice-demo:/services --link wx_api:wx_api --link solar_api:solar_api launchany/rpi-docker-microservice-demo ruby /services/lib/dash/dashboard_app.rb

8. Browse to the dashboard, on port 8080 of your rpi host. Refresh to see the values change as the services simulate new readings. 

# Running the Demo (containers already exist)

docker start redis

docker start wx_api
docker start solar_api
docker start dashboard

docker start wx_collector
docker start solar_collector

docker start solar_aggregator

# Stop the running services

docker stop dashboard wx_api solar_api  solar_aggregator wx_collector solar_collector redis
