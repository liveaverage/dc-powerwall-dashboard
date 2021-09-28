#!/bin/bash

export POWERWALL_IP=192.168.1.194
export POWERWALL_PASS=02ESH
export POWERWALL_LOCATION="lat=36.2452052&lon=-80.7292593"

podman rm influxdb || true;
podman run -d \
	--restart always \
	--label "io.containers.autoupdate=image" \
	--name influxdb \
	-v ./influxdb/etc:/etc/influxdb \
	-v /srv/powerwall/influxdb:/var/lib/influxdb:z \
	docker.io/influxdb:1.8

podman rm telegraf || true;
podman run -d \
	--restart always \
        --label "io.containers.autoupdate=image" \
        --name telegraf \
	--add-host powerwall:${POWERWALL_IP} \
	-e POWERWALL_PASS=${POWERWALL_PASS} \
	-e POWERWALL_LOCATION=${POWERWALL_LOCATION} \
        -v ./telegraf/entrypoint.sh:/tmp/entrypoint.sh:z \
	-v ./telegraf/etc:/etc/telegraf:z \
	-v ./powerwall_auth:/tmp/cookie:z \
	docker.io/telegraf:1.19 \
	bash -xe /tmp/entrypoint.sh
  
podman rm grafana || true;
podman run -d \
        --restart always \
        --label "io.containers.autoupdate=image" \
        --name grafana \
        --add-host powerwall:${POWERWALL_IP} \
        -e GF_SECURITY_ADMIN_USER=powerwall \
	-e GF_SECURITY_ADMIN_PASSWORD=powerwall \
	-e GF_INSTALL_PLUGINS=grafana-piechart-panel \
        -e POWERWALL_LOCATION=${POWERWALL_LOCATION} \
        -v ./grafana/datasources:/etc/grafana/provisioning/datasources:z\
        -v ./grafana/dashboards:/etc/grafana/provisioning/dashboards:z \
        -v ./grafana/baked:/var/lib/grafana/dashboards:z \
	-p 3000:3000 \
	docker.io/grafana/grafana:7.5.10

