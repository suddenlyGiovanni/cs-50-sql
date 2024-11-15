SET search_path TO virtual_file_system, public;

BEGIN;
DO
$$
    BEGIN
        IF NOT exists (
            SELECT 1
              FROM pg_type
             WHERE typname = 'ROLE'
                      ) THEN CREATE TYPE ROLE AS ENUM ('admin', 'owner', 'editor', 'viewer');
        END IF;
    END;
$$;


COMMENT ON TYPE ROLE IS 'The type of role a user can have in the system.
    Admins can do everything,
    Owners can do everything except delete the project,
    Editors can do everything except delete the project and manage users,
    Viewers can only view the project.';


COMMIT;
