FROM ubuntu:24.04

# Avoid debconf interactive prompts during image build only.
ARG DEBIAN_FRONTEND=noninteractive

# Component versions are build-time parameters, not runtime environment variables.
ARG GRAFANA_VERSION=13.2.2
ARG TELEGRAF_VERSION=1.40.0-1
ARG VM_VERSION=v1.152.0
ARG GRAFANA_VM_PLUGIN_VERSION=v0.26.1

# Docker/BuildKit normally sets TARGETARCH automatically.
# Default keeps normal `docker build` working as amd64.
ARG TARGETARCH=amd64

ENV PLUGIN_PATH=/var/lib/grafana/plugins

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


# ----------------------------------------------------------------------
# Base packages + Grafana + Telegraf
# ----------------------------------------------------------------------
#
# Install local .deb packages with apt-get rather than dpkg.
# This is important for Grafana 13.x because its package has additional
# dependencies (notably systemd).
#
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        adduser \
        ca-certificates \
        curl \
        libfontconfig1 \
        musl \
        tar; \
    \
    # Grafana
    curl \
        --fail \
        --show-error \
        --silent \
        --location \
        --retry 5 \
        --retry-all-errors \
        -o /tmp/grafana.deb \
        "https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_${TARGETARCH}.deb"; \
    apt-get install -y --no-install-recommends /tmp/grafana.deb; \
    rm -f /tmp/grafana.deb; \
    \
    # Telegraf
    curl \
        --fail \
        --show-error \
        --silent \
        --location \
        --retry 5 \
        --retry-all-errors \
        -o /tmp/telegraf.deb \
        "https://repos.influxdata.com/debian/packages/telegraf_${TELEGRAF_VERSION}_${TARGETARCH}.deb"; \
    apt-get install -y --no-install-recommends /tmp/telegraf.deb; \
    rm -f /tmp/telegraf.deb; \
    \
    # Clean apt metadata from the image
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb


# ----------------------------------------------------------------------
# Grafana dashboards and configuration
# ----------------------------------------------------------------------

RUN set -eux; \
    install -d -o grafana -g grafana \
        /var/lib/grafana/dashboards \
        "${PLUGIN_PATH}" \
        /etc/grafana/provisioning/dashboards \
        /etc/grafana/provisioning/datasources

COPY --chown=grafana:grafana grafana_dashboards/ /var/lib/grafana/dashboards/

COPY spark.yaml \
    /etc/grafana/provisioning/dashboards/spark.yaml

COPY grafana.ini \
    /etc/grafana/grafana.ini

COPY victoriametrics-metrics-datasource.yml \
    /etc/grafana/provisioning/datasources/victoriametrics-metrics-datasource.yml


# ----------------------------------------------------------------------
# VictoriaMetrics Grafana datasource plugin
# ----------------------------------------------------------------------

RUN set -eux; \
    curl \
        --fail \
        --show-error \
        --silent \
        --location \
        --retry 5 \
        --retry-all-errors \
        -o /tmp/victoriametrics-datasource.tar.gz \
        "https://github.com/VictoriaMetrics/victoriametrics-datasource/releases/download/${GRAFANA_VM_PLUGIN_VERSION}/victoriametrics-metrics-datasource-${GRAFANA_VM_PLUGIN_VERSION}.tar.gz"; \
    \
    tar \
        -xzf /tmp/victoriametrics-datasource.tar.gz \
        -C "${PLUGIN_PATH}"; \
    \
    rm -f /tmp/victoriametrics-datasource.tar.gz; \
    \
    # Keep only the backend binary needed for this architecture.
    find "${PLUGIN_PATH}/victoriametrics-metrics-datasource" \
        -type f \
        -name 'victoriametrics_backend_plugin*' \
        ! -name "*linux_${TARGETARCH}" \
        -delete; \
    \
    chown -R grafana:grafana "${PLUGIN_PATH}"


# ----------------------------------------------------------------------
# Telegraf configuration
# ----------------------------------------------------------------------

COPY telegraf.conf /etc/telegraf/telegraf.conf


# ----------------------------------------------------------------------
# VictoriaMetrics
# ----------------------------------------------------------------------

RUN set -eux; \
    curl \
        --fail \
        --show-error \
        --silent \
        --location \
        --retry 5 \
        --retry-all-errors \
        -o /tmp/victoria-metrics.tar.gz \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VM_VERSION}/victoria-metrics-linux-${TARGETARCH}-${VM_VERSION}.tar.gz"; \
    \
    tar \
        -xzf /tmp/victoria-metrics.tar.gz \
        -C /; \
    \
    rm -f /tmp/victoria-metrics.tar.gz; \
    \
    chmod 0755 /victoria-metrics-prod


# ----------------------------------------------------------------------
# Entrypoint
# ----------------------------------------------------------------------

COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod 0755 /opt/entrypoint.sh


# Grafana
EXPOSE 3000/tcp

# Telegraf / Graphite
EXPOSE 2003/tcp

# VictoriaMetrics
EXPOSE 8428/tcp


WORKDIR /

ENTRYPOINT ["/opt/entrypoint.sh"]

