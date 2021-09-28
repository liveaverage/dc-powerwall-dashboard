#!/bin/bash

podman pod create -n dcpowerwalldashboard -p 3000:3000

podman generate systemd --new -n --files grafana
podman generate systemd --new -n --files telegraf
podman generate systemd --new -n --files influxdb
