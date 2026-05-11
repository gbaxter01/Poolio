## Database
This directory holds all code required to run the PostgreSQL database which services the Poolio API. A Docker Compose network configures running the PostreSQL container, along with a Flyway container which manages database migrations.

### Docker
[PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)

[Flyway Docker Hub](https://hub.docker.com/r/flyway/flyway)

Run the Docker Compose network
```
docker compose -f docker-compose-db.yaml up -d
```
This will build and run the Postgres Docker image, which is configured using environment variables in a **.env** file, and then the Flyway container will run to apply any missing migrations.

To access the database running in the postgres container
```
docker exec -it poolio_db-postgres-1 psql -U $POSTGRES_USER
```

### Flyway
Flyway is a tool used for managing database migrations. It tracks which migrations have already been applied to your database and only applies ones which have not yet been applied. All tables, triggers, indexes, and seed data are defined in SQL files under `flyway/sql/` and are versioned using the convention `Vxxx__<name>.sql`. This naming convention is required as Flyway analyses it to verify whether a file has already been applied.

The goal of using Flyway is to have a reproducible schema which can be applied to any Postgres database. It also provides a clear reference on how and when each table, function, trigger, etc. were created and modified.

To apply a new SQL file while the Docker Compose network is running, simply restart the **flyway** service. It will notice the new file, apply it, then exit gracefully
```
docker compose -f docker-compose-db.yaml up flyway --build
```

#### Resetting the database from schema
This will clear all data  from the database and then rebuild it from the migration files
```
# Stop docker compose network
docker compose -f docker-compose-db.yaml down

# Delete the named volume poolio_data
docker volume rm poolio_db_poolio_data

# Start the docker compose network
docker compose -f docker-compose-db.yaml up -d
```