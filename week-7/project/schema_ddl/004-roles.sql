BEGIN;

DROP TABLE IF EXISTS roles;

DROP TYPE IF EXISTS ROLE_TYPE;
DO
$$
    BEGIN
        IF NOT exists (
                      SELECT 1
                        FROM pg_type
                       WHERE typname = 'ROLE_TYPE'
                      ) THEN CREATE TYPE ROLE_TYPE AS ENUM ('admin', 'owner', 'editor', 'viewer');
        END IF;
    END;
$$;


CREATE TABLE IF NOT EXISTS roles (
    id          SMALLSERIAL PRIMARY KEY,
    name        ROLE_TYPE    NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL
);
COMMENT ON TABLE roles IS 'Role Base Access Control';
COMMENT ON COLUMN roles.name IS 'The unique name of the role';
COMMENT ON COLUMN roles.description IS 'What the domain behaviour is attached to the role';

DROP INDEX IF EXISTS roles_role_name_index;
CREATE INDEX IF NOT EXISTS roles_role_name_index ON roles(id, name);

INSERT INTO roles (name, description)
VALUES ('admin', 'Has FULL CONTROL over all files and folders, including the ability to MODIFY PERMISSIONS.')
     , ('owner', 'Can READ, WRITE and DELETE the resource; Automatically assigned to the user creating said resource')
     , ('editor', 'Can READ and WRITE but not delete or manage permissions')
     , ('viewer', 'Can only VIEW the resource')
    ON CONFLICT (name) DO NOTHING;

CREATE OR REPLACE FUNCTION roles_seal() RETURNS TRIGGER AS
$$
BEGIN
    RAISE EXCEPTION 'Modifications to the roles table are not allowed.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS roles_seal_trigger ON roles;
CREATE TRIGGER roles_seal_trigger
    BEFORE INSERT OR UPDATE OR DELETE
    ON roles
    FOR EACH ROW
EXECUTE FUNCTION roles_seal();
COMMENT ON TRIGGER roles_seal_trigger ON roles IS 'Seal the roles table';

COMMIT;
