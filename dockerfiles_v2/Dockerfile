FROM ubuntu:24.04

ENV TELEGRAF_VERSION 1.35.4-1
ENV GRAFANA_VERSION 12.1.1
ENV VM_VERSION v1.124.0
ENV ARCH amd64
ENV GRAFANA_VM_PLUGIN_VERSION v0.18.3
ENV PLUGIN_PATH /var/lib/grafana/plugins

# Download and install Grafana
RUN set -ex && \
    apt-get update && \
    apt-get install -qq -y curl libfontconfig musl adduser && \
    curl -O https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_${ARCH}.deb && \
    dpkg -i grafana_${GRAFANA_VERSION}_${ARCH}.deb && \
    rm -f grafana_${GRAFANA_VERSION}_${ARCH}.deb

# Copy the bundled dashboards for the spark-dashboard
COPY grafana_dashboards /var/lib/grafana/dashboards
COPY spark.yaml /etc/grafana/provisioning/dashboards/spark.yaml

# Install and configure Grafana datasource for VictoriaMetric
RUN set -ex && \
    curl -L -O https://github.com/VictoriaMetrics/victoriametrics-datasource/releases/download/${GRAFANA_VM_PLUGIN_VERSION}/victoriametrics-metrics-datasource-${GRAFANA_VM_PLUGIN_VERSION}.tar.gz && \
    tar -xzf victoriametrics-metrics-datasource-${GRAFANA_VM_PLUGIN_VERSION}.tar.gz && \
    find victoriametrics-metrics-datasource -type f -name "victoriametrics_backend_plugin*" ! -name "*linux_amd64" -exec rm -f {} + && \
    mkdir ${PLUGIN_PATH} && \
    mv victoriametrics-metrics-datasource ${PLUGIN_PATH} && \
    rm victoriametrics-metrics-datasource-${GRAFANA_VM_PLUGIN_VERSION}.tar.gz

COPY grafana.ini /etc/grafana/grafana.ini
COPY victoriametrics-metrics-datasource.yml /etc/grafana/provisioning/datasources/victoriametrics-metrics-datasource.yml

# Install and configure Telegraf
RUN set -ex && \
    curl -O https://repos.influxdata.com/debian/packages/telegraf_${TELEGRAF_VERSION}_${ARCH}.deb && \
    dpkg -i telegraf_${TELEGRAF_VERSION}_${ARCH}.deb && \
    rm -f telegraf_${TELEGRAF_VERSION}_${ARCH}.deb

COPY telegraf.conf /etc/telegraf/telegraf.conf

# Download and install VictoriaMetrics (VM)
RUN set -ex && \
    curl -L -O https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VM_VERSION}/victoria-metrics-linux-${ARCH}-${VM_VERSION}.tar.gz && \
    tar -xzvf victoria-metrics-*.tar.gz && \
    rm -f victoria-metrics-linux-${ARCH}-${VM_VERSION}.tar.gz

# Copy the entrypoint script, it contains the startup commands
COPY entrypoint.sh /opt/entrypoint.sh

# Expose the ports for Grafana, Telegraf and VictoriaMetrics
EXPOSE 3000/tcp 2003/tcp 8428/tcp

WORKDIR /
ENTRYPOINT [ "/opt/entrypoint.sh" ]
