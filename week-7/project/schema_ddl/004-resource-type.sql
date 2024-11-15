SET search_path TO virtual_file_system, public;


DO
$$
    BEGIN
        IF NOT exists(
            SELECT 1
              FROM pg_catalog.pg_type
             WHERE typname = 'RESOURCE'
                     ) THEN CREATE TYPE RESOURCE AS ENUM ('folder', 'file');
        END IF;
    END;
$$;

COMMENT ON TYPE RESOURCE IS 'The type of the resource; either "folder" or "file"';
