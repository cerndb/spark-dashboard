# Spark Performance Dashboard

This repository provides the tooling and configuration for deploying an Apache Spark Performance Dashboard using containers technology.
The monitoring pipeline is implemented using the [Spark metrics system](https://spark.apache.org/docs/latest/monitoring.html#metrics),
InfluxDB, and Grafana.

**Why:** Troubleshooting Spark jobs and understanding how system resources are used by Spark executors can be complicated.
This type of data is precious for visualizing and understanding root causes of performance issues.
Using the Spark Dashboard you can collect and visualize many of key metrics available by the Spark metrics system
as time series, empowering Spark applications troubleshooting, including straggler and memory usage analyses.

**Compatibility:** Use with Spark 3.x and 2.4. 

**Demos and blogs:**
  - **[Short demo of the Spark dashboard](https://canali.web.cern.ch/docs/Spark_Dashboard_Demo.mp4)**
  - [Blog entry on Spark Dashboard](https://db-blog.web.cern.ch/blog/luca-canali/2019-02-performance-dashboard-apache-spark)
  - Talk at [Data+AI Summit 2021](https://databricks.com/session_na21/monitor-apache-spark-3-on-kubernetes-using-metrics-and-plugins), [slides](http://canali.web.cern.ch/docs/Monitor_Spark3_on_Kubernetes_DataAI2021_LucaCanali.pdf)
  - Notes on [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard)

Main author and contact: Luca.Canali@cern.ch  
Previous contributors: Riccardo Castellotti, Michal Bien.  

Related work: **[sparkMeasure](https://github.com/LucaCanali/sparkMeasure)** a tool for 
performance troubleshooting of Apache Spark workloads

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
## Deploy the Spark Dashboard in 3 Steps

## Step 1/3: Run the Spark dashboard using a container technology

Two different installation options are packaged in this repository, use the one that best suits your environment:

### Option Docker: Deploy the dashboard using Docker
 - Quickstart: `docker run --network=host -d lucacanali/spark-dashboard:v01`
 - Details: [dockerfiles](dockerfiles)

### Option Helm: Deploy the dashboard using Helm
 - Quickstart: `helm install spark-dashboard https://github.com/cerndb/spark-dashboard/raw/master/charts/spark-dashboard-0.3.0.tgz`
 - Details: [charts](charts)


## Step 2/3: Spark configuration parameters

You will need to set a few Spark configuration parameters to hook the Spark metrics system instrumentation
to the dashboard.
In particular, you need to point Spark to the InfluxDB instance (via a Graphite endpoint set up on InfluxDB 1.x).  

```
# InfluxDB endpoint, as started using the docker container
INFLUXDB_ENDPOINT=`hostname`

# For helm deployments use this instead
#INFLUXDB_ENDPOINT=spark-dashboard-influx.default.svc.cluster.local

bin/spark-shell (or spark-submit or pyspark) ...addtitional options...

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

Note: You can also set the configuration using the `metrics.properties` file in `SPARK_CONF_DIR`  
Example `metrics.properties` file:
  ```
  *.sink.graphite.host=localhost
  *.sink.graphite.port=2003
  *.sink.graphite.period=10
  *.sink.graphite.unit=seconds
  *.sink.graphite.prefix=lucatest
  *.source.jvm.class=org.apache.spark.metrics.source.JvmSource
  ```


## Step 3/3: Visualize the metrics using a Grafana dashboard

### Option Docker:
 - The Grafana dashboard should be reachable at port 3000 of your machine/VM where you started the container
 - Point your browser to `http://hostname:3000` (edit `hostname` as relevant)
 - Credentials: use the default for the first login (user: admin, password: admin)

### Option Helm:
 - The Grafana dashboard is reachable at port 3000 of the spark-dashboard-service.  
   See service details: `kubectl get service spark-dashboard-grafana`  
   When using NodePort and an internal cluster IP address, this is how you can port forward to the service from
   the local machine: `kubectl port-forward service/spark-dashboard-grafana 3000:3000`

### Examples:
- See some [examples of the graphs available in the dashboard at this link](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard#example-graphs)

### Notes:
- At the first logon to the Grafana dashboard use user "admin", with password admin (you can change that after logon)
- Choose one of the provided dashboards (for example start with **Spark_Perf_Dashboard_v04**) and select the user,
  applicationId and time range.
- You will need a running Spark application configured to use the dashboard to be able to select and application
  and display the metrics.

---
## Advanced configurations and notes

### Graph annotations: display query/job/stage start and end times  
Optionally, you can add annotation instrumentation to the performance dashboard.
Annotations provide additional info on start and end times for queries, jobs and stages.
To activate annotations, add the following additional configuration, needed for collecting and writing extra performance data:
```
INFLUXDB_HTTP_ENDPOINT="http://`hostname`:8086"
--packages ch.cern.sparkmeasure:spark-measure_2.12:0.22 \
--conf spark.sparkmeasure.influxdbURL=$INFLUXDB_HTTP_ENDPOINT \
--conf spark.extraListeners=ch.cern.sparkmeasure.InfluxDBSink \
```

### Notes
- More details on how this works and alternative configurations at [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard)
- The dashboard can be used when running Spark on a cluster (Kubernetes, YARN, Standalone, Mesos) or in local mode.
  When using Spark in local mode, please use Spark version 3.1 or higher, see [SPARK-31711](https://issues.apache.org/jira/browse/SPARK-31711)
- The configuration in the example below is done using `spark.metrics.conf...` parameters, as an alternative
  you can choose to configure the metrics system using the configuration file `$SPARK_HOME/conf/metrics.properties file`

### Docker
- InfluxDB will use port 2003 (graphite endpoint), and port 8086 (http endpoint) of
  your machine/VM (when running using `--network=host`).
- Note: the endpoints need to be available on the node where you started the Docker container and
  reachable by Spark executors and driver (mind the firewall).

### Helm
- Find the InfluxDB endpoint IP with `kubectl get service spark-dashboard-influx`.
  Optionally resolve the dns name with `nslookup` of such IP.
  For example, the InfluxDB service host name of a test installation is: `spark-dashboard-influx.default.svc.cluster.local`

### Customizing and adding new dashboards 

The provided example dashboards are examples based on the authors' usage. Only a subset of the metrics values logged into 
InfluxDB are visualized in the provided dashboard.
For a full list of the available metrics see the
[documentation of Spark metrics system](https://github.com/apache/spark/blob/master/docs/monitoring.md#metrics).
New dashboards can be added by putting them in the relevant `grafana_dashboards` folder and re-building the container image
(or  re-packaging the helm chart).
On Helm: running helm-update is enough to upload it as ConfigMap and make it available to Grafana. 
Automatically persisting manual edits is not supported at this time.
