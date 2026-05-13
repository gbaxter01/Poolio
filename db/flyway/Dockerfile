FROM flyway/flyway:12.5.0-alpine

WORKDIR /app

ARG FLYWAY_EDITION
ENV FLYWAY_EDITION="community"

COPY ./flyway.conf ./flyway.conf
COPY ./deploy.sh ./deploy.sh
COPY ./sql ./sql

RUN chmod +x ./deploy.sh && sed -i 's/\r//' ./deploy.sh

ENTRYPOINT [ "./deploy.sh" ]