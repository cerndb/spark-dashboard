# Helm chart for spark-dashboard

This repository contains an Helm chart to deploy [Spark Dashboard](https://github.com/LucaCanali/Miscellaneous/tree/master/Spark_Dashboard).

## Installation

The chart can be installed with `helm install -f values.yaml`. A reference `values.yaml` can be found in the `templates` folder.

# Configuration options

The storage for influxDB can be defined in the `values.yaml`: if no storageClass is provided, an EmptyDir will be allocated.
The services exposed by `grafana` and `influx` can be of `LoadBalancer` type if your Kubernetes can support it, or a `NodePort`.

## Adding new dashboards 

New dashboards can be added by putting them in the grafana\_dashboards folder in json format and re-packaging the chart. Running helm-update is enough to upload it as ConfigMap and make it available to grafana. Persisting the manual edits automatically is not supported at this time.
