# Spark-Dashboard
Real-Time Spark Monitoring & Optimization

[![DOI](https://zenodo.org/badge/212368829.svg)](https://doi.org/10.5281/zenodo.14718682)
[![Docker Pulls](https://img.shields.io/docker/pulls/lucacanali/spark-dashboard)](https://hub.docker.com/r/lucacanali/spark-dashboard)

**Spark-Dashboard** is an intuitive and comprehensive tool designed to help you optimize and monitor your Apache Spark clusters with ease. 
By delivering real-time insights into critical performance metrics—including CPU usage, active sessions, task throughput,
memory utilization, HDFS usage, and more—this dashboard empowers you to quickly identify and resolve performance bottlenecks,
ensuring your Spark applications run smoothly.

## Key Features

- **Real-Time Visualization:**  
  Leverage Grafana dashboards to visualize Spark metrics dynamically, allowing for prompt performance analysis.

- **Performance Troubleshooting:**  
  Quickly pinpoint and address performance issues in your Spark applications with comprehensive metric tracking.

- **Broad Compatibility:**  
  Designed to support all current Apache Spark versions (2.4 and higher) and all supported clusters (Hadoop, Kubernetes, stand-alone)
- ensuring wide-ranging applicability.
  
### Contents
- [Architecture](#architecture)
- [How To Deploy the Spark Dashboard V2](#how-to-deploy-the-spark-dashboard)
  - [How to run the Spark Dashboard V2 on a container](#how-to-run-the-spark-dashboard-v2-on-a-container)
  - [Extended Spark dashboard](#extended-spark-dashboard)
- [Notes on Running Spark Dashboard on Spark Connect](#notes-on-running-spark-dashboard-on-spark-connect) 
- [Examples and getting started with Spark Performance dashboards](#examples-and-getting-started-with-spark-performance-dashboards) 
  - [Start small, testing with Spark in local mode](#start-small-testing-with-spark-in-local-mode)
  - [Measuring with Spark Dashboard while running TPCDS on a Spark cluster](#running-tpcds-on-a-spark-cluster)
- [Old implementation (V1)](#old-implementation-v1)
  - [How to run the Spark dashboard V1 on a container](#how-to-run-the-spark-dashboard-v1-on-a-container)
  - [How to run the dashboard V1 on Kubernetes using Helm](#how-to-run-the-dashboard-v1-on-kubernetes-using-helm)
- [Advanced configurations and notes](#advanced-configurations-and-notes)

### Resources
- [![Watch the video](https://www.youtube.com/s/desktop/050e6796/img/favicon_32x32.png) Watch Spark-Dashboard demo and tutorial](https://www.youtube.com/watch?v=sLjAyDwpg80)
- Notes on [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard)
- Blog on [building an Apache Spark Performance Lab](https://db-blog.web.cern.ch/node/195)
- Blog [on Spark Dashboard](https://db-blog.web.cern.ch/blog/luca-canali/2019-02-performance-dashboard-apache-spark)
- Talk on Spark performance at [Data+AI Summit 2021](https://databricks.com/session_na21/monitor-apache-spark-3-on-kubernetes-using-metrics-and-plugins), [slides](http://canali.web.cern.ch/docs/Monitor_Spark3_on_Kubernetes_DataAI2021_LucaCanali.pdf)
- [sparkMeasure](https://github.com/LucaCanali/sparkMeasure) a tool for performance troubleshooting of Apache Spark workloads
- [TPCDS_PySpark](https://github.com/LucaCanali/Miscellaneous/tree/master/Performance_Testing/TPCDS_PySpark) a TPC-DS workload generator written in Python and designed to run at scale using Apache Spark

Main author and contact: Luca.Canali@cern.ch  

---
### Architecture

![Spark metrics dashboard architecture](https://raw.githubusercontent.com/LucaCanali/Miscellaneous/master/Spark_Dashboard/images/Spark_MetricsSystem_Grafana_Dashboard_V2.0.png "Spark metrics dashboard architecture")

This diagram illustrates an end-to-end monitoring pipeline for Apache Spark built entirely on open-source components. 
The architecture is designed to deliver real-time insights into the performance and health of your Spark clusters through
a seamless flow of data from metric generation to visualization.

- **Apache Spark Metrics:**  
  Apache Spark generates detailed performance metrics via its [metrics system](https://spark.apache.org/docs/latest/monitoring.html#metrics).
  Both the driver and executors emit a wide range of metrics—such as runtime, CPU usage, garbage collection (GC) time, memory utilization, shuffle statistics, and I/O metrics—in Graphite format.

- **Telegraf:**  
  Acting as the collection agent, Telegraf ingests the metrics emitted by Spark. It enriches these measurements with additional
  labels and tags to facilitate effective organization and analysis before forwarding them to the storage backend.

- **VictoriaMetrics:**  
  This robust time-series database efficiently stores the labeled metrics data. Its design is optimized for handling large volumes
  of timestamped, sequential data, making it ideal for monitoring and historical trend analysis.

- **Grafana:**  
  Grafana provides a dynamic visualization layer, querying VictoriaMetrics using PromQL/MetricsQL. The result is a set of interactive
  dashboards that display real-time metrics and trends, empowering users to monitor system performance and swiftly identify any bottlenecks.

Together, these components form a cohesive and scalable monitoring solution tailored for Apache Spark environments.

---
## How To Deploy the Spark Dashboard 

This quickstart guide presents multiple methods for deploying Spark Dashboard. The **recommended** approach is to deploy 
Spark-Dashboard v2 using a container.

### How to run the Spark Dashboard V2 on a container
Follow these steps to get started with the container image:

#### 1. Start the container
The provided container image is pre-configured to run VictoriaMetrics (for metrics storage) and Grafana (for visualization). 
You can start the container using either Docker or Podman:

- **Using Docker:**

  `docker run -p 3000:3000 -p 2003:2003 -d lucacanali/spark-dashboard`

- **Using Podman:**

  `podman run -p 3000:3000 -p 2003:2003 -d lucacanali/spark-dashboard`

#### 2. Configure Apache Spark

To send metrics from Spark to the dashboard, configure Spark to export its metrics to the Graphite endpoint provided by the container.

**Method A: Using `metrics.properties`**

Edit the `metrics.properties` file located in `$SPARK_CONF_DIR` and add the following configuration:

    # Configure Graphite sink for Spark metrics
    *.sink.graphite.host=localhost
    *.sink.graphite.port=2003
    *.sink.graphite.period=10
    *.sink.graphite.unit=seconds
    *.sink.graphite.prefix=lucatest

    # Enable JVM metrics collection
    *.source.jvm.class=org.apache.spark.metrics.source.JvmSource

Optionally, add these settings to your Spark launch configuration (or `spark-defaults.conf`):

    --conf spark.metrics.staticSources.enabled=true
    --conf spark.metrics.appStatusSource.enabled=true

**Method B: Passing Configuration via Command-Line**

Alternatively, you can specify Spark metrics settings directly when launching your Spark application. For example:

    # Define the VictoriaMetrics Graphite endpoint (replace `hostname` with your actual host if needed)
    VICTORIAMETRICS_ENDPOINT=$(hostname)

    bin/spark-shell \
      --conf "spark.metrics.conf.*.sink.graphite.class=org.apache.spark.metrics.sink.GraphiteSink" \
      --conf "spark.metrics.conf.*.sink.graphite.host=${VICTORIAMETRICS_ENDPOINT}" \
      --conf "spark.metrics.conf.*.sink.graphite.port=2003" \
      --conf "spark.metrics.conf.*.sink.graphite.period=10" \
      --conf "spark.metrics.conf.*.sink.graphite.unit=seconds" \
      --conf "spark.metrics.conf.*.sink.graphite.prefix=lucatest" \
      --conf "spark.metrics.conf.*.source.jvm.class=org.apache.spark.metrics.source.JvmSource" \
      --conf "spark.metrics.staticSources.enabled=true" \
      --conf "spark.metrics.appStatusSource.enabled=true"

*Optional:* To also collect and display "Tree Process Memory Details", add:

    --conf spark.executor.processTreeMetrics.enabled=true

#### 3. Visualize Metrics in Grafana

Once the container is running and Spark is configured to export metrics, you can view the performance data through Grafana:

- **Access Grafana:**  
  Open your web browser and navigate to [http://localhost:3000](http://localhost:3000) (replace `localhost` with your server's address if necessary).

- **Login Credentials:**  
  Use the default credentials:  
  **User:** `admin`  
  **Password:** `admin`

- **Dashboard Overview:**  
  The bundled dashboard (**Spark_Perf_Dashboard_v04_promQL**) displays a summary of key metrics (such as runtime, CPU usage, I/O, shuffle, task counts, etc.) along with detailed timeseries graphs. Select the appropriate username, application ID, and time range (default is the last 5 minutes) to customize your view.

> **Important:**  
> Ensure that you have a running Spark application configured as detailed above so that metrics are available for selection and display.

For testing purposes, you can simulate load on Spark using [TPCDS_PySpark](https://github.com/LucaCanali/Miscellaneous/tree/master/Performance_Testing/TPCDS_PySpark), a TPC-DS workload generator written in Python and designed to run at scale with Apache Spark.

---
### Extended Spark Dashboard

Enhance your monitoring capabilities with the Extended Spark Dashboard, which collects and visualizes OS and storage metrics alongside standard Spark performance data. This enhanced pipeline leverages [Spark Plugins](https://github.com/cerndb/SparkPlugins) to gather additional metrics, all stored within the same VictoriaMetrics database as the standard Spark metrics.

#### Additional Dashboard Features

The extended dashboard introduces three extra groups of graphs beyond those available in the standard Spark Dashboard:

- **CGroup Metrics**  
  Collects data via CGroup instrumentation—ideal for Spark running on Kubernetes.

- **Cloud Storage**  
  Displays metrics from block storage systems such as S3A, GZ, WASB, and other cloud storage services.

- **HDFS Advanced Statistics**  
  Provides deeper insights into HDFS usage, offering additional performance metrics when Spark leverages HDFS.

#### Configuration

To enable extended metrics, add the following configurations to your Spark setup:

    --conf ch.cern.sparkmeasure:spark-plugins_2.12:0.3
    --conf spark.plugins=ch.cern.HDFSMetrics,ch.cern.CgroupMetrics,ch.cern.CloudFSMetrics

#### Using the Extended Dashboard

After configuring Spark, select the extended dashboard in Grafana to view the additional metrics:

- **Dashboard Name:** `Spark_Perf_Dashboard_v04_PromQL_with_SparkPlugins`
- The dashboard includes extra graphs for OS and storage metrics, offering a comprehensive view of your system's performance.

----
### Notes on Running Spark Dashboard on Spark Connect
Spark Connect allows you to run a thin Spark client connected to a Spark cluster. In that environment, Spark Dashboard needs to be run when starting Spark Connect.
1. Start the Spark Dashboard container (as detailed above).
2. Edit the `metrics.properties` file in the Spark Connect `conf` directory (as detailed above).
3. Start Spark Connect with the command:
   `sbin/start-connect-server.sh`  
   You will find that the metrics are sent to the Spark Dashboard container and visualized in Grafana

-----
## Examples and getting started with Spark Performance dashboards:
- See some [examples of the dashboard graphs at this link](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard#example-graphs)

### Start small, testing with Spark in local mode
- You can use the [TPCDS_PySpark](https://github.com/LucaCanali/Miscellaneous/tree/master/Performance_Testing/TPCDS_PySpark) package to generate a TPC-DS workload and test the dashboard.
- Run the following on local resources or cloud, for example use GitHub Codespaces from this repo
  - [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/cerndb/spark-dashboard)
```
# Install the tool and dependencies
pip install pyspark 
pip install sparkmeasure 
pip install tpcds_pyspark 

# Download the test data
wget https://sparkdltrigger.web.cern.ch/sparkdltrigger/TPCDS/tpcds_10.zip
unzip -q tpcds_10.zip

# 1. Run the tool for a minimal test
tpcds_pyspark_run.py -d tpcds_10 -n 1 -r 1 --queries q1,q2

# 2. Start the dashboard and visualize the metrics (use docker or podman)
docker run -p 2003:2003 -p 3000:3000 -d lucacanali/spark-dashboard

# 3. run the tpcds workload sending metrics to the dashboard
TPCDS_PYSPARK=`which tpcds_pyspark_run.py`
spark-submit --master local[*] \
--conf "spark.metrics.conf.*.sink.graphite.class"="org.apache.spark.metrics.sink.GraphiteSink" \
--conf "spark.metrics.conf.*.sink.graphite.host"="localhost" \
--conf "spark.metrics.conf.*.sink.graphite.port"=2003 \
--conf "spark.metrics.conf.*.sink.graphite.period"=10 \
--conf "spark.metrics.conf.*.sink.graphite.unit"=seconds \
--conf "spark.metrics.conf.*.sink.graphite.prefix"="lucatest" \
--conf "spark.metrics.conf.*.source.jvm.class"="org.apache.spark.metrics.source.JvmSource" \
--conf "spark.metrics.staticSources.enabled"=true \
--conf "spark.metrics.appStatusSource.enabled"=true \
--conf spark.driver.memory=4g \
--conf spark.log.level=error \
--packages ch.cern.sparkmeasure:spark-measure_2.12:0.24 \
$TPCDS_PYSPARK -d tpcds_10

# 4. Accessing the Grafana Dashboard:
#    - Navigate to https://localhost:3000 to access the Grafana dashboard.
#    - If using GitHub Codespaces, use the "Ports" tab to open a browser window for this address.
#    - Default credentials for Grafana are username: admin and password: admin.
#    - Optionally, open the Spark WebUI at http://localhost:4040 to monitor the Spark job.

# Wait a few minutes for metrics to populate the dashboard.
# Note: This dashboard is more effective when Spark runs on cluster resources
#       rather than in the local mode demonstrated here. For more details, refer to the next paragraph.
```


### Running TPCDS on a Spark cluster
- Example of running TPCDS on a YARN Spark cluster, monitor with the Spark dashboard:
```
TPCDS_PYSPARK=`which tpcds_pyspark_run.py`

spark-submit --master yarn --conf spark.log.level=error --conf spark.executor.cores=8 --conf spark.executor.memory=64g \
--conf spark.driver.memory=16g --conf spark.driver.extraClassPath=tpcds_pyspark/spark-measure_2.12-0.24.jar \
--conf spark.dynamicAllocation.enabled=false --conf spark.executor.instances=32 --conf spark.sql.shuffle.partitions=512 \
$TPCDS_PYSPARK -d hdfs://<PATH>/tpcds_10000_parquet_1.13.1
```

- Example of running TPCDS on a Kubernetes cluster with S3 storage, monitor this with the extended dashboard using Spark plugins:
```
TPCDS_PYSPARK=`which tpcds_pyspark_run.py`

spark-submit --master k8s://https://xxx.xxx.xxx.xxx:6443 --conf spark.kubernetes.container.image=<URL>/spark:v3.5.1 --conf spark.kubernetes.namespace=xxx \
--conf spark.eventLog.enabled=false --conf spark.task.maxDirectResultSize=2000000000 --conf spark.shuffle.service.enabled=false --conf spark.executor.cores=8 --conf spark.executor.memory=32g --conf spark.driver.memory=4g \
--packages org.apache.hadoop:hadoop-aws:3.3.4,ch.cern.sparkmeasure:spark-measure_2.12:0.24,ch.cern.sparkmeasure:spark-plugins_2.12:0.3 --conf spark.plugins=ch.cern.HDFSMetrics,ch.cern.CgroupMetrics,ch.cern.CloudFSMetrics \
--conf spark.cernSparkPlugin.cloudFsName=s3a \
--conf spark.dynamicAllocation.enabled=false --conf spark.executor.instances=4 \
--conf spark.hadoop.fs.s3a.secret.key=$SECRET_KEY \
--conf spark.hadoop.fs.s3a.access.key=$ACCESS_KEY \
--conf spark.hadoop.fs.s3a.endpoint="https://s3.cern.ch" \
--conf spark.hadoop.fs.s3a.impl="org.apache.hadoop.fs.s3a.S3AFileSystem" \
--conf spark.executor.metrics.fileSystemSchemes="file,hdfs,s3a" \
--conf spark.hadoop.fs.s3a.fast.upload=true \
--conf spark.hadoop.fs.s3a.path.style.access=true \
--conf spark.hadoop.fs.s3a.list.version=1 \
$TPCDS_PYSPARK -d s3a://luca/tpcds_100
```

---
## Old implementation (v1)

Note: spark-dashboard v1 (the original implementation) uses InfluxDB as the time-series database, see also
[spark-dashabord v1 architecture](https://raw.githubusercontent.com/LucaCanali/Miscellaneous/master/Spark_Dashboard/images/Spark_metrics_dashboard_arch.PNG)

### How to run the Spark dashboard V1 on a container
This is the original implementation of the tool using InfluxDB and Grafana 

**1. Start the container**
The provided container image has been built configured to run InfluxDB and Grafana
  -`docker run -p 3000:3000 -p 2003:2003 -d lucacanali/spark-dashboard:v01` 
 - Note: port 2003 is for Graphite ingestion, port 3000 is for Grafana
 - More options, including on how to persist InfluxDB data across restarts at: [Spark dashboard in a container](dockerfiles)

**2. Spark configuration**
See above

**3. Visualize the metrics using a Grafana dashboard**
  - Point your browser to `http://hostname:3000` (edit `hostname` as relevant)
  - See details above

---
### How to run the dashboard V1 on Kubernetes using Helm
If you chose to run on Kubernetes, these are steps:

1. The Helm chart takes care of configuring and running InfluxDB and Grafana:
   - Quickstart: `helm install spark-dashboard https://github.com/cerndb/spark-dashboard/raw/master/charts/spark-dashboard-0.3.0.tgz`
   - Details: [charts](charts)
  
2. Spark configuration:
   - Configure `metrics.properties` as detailed above.
   - Use `INFLUXDB_ENDPOINT=spark-dashboard-influx.default.svc.cluster.local` as the InfluxDB endpoint in 
     the Spark configuration.

3. Grafana's visualization with Helm:
   - The Grafana dashboard is reachable at port 3000 of the spark-dashboard-service.  
   - See service details: `kubectl get service spark-dashboard-grafana`  
   - When using NodePort and an internal cluster IP address, this is how you can port forward to the service from
     the local machine: `kubectl port-forward service/spark-dashboard-grafana 3000:3000`

More info at [Spark dashboard on Kubernetes](charts/README.md)

---
## Advanced configurations and notes

### Graph annotations: display query/job/stage start and end times  
Optionally, you can add annotation instrumentation to the performance dashboard v1.
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
- When using Spark in local mode, use Spark version 3.1 or higher, see [SPARK-31711](https://issues.apache.org/jira/browse/SPARK-31711)

### Docker / Podman
- Telegraf will use port 2003 (graphite endpoint) and port 8428 (VictoriaMetrics source) of your machine/VM.
- For dashboard v1: InfluxDB will use port 2003 (graphite endpoint), and port 8086 (http endpoint) of
  your machine/VM (when running using `--network=host`).
- Note: the endpoints need to be available on the node where you started the container and
  reachable by Spark executors and driver (mind the firewall).

### Helm
- Find the InfluxDB endpoint IP with `kubectl get service spark-dashboard-influx`.
- Optionally, resolve the DNS name with `nslookup` of such IP.
  For example, the InfluxDB service host name of a test installation is: `spark-dashboard-influx.default.svc.cluster.local`

### Customizing and adding new dashboards 

- This implementation comes with some example dashboards. Note that only a subset of the
metrics values logged into VictoriaMetrics are visualized in the provided dashboard.
- For a full list of the available metrics see the [documentation of Spark metrics system](https://github.com/apache/spark/blob/master/docs/monitoring.md#metrics).
- New dashboards can be added by putting them in the relevant `grafana_dashboards` folder and re-building the container image
(or  re-packaging the helm chart).
- On Helm: running helm-update is enough to upload it as ConfigMap and make it available to Grafana. 
- Automatically persisting manual edits is not supported at this time.
