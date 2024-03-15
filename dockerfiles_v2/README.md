# How to build and run the Spark dashboard in a container image

## How to run
Run the dashboard using a container image from [Dockerhub](https://hub.docker.com/r/lucacanali/spark-dashboard):
- There are a few ports needed and multiple options on how to expose them
- Port 2003 is for Graphite ingestion, port 3000 is for Grafana, port 8428 is used internally by VictoriaMetrics source
- You can expose the ports from the container individually or just make `network=host`.
- Examples:
```
docker run --network=host -d lucacanali/spark-dashboard
or
docker run -p 3000:3000 -p 2003:2003 -d lucacanali/spark-dashboard
or
docker run -p 3000:3000 -p 2003:2003 -p 8428:8428 -d lucacanali/spark-dashboard
```

## Advanced: persist InfluxDB data across restarts
- This shows an example of how to use a volume to store data on VictoriaMetrics. 
  It allows preserving the history across runs when the container is restarted,
  otherwise InfluxDB starts from scratch each time.
```
mkdir metrics_data
docker run --network=host -v ./metrics_data:/victoria-metrics-data -d lucacanali/spark-dashboard:v02
```

## Example of how to build the image:
```
cd dockerfiles_v2
docker build -t spark-dashboard:v02 .
```

