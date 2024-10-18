-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it

-- \i ./schema_ddl/000-database.sql

\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/001-virtual_file_system_schema.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/002-users.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/003-active_users_view.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/004-roles.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/005-permissions.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/006-role_permissions.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/007-role_permissions_matrix_view.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/008-resources.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/009-folders.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/010-files.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/011-user_role_resource.sql
\i /docker-entrypoint-initdb.d/schema_ddl/schema_ddl/012-user_role_resource_access_view.sql
