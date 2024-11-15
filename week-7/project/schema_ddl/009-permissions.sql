SET search_path TO virtual_file_system, public;

BEGIN;

DROP TABLE IF EXISTS permissions CASCADE;

CREATE TABLE IF NOT EXISTS permissions (
    id          SMALLSERIAL PRIMARY KEY,
    name        PERMISSION_TYPE NOT NULL UNIQUE,
    description VARCHAR(255)    NOT NULL
);

DROP INDEX IF EXISTS permissions_permission_name_index;
CREATE INDEX IF NOT EXISTS permissions_permission_name_index ON permissions(id, name);

INSERT
  INTO permissions (name, description)
VALUES ('read', 'Can READ a resource, Folder or File')
     , ('write', 'Can UPDATE a resource, Folder or File')
     , ('delete', 'Can DELETE a resource, Folder or File')
     , ('manage', 'Can change the access control of a resource, File or Folder')
    ON CONFLICT (name) DO NOTHING;

COMMIT;
