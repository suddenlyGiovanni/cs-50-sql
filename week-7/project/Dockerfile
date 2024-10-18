FROM arm64v8/postgres:17-alpine
LABEL authors="suddenlygiovanni"

#COPY schema.sql /docker-entrypoint-initdb.d/
COPY schema_ddl/ /docker-entrypoint-initdb.d/

RUN ls -R /docker-entrypoint-initdb.d/
