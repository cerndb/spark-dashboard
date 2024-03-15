# How to install the Helm Chart for the Spark Dashboard

The Helm chart is installed using [helm](https://helm.sh/docs/intro/quickstart/):
```
helm install spark-dashboard https://github.com/cerndb/spark-dashboard/raw/master/charts/spark-dashboard-0.3.0.tgz
```  

Other installation options:
 
```
# Install from source.
# Prerequisite: download the repo and cd into the charts directory
helm install spark-dashboard -f values.yaml .
```  

```
# Re-package and install
helm package .
helm install spark-dashboard spark-dashboard-0.3.0.tgz
```

Additional admin commands:
```
# Update the chart (after repackaging)
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

The provided configuration is for testing purposes, for production use you may need further configuration, as typical for these type of components.
- The storage for influxDB can be defined in the `values.yaml`
  - If no storageClass is provided, an `EmptyDir` will be allocated: the dashboard history will be lost when the
   underlying pod is restarted. You may rather want to use a persistent backend in the configuration.
- The services exposed by `grafana` and `influx` in the example are of type `NodePort`. You can use `LoadBalancer` type if your Kubernetes distribution supports it.
