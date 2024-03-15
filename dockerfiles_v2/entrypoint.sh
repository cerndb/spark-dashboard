#!/bin/bash

# Start the services
service grafana-server start
service telegraf start
./victoria-metrics-prod

# when running with docker run -d option this keeps the container running
tail -f /dev/null


