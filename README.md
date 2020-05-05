# Helm Chart for Spark-Dashboard

This repository contains a Helm chart to ease the deployment of a performance dashboard for Apache Spark on Kubernetes.
The dashboard collects and displays workload data based on Spark metrics, using InfluxDB and Grafana.  
Details of how this works at: [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard)  
More info at: [Spark Summit 2019 talk](https://databricks.com/session_eu19/performance-troubleshooting-using-apache-spark-metrics)

![Spark metrics dashboard architecture](https://raw.githubusercontent.com/LucaCanali/Miscellaneous/master/Spark_Dashboard/images/Spark_metrics_dashboard_arch.PNG "Spark metrics dashboard architecture")

## Installation and administration

The chart can be installed using [helm](https://helm.sh/docs/intro/quickstart/) with:  
```
helm install spark-dashboard -f values.yaml .
```  

Other options:
```
# package and install
helm package .
helm install spark-dashboard spark-dashboard-0.3.0.tgz

# update
helm upgrade --install spark-dashboard spark-dashboard-0.3.0.tgz

# uninstall
helm uninstall spark-dashboard

# list and display installed components
help list
kubectl get service spark-dashboard-grafana spark-dashboard-influx
kubectl get pods |grep spark-dashboard
kubectl get configmaps |grep spark-dashboard
```

## Configuration options

The provided configuration is for testig purposes, for production use you may need further configuration, as typical for these type of components.
- The storage for influxDB can be defined in the `values.yaml`
  - If no storageClass is provided, an `EmptyDir` will be allocated: the dashboard history will be lost when the
   underlying pod is restarted. You may rather want to use a storage class in the configuration.
- The services exposed by `grafana` and `influx` in the example use `NodePort`. You can use `LoadBalancer` type if your Kubernetes can support it.

## How to connect to the dashboard

The dashboard is reachable at port 3000 of the spark-dashboard-service.
See details: `kubectl get service spark-dashboard-grafana`).
When using NodePort and internal cluster IP addresses, this how you can port forward to the service from the local machine: `kubectl port-forward service/spark-dashboard-grafana 3000:3000
`
## How to use this with Spark

As explained in [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard) you need to set a few 
Spark configuration parameter to use this type of instrumentation. In particular, you need to point Spark to
write to the InfluxDB instance (with graphite endpoint).
Find the (cluster) endpoint with `kubectl get service spark-dashboard-influx`. Optionally resolv the dns name with `nslookup` of such IP.
In this example configuration parameter list, the InfluxDB service host name is `spark-dashboard-influx.default.svc.cluster.local`
```
--conf "spark.metrics.conf.driver.sink.graphite.class"="org.apache.spark.metrics.sink.GraphiteSink"         \
--conf "spark.metrics.conf.executor.sink.graphite.class"="org.apache.spark.metrics.sink.GraphiteSink"         \
--conf "spark.metrics.conf.driver.sink.graphite.host"="spark-dashboard-influx.default.svc.cluster.local"         \
--conf "spark.metrics.conf.executor.sink.graphite.host"="spark-dashboard-influx.default.svc.cluster.local"         \
--conf "spark.metrics.conf.*.sink.graphite.port"=2003         \
--conf "spark.metrics.conf.*.sink.graphite.period"=10         \
--conf "spark.metrics.conf.*.sink.graphite.unit"=seconds         \
--conf "spark.metrics.conf.*.sink.graphite.prefix"="luca"        \
--conf "spark.metrics.conf.*.source.jvm.class"="org.apache.spark.metrics.source.JvmSource" \
```

Note: If you want in addition to use annotation instrumentation 
(which add info on the queries, jobs and stages time), add the following configuration:
```
--packages ch.cern.sparkmeasure:spark-measure_2.12:0.16 \
--conf spark.sparkmeasure.influxdbURL="http://spark-dashboard-influx.default.svc.cluster.local:8086" \
--conf spark.extraListeners=ch.cern.sparkmeasure.InfluxDBSink
```

## Adding new dashboards 

New dashboards can be added by putting them in the `grafana_dashboards` folder in json format and re-packaging the chart.
Running helm-update is enough to upload it as ConfigMap and make it available to Grafana. 
Persisting manual edits automatically is not supported at this time.
