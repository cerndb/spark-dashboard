# Container image for Spark Dashboard
# using InfluxDB and Grafana

FROM ubuntu:22.04

ENV INFLUXDB_VERSION 1.8.10
ENV GRAFANA_VERSION 10.4.0
ENV ARCH amd64

RUN set -ex && \
    apt-get update && \
    apt-get install -qq -y curl libfontconfig musl && \
    curl -O https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_${ARCH}.deb && \
    dpkg -i grafana_${GRAFANA_VERSION}_${ARCH}.deb && \
    rm -f grafana_${GRAFANA_VERSION}_${ARCH}.deb && \
    curl -O https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_${ARCH}.deb && \
    dpkg -i influxdb_${INFLUXDB_VERSION}_${ARCH}.deb && \
    rm -f influxdb_${INFLUXDB_VERSION}_${ARCH}.deb

COPY influxdb.conf /etc/influxdb/influxdb.conf
COPY --chown=grafana:grafana grafana_dashboards /var/lib/grafana/dashboards
COPY --chown=grafana:grafana influx.yaml /etc/grafana/provisioning/datasources/influx.yaml
COPY --chown=grafana:grafana spark.yaml /etc/grafana/provisioning/dashboards/spark.yaml
COPY entrypoint.sh /opt/entrypoint.sh

# expose grafana dashboard (3000) and influxdb graphite (2003) and http (8086) endpoints
EXPOSE 3000/tcp 2003/tcp 8086/tcp

WORKDIR /
ENTRYPOINT [ "/opt/entrypoint.sh" ]
