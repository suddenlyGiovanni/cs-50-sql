SET search_path TO virtual_file_system, public;

DROP TYPE IF EXISTS RESOURCE_TYPE CASCADE;
DO
$$
    BEGIN
        IF NOT exists(
            SELECT 1
              FROM pg_catalog.pg_type
             WHERE typname = 'RESOURCE_TYPE'
                     ) THEN CREATE TYPE RESOURCE_TYPE AS ENUM ('folder', 'file');
        END IF;
    END;
$$;

COMMENT ON TYPE RESOURCE_TYPE IS 'The type of the resource; either "folder" or "file"';
