#!/bin/bash

# This takes care of changing ownership, useful when mounting
# /var/lib/influxdb from an external volume
chown -R influxdb:influxdb /var/lib/influxdb

service influxdb start
service grafana-server start

# when running with docker run -d option this keeps the container running
tail -f /dev/null
