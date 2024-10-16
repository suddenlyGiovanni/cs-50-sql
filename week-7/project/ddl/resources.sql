-- Defines the type of resource: folder or file

BEGIN;
DROP TABLE IF EXISTS resources;
DROP TYPE IF EXISTS RESOURCE_TYPE;
DROP INDEX IF EXISTS resources_type_index;

CREATE TYPE RESOURCE_TYPE AS ENUM ('folder', 'file');

CREATE TABLE IF NOT EXISTS resources (
    id   SERIAL        NOT NULL PRIMARY KEY,
    type RESOURCE_TYPE NOT NULL
);

CREATE INDEX IF NOT EXISTS resources_type_index ON resources(type);

COMMIT;
