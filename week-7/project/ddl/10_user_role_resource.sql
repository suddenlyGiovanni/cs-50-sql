BEGIN;
DROP TABLE IF EXISTS user_role_resource;
DROP INDEX IF EXISTS user_role_resource_id_index;
DROP INDEX IF EXISTS user_role_resource_user_id_index;

CREATE TABLE IF NOT EXISTS user_role_resource (
    resource_id INTEGER NOT NULL,
    user_id     INTEGER NOT NULL,
    role_id     INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE,
    UNIQUE (user_id, resource_id) -- Ensures a user can have only one role per resource
);

COMMENT ON TABLE user_role_resource IS 'User-Role-Resource mapping: Many-to-Many relationship. A user can only have one role per resource.';
COMMENT ON COLUMN user_role_resource.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN user_role_resource.user_id IS 'Reference to the user table';
COMMENT ON COLUMN user_role_resource.role_id IS 'Reference to the role table';

CREATE INDEX user_role_resource_id_index ON user_role_resource(resource_id);
CREATE INDEX user_role_resource_user_id_index ON user_role_resource(user_id);

COMMIT;
