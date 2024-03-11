# Apache Spark Performance Dashboard and Spark Monitoring

This repository provides the tooling and configuration for deploying an Apache Spark Performance Dashboard using containers technology.  
This provides monitoring for Apache Spark workloads.  
The monitoring pipeline and dashboard are implemented from the [Spark metrics system](https://spark.apache.org/docs/latest/monitoring.html#metrics) using InfluxDB, and Grafana.

**Why:** Troubleshooting Spark jobs and understanding how system resources are used by Spark executors can be complicated.
This type of data is precious for visualizing and understanding root causes of performance issues.
Using the Spark Dashboard you can collect and visualize many of key metrics available by the Spark metrics system
as time series. This provides monitoring and help for Spark applications troubleshooting. 

**Compatibility:** 
- Use with Spark 3.x and 2.4.
- The provided containers are for the Linux platform

**Demos and blogs:**
  - **[Short demo of the Spark dashboard](https://canali.web.cern.ch/docs/Spark_Dashboard_Demo.mp4)**
  - [Blog entry on Spark Dashboard](https://db-blog.web.cern.ch/blog/luca-canali/2019-02-performance-dashboard-apache-spark)
  - Talk on Spark performance at [Data+AI Summit 2021](https://databricks.com/session_na21/monitor-apache-spark-3-on-kubernetes-using-metrics-and-plugins), [slides](http://canali.web.cern.ch/docs/Monitor_Spark3_on_Kubernetes_DataAI2021_LucaCanali.pdf)
  - Notes on [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard)

**Related work:** 
- **[sparkMeasure](https://github.com/LucaCanali/sparkMeasure)** a tool for performance troubleshooting of Apache Spark workloads
- **[TPCDS_PySpark](https://github.com/LucaCanali/Miscellaneous/tree/master/Performance_Testing/TPCDS_PySpark)** a TPC-DS workload generator written in Python and designed to run at scale using Apache Spark

Main author and contact: Luca.Canali@cern.ch  

---
### Architecture
The Spark Dashboard collects and displays Apache Spark workload metrics produced by
the [Spark metrics system](https://spark.apache.org/docs/latest/monitoring.html#metrics).
Spark metrics are exported via a Graphite endpoint and stored in InfluxDB.
Metrics are then queried from InfluxDB and displayed using a set of pre-configured Grafana dashboards distributed with this repo.   
Note that the provided installation instructions and code are intended as examples for testing and experimenting.
Hardening the installation will be necessary for production-quality use.

![Spark metrics dashboard architecture](https://raw.githubusercontent.com/LucaCanali/Miscellaneous/master/Spark_Dashboard/images/Spark_metrics_dashboard_arch.PNG "Spark metrics dashboard architecture")

---
## How To Deploy the Spark Dashboard 

This provides a quickstart guide to deploy the Spark Dashboard. Two methods are provided: one using a Docker container 
and the other is deploying on Kubernetes via Helm.

### How to run the Spark dashboard on a Docker container
If you chose to run on container image, these are steps:

**1. Start the container**
The provided container image has been built configured to run InfluxDB and Grafana
  -`docker run -p 3000:3000 -p 2003:2003 -d lucacanali/spark-dashboard` 
 - Note: port 2003 is for Graphite ingestion, port 3000 is for Grafana
 - More options, including on how to persist InfluxDB data across restarts at: [Spark dashboard in a container](dockerfiles)

**2. Spark configuration**
You need to configure Spark to send the metrics to the desired Graphite endpoint + the add the related configuration.
You can do this by editing the file `metrics.properties` located in `$SPARK_CONF_DIR` as follows:  
  ```
  # Add this to metrics.properties 
  *.sink.graphite.host=localhost
  *.sink.graphite.port=2003
  *.sink.graphite.period=10
  *.sink.graphite.unit=seconds
  *.sink.graphite.prefix=lucatest
  *.source.jvm.class=org.apache.spark.metrics.source.JvmSource
  ```

Additional configuration, that you should pass as command line options (or add to spark-defaults.conf): 
```
--conf spark.metrics.staticSources.enabled=true
--conf spark.metrics.appStatusSource.enabled=true
```

Instead of using metrics.properties, you may prefer to use Spark configuration options directly.
It's a matter of convenience and depends on your use case. This is an example of how to do it:  
```
# InfluxDB endpoint, point to the host where the InfluxDB container is running
INFLUXDB_ENDPOINT=`hostname`

bin/spark-shell (or spark-submit or pyspark)
--conf "spark.metrics.conf.*.sink.graphite.class"="org.apache.spark.metrics.sink.GraphiteSink" \
--conf "spark.metrics.conf.*.sink.graphite.host"=$INFLUXDB_ENDPOINT \
--conf "spark.metrics.conf.*.sink.graphite.port"=2003 \
--conf "spark.metrics.conf.*.sink.graphite.period"=10 \
--conf "spark.metrics.conf.*.sink.graphite.unit"=seconds \
--conf "spark.metrics.conf.*.sink.graphite.prefix"="lucatest" \
--conf "spark.metrics.conf.*.source.jvm.class"="org.apache.spark.metrics.source.JvmSource" \
--conf "spark.metrics.staticSources.enabled"=true \
--conf "spark.metrics.appStatusSource.enabled"=true
```

**3. Visualize the metrics using a Grafana dashboard**
  - Point your browser to `http://hostname:3000` (edit `hostname` as relevant)
  - Credentials: use the default for the first login (user: admin, password: admin)
  - Choose one of the provided dashboards (for example start with **Spark_Perf_Dashboard_v04**) and select the user,
    applicationId and time range.
    - You will need a running Spark application configured to use the dashboard to be able to select an application
    and display the metrics. 
    - See also [TPCDS_PySpark](https://github.com/LucaCanali/Miscellaneous/tree/master/Performance_Testing/TPCDS_PySpark)
    a TPC-DS workload generator written in Python and designed to run at scale using Apache Spark.

### Examples:
- See some [examples of the graphs available in the dashboard at this link](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard#example-graphs)

---
### How to run the dashboard on Kubernetes using Helm
If you chose to run on Kubernetes, these are steps:

1. The Helm chart takes care of configuring and running InfluxDB and Grafana:
   - Quickstart: `helm install spark-dashboard https://github.com/cerndb/spark-dashboard/raw/master/charts/spark-dashboard-0.3.0.tgz`
   - Details: [charts](charts)
  
2. Spark configuration:
   - Configure `metrics.properties` as detailed above.
   - Use `INFLUXDB_ENDPOINT=spark-dashboard-influx.default.svc.cluster.local` as the InfluxDB endpoint in 
     the Spark configuration.

3. Grafana visualization with Helm:
   - The Grafana dashboard is reachable at port 3000 of the spark-dashboard-service.  
   - See service details: `kubectl get service spark-dashboard-grafana`  
   - When using NodePort and an internal cluster IP address, this is how you can port forward to the service from
     the local machine: `kubectl port-forward service/spark-dashboard-grafana 3000:3000`

More info at [Spark dashboard on Kubernetes](charts/README.md)

---
## Advanced configurations and notes

### Graph annotations: display query/job/stage start and end times  
Optionally, you can add annotation instrumentation to the performance dashboard.
Annotations provide additional info on start and end times for queries, jobs and stages.
To activate annotations, add the following additional configuration, needed for collecting and writing 
extra performance data:
```
INFLUXDB_HTTP_ENDPOINT="http://`hostname`:8086"
--packages ch.cern.sparkmeasure:spark-measure_2.12:0.24 \
--conf spark.sparkmeasure.influxdbURL=$INFLUXDB_HTTP_ENDPOINT \
--conf spark.extraListeners=ch.cern.sparkmeasure.InfluxDBSink \
```

### Notes
- More details on how this works and alternative configurations at [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard)
- The dashboard can be used when running Spark on a cluster (Kubernetes, YARN, Standalone) or in local mode.  
- When using Spark in local mode, it's best with Spark version 3.1 or higher, see [SPARK-31711](https://issues.apache.org/jira/browse/SPARK-31711)

### Docker
- InfluxDB will use port 2003 (graphite endpoint), and port 8086 (http endpoint) of
  your machine/VM (when running using `--network=host`).
- Note: the endpoints need to be available on the node where you started the Docker container and
  reachable by Spark executors and driver (mind the firewall).

### Helm
- Find the InfluxDB endpoint IP with `kubectl get service spark-dashboard-influx`.
- Optionally, resolve the DNS name with `nslookup` of such IP.
  For example, the InfluxDB service host name of a test installation is: `spark-dashboard-influx.default.svc.cluster.local`

### Customizing and adding new dashboards 

- This implementation comes with some example dashboards based on the authors' use. Note that only a subset of the
metrics values logged into InfluxDB are visualized in the provided dashboard.
- For a full list of the available metrics see the [documentation of Spark metrics system](https://github.com/apache/spark/blob/master/docs/monitoring.md#metrics).
- New dashboards can be added by putting them in the relevant `grafana_dashboards` folder and re-building the container image
(or  re-packaging the helm chart).
- On Helm: running helm-update is enough to upload it as ConfigMap and make it available to Grafana. 
- Automatically persisting manual edits is not supported at this time.
