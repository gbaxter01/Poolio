## Poolio API
This directory holds all code related to the Poolio API which will serve the Poolio front-end.

### Grafana
Grafana is setup for monitoring and visualizing both logs and metrics. It has been adapted from Grafana's official [example docker setup](https://github.com/grafana/alloy-scenarios/tree/main/docker-monitoring). More information about the Alloy setup from the docker example can be found [here](https://grafana.com/docs/alloy/latest/monitor/monitor-docker-containers/).

The following services have been added to the docker-compose file to setup Grafana for monitoring the Poolio API:

#### Loki
Aggregates and stores logs that are pushed to it by Alloy.
- Alloy pushes the logs to Loki and it receives, indexes, and stores them.
- The Grafana service can query the Loki container through port 3100 to access the logs.
- A custom configuration file [loki-config.yaml](./grafana/loki-config.yaml) is injected as a volume mount.

#### Grafana
UI for querying and displaying logs and metrics
- The Grafana UI can be accessed through port 3000
- The custom entrypoint for this service writes the datasources config file `ds.yaml` at startup. This automatically adds Loki as the datasource, so it doesn't have to be manually added through the Grafana UI.
- Password for logging into **admin** acount is stored in the environment variable `GRAFANA_ADMIN_PASSWORD`

#### Alloy
Collects the logs and then sends them to Loki.
- The Alloy UI can be accessed through port 12345. This allows you to see what's being collected and debug any issues with collection
- The current setup collects logs and process metrics like CPU and memory usage from the **app** container.
- Other metrics like harware/kernel metrics, I/O metrics, and disk usage metrics can be added later if needed.