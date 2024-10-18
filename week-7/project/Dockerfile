FROM arm64v8/postgres:17-alpine
LABEL authors="suddenlygiovanni"

COPY schema_ddl/ /docker-entrypoint-initdb.d/

# Create a symbolic link directly in the docker-entrypoint-initdb.d directory
RUN ln -s /docker-entrypoint-initdb.d /schema_ddl

COPY schema.sql /schema.sql
