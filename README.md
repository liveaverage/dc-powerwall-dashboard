# Overview

This project is a complete monitoring & trending stack for Tesla Powerwall & Backup Gateway solutions. It consists of vendor-provided images of Telegraf, InfluxDB, and Grafana. This is an evolutionary stage of the original monolith, multi-arch container project [docker-powerwall-dashboard](https://github.com/liveaverage/docker-powerwall-dashboard) and attempts to simplify maintenance of the stack by splitting-out each service.

# Preview

<a href="https://i.imgur.com/GtP725k.png" ><img src="https://i.imgur.com/GtP725k.png" alt="Grafana Dashboard Preview" width="50%"/></a>

# Usage

- FIXME

# Notes

- If using podman you may need to cleanup containers before re-running the stack: `sudo docker rm $(sudo docker ps -q --filter "status=exited")`
  - [In order to use podman with docker-compose](https://www.redhat.com/sysadmin/podman-docker-compose) you'll need to install a few extra packages alongside podman 3.0+:
    - docker-compose
    - podman-docker
- A future project iteration will provide k8s manifests and/or helm chart to run the stack on k3s (for multi-arch support)
- This project is based on the work of [@rhodesman](https://github.com/rhodesman) and his [teslaPowerDash](https://github.com/rhodesman/teslaPowerDash) repo, but hopefully enables easier ramp up to start obtaining and trending Powerwall 2 API data. 