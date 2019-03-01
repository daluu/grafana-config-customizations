#!/usr/bin/dumb-init /bin/sh

service nginx start
service uwsgi start
/opt/graphite/bin/carbon-cache.py start
/opt/graphite/bin/carbon-aggregator.py start
/opt/grafana/bin/grafana-server -homepath /opt/grafana
