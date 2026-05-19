# Poolio
Building a better site for my already-drafted NHL Playoff Hockey Pool since the free option that we're using is terrible. Feel free to clone and use this for your own pool

## Structure
Poolio is a web application which runs a React front-end driven by a Node.js/Express back-end. The db is PostgreSQL. Each component is containerized using Docker. Each component has it's own subdirectory with a README.md file which explains the architecture, how to run the Docker compose network, etc.

#### /db
This directory holds all code related to provisioning the Postgres DB. It includes the Postgres container setup, Python scripts which scrape data and create seed files, and a Flyway setup which manages and runs DB migrations for schema and seed data changes. For more information, consult the [README.md](./db/README.md) file.

#### /poolio_api
Development is in progress on the Node.js/Express API. Initial development is being completed on the `feature/api-standings-endpoint` branch.

#### /poolio_webapp
The React front-end is to be completed once API development is finished.