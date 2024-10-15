-- Defines the type of resource: folder or file
DROP TABLE IF EXISTS resources;
CREATE TABLE IF NOT EXISTS resources (
    id   INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    type TEXT    NOT NULL CHECK ( type IN ('folder', 'file') )
);

DROP INDEX IF EXISTS resources_type_index;
CREATE INDEX IF NOT EXISTS resources_type_index ON resources(type);
