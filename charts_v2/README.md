# Spark Dashboard v2 Helm Chart

This chart installs Spark Dashboard v2 on Kubernetes using the v2 container image and configuration layout:

- Grafana for visualization
- Telegraf for Graphite ingestion
- VictoriaMetrics for metrics storage

## Install

From the chart directory:

```bash
helm install spark-dashboard ./charts_v2
```

If your cluster does not have a default storage class, start with:

```bash
helm install spark-dashboard ./charts_v2 --set persistence.enabled=false
```

With custom values:

```bash
helm install spark-dashboard ./charts_v2 -f my-values.yaml
```

To expose Grafana and Graphite outside the cluster with a stable external address, use a `LoadBalancer` service:

```bash
helm install spark-dashboard ./charts_v2 \
  --set persistence.enabled=false \
  --set service.type=LoadBalancer
```

This does not expose VictoriaMetrics port `8428` on the load balancer by default. Expose it only when needed:

```bash
helm install spark-dashboard ./charts_v2 \
  --set persistence.enabled=false \
  --set service.type=LoadBalancer \
  --set service.victoriametrics.exposeOnLoadBalancer=true
```

## Grafana HTTPS

By default, Grafana listens with HTTP on port `3000`. To use HTTPS, first create a certificate. For testing, `openssl` can be used to generate a self-signed certificate:

```bash
openssl req -x509 -newkey rsa:4096 -nodes -days 365 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=dashboard.example.com" \
  -addext "subjectAltName=DNS:dashboard.example.com"
```

Then create a Kubernetes TLS secret and enable the chart option:

```bash
kubectl create secret tls spark-dashboard-grafana-tls \
  --cert=./tls.crt \
  --key=./tls.key

helm upgrade --install spark-dashboard ./charts_v2 \
  --set persistence.enabled=false \
  --set grafana.https.enabled=true \
  --set grafana.https.secretName=spark-dashboard-grafana-tls
```

The chart expects the secret keys to be `tls.crt` and `tls.key`. If your secret uses different key names, set:

```bash
helm upgrade --install spark-dashboard ./charts_v2 \
  --set grafana.https.enabled=true \
  --set grafana.https.secretName=spark-dashboard-grafana-tls \
  --set grafana.https.certFile=grafana.crt \
  --set grafana.https.certKey=grafana.key
```

Set `grafana.https.rootUrl` when Grafana is served through a DNS name or external URL:

```bash
helm upgrade --install spark-dashboard ./charts_v2 \
  --set grafana.https.enabled=true \
  --set grafana.https.secretName=spark-dashboard-grafana-tls \
  --set grafana.https.rootUrl=https://dashboard.example.com:3000/
```

## Upgrade

```bash
helm upgrade --install spark-dashboard ./charts_v2
```

## Uninstall

```bash
helm uninstall spark-dashboard
```

## Notes

- Grafana is exposed on port `3000` using HTTP by default, or HTTPS when `grafana.https.enabled=true`.
- Spark metrics are ingested on port `2003` using Graphite protocol.
- VictoriaMetrics listens on port `8428` inside the pod.
- With `service.type=LoadBalancer`, port `8428` is not exposed by default; set `service.victoriametrics.exposeOnLoadBalancer=true` only when needed.
- By default, metrics storage uses a persistent volume claim. Disable persistence to use `emptyDir`.
- If you want persistent storage and your cluster has no default storage class, set `persistence.storageClass` explicitly.

## Example checks

```bash
kubectl get pods -l app.kubernetes.io/name=spark-dashboard-v2
kubectl get svc spark-dashboard-v2
```

## Testing

Install the chart and wait for the pod to become `Running`:

```bash
helm install spark-dashboard ./charts_v2 --set persistence.enabled=false
kubectl get pods -l app.kubernetes.io/name=spark-dashboard-v2 -w
kubectl get svc spark-dashboard-v2
```

For Spark running inside the Kubernetes cluster, use the service DNS name as the Graphite endpoint:

```text
spark-dashboard-v2:2003
```

For Spark running outside the Kubernetes cluster, prefer a `LoadBalancer` service and use the external address:

```bash
kubectl get svc spark-dashboard-v2 -w
```

When `EXTERNAL-IP` is assigned, use:

```text
<external-ip>:2003
```

For Grafana:

```text
http://<external-ip>:3000
```

For browser access to Grafana during testing, use port-forward:

```bash
kubectl port-forward svc/spark-dashboard-v2 3000:3000 2003:2003
```

Then open:

```text
http://localhost:3000
```

If Spark runs on the same machine as the port-forward, use:

```text
localhost:2003
```

## Troubleshooting

If the pod stays `Pending`, check whether the persistent volume claim is waiting for a storage class:

```bash
kubectl get pvc
kubectl describe pod -l app.kubernetes.io/name=spark-dashboard-v2
kubectl get storageclass
```

If your cluster has no suitable storage class, reinstall with:

```bash
helm uninstall spark-dashboard
helm install spark-dashboard ./charts_v2 --set persistence.enabled=false
```

If the service exists but external `NodePort` access is refused, verify that the pod and service work inside the cluster first:

```bash
kubectl get endpoints spark-dashboard-v2
kubectl run netcheck --rm -it --image=busybox:1.36 --restart=Never -- sh
```

From the debug shell:

```sh
nc -vz spark-dashboard-v2 3000
nc -vz spark-dashboard-v2 2003
```

If those in-cluster checks pass, the chart is working and the remaining issue is external cluster networking, firewall rules, or `NodePort` exposure.

If you install with `service.type=LoadBalancer` and `EXTERNAL-IP` stays pending, your cluster likely does not have load balancer integration configured. In that case, use `NodePort`, install a load balancer solution such as MetalLB, or ask your cluster administrators for the supported external exposure mechanism.
