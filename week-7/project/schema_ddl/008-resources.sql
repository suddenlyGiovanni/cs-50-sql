BEGIN;

DROP TABLE IF EXISTS resources CASCADE;
DROP TYPE IF EXISTS RESOURCE_TYPE CASCADE;
DO
$$
    BEGIN
        IF NOT exists(
                     SELECT 1
                       FROM pg_type
                      WHERE typname = 'RESOURCE_TYPE'
                     ) THEN CREATE TYPE RESOURCE_TYPE AS ENUM ('folder', 'file');
        END IF;
    END;
$$;



CREATE TABLE IF NOT EXISTS resources (
    id         SERIAL        NOT NULL PRIMARY KEY,
    type       RESOURCE_TYPE NOT NULL,
    created_at TIMESTAMP     NOT NULL DEFAULT current_timestamp,
    updated_at TIMESTAMP     NOT NULL DEFAULT current_timestamp,
    created_by INTEGER       NOT NULL,
    updated_by INTEGER       NOT NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id)
);

COMMENT ON COLUMN resources.created_at IS 'The resource creation timestamp; auto-generated on creation';
COMMENT ON COLUMN resources.updated_at IS 'The resource last update timestamp; auto-updated on every update';
COMMENT ON COLUMN resources.created_by IS 'Reference to the user who created the resource';
COMMENT ON COLUMN resources.updated_by IS 'Reference to the user who last updated the resource';

DROP INDEX IF EXISTS resources_type_index;
CREATE INDEX IF NOT EXISTS resources_type_index ON resources(type);


CREATE OR REPLACE FUNCTION resource_update_timestamp() RETURNS TRIGGER AS
$$
BEGIN
    new.updated_at = current_timestamp;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS resources_updated_at_trigger ON resources;
CREATE TRIGGER resources_updated_at_trigger
    BEFORE UPDATE
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resource_update_timestamp();

COMMIT;
