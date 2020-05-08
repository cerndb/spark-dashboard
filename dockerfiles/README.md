# How to build and run the docker container

How to run the dashboard contained using the image on [Dockerhub](https://hub.docker.com/r/lucacanali/spark-dashboard):
- this example uses `network=host`. As a result Grafana and InfluxDB started in the container will be 
  using the local host machine's network.   Note that this will use ports 3000, 2003 and 8086 on the host.
```
docker run --network=host -d lucacanali/spark-dashboard:v01
```

How to build the image locally:
```
docker build -t spark-dashboard:v01 .
```

Additional deployment examples:
- This shows an example of how to use a volume to store InfluxDB data. 
  It allows preserving the history across runs when the container is restarted,
  otherwise InfluxDB starts from scratch each time.
```
docker run --network=host -v MYPATH/myinfluxdir:/var/lib/influxdb -d lucacanali/spark-dashboard:v01
```
