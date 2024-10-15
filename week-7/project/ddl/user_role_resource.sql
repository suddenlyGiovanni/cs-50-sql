DROP TABLE IF EXISTS user_role_resource;
CREATE TABLE IF NOT EXISTS user_role_resource (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    role_id     INTEGER NOT NULL,
    resource_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE
);
