-- Roles are granted different permission to resources (file or folder)
DROP TABLE IF EXISTS roles;
CREATE TABLE IF NOT EXISTS roles (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL UNIQUE CHECK ( name IN ('admin', 'owner', 'editor', 'viewer') ),
    description TEXT NOT NULL
);

DROP INDEX IF EXISTS roles_role_name_index;
CREATE INDEX IF NOT EXISTS roles_role_name_index ON roles(id, name);


INSERT INTO roles (name, description)
VALUES ('admin', 'Has FULL CONTROL over all files and folders, including the ability to MODIFY PERMISSIONS.')
     , ('owner', 'Can READ, WRITE and DELETE the resource; Automatically assigned to the user creating said resource')
     , ('editor', 'Can READ and WRITE but not delete or manage permissions')
     , ('viewer', 'Can only VIEW the resource');
