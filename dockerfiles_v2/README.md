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

## Persisting VictoriaMetrics Data Across Restarts
By default, VictoriaMetrics does not retain data between container restarts—each time the container starts, it begins with an empty dataset. 
To preserve historical metrics, you need to mount a persistent volume for data storage.

Below is an example of how to do this using a local directory:

```
# Create a directory to store VictoriaMetrics data
mkdir metrics_data

# Run the container with the local directory mounted as the data volume.
# This ensures your metrics history survives container restarts.
docker run --network=host \
  -v ./metrics_data:/victoria-metrics-data \
  -d lucacanali/spark-dashboard:v02
```

## Example of how to build the image:
```
cd dockerfiles_v2
docker build -t spark-dashboard:v02 .
```

