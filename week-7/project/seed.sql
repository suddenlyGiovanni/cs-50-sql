INSERT INTO users (username, email,              hashed_password                           )
VALUES            (
                   'user_1', 'user.1@email.com', 'e09b4a4e5ad92e5a70aca91b9e382867246b33db')
     ,            (
                   'user_2', 'user.2@email.com', '7c3bcbab4141b30131d2736f8e0eb3ae93e0c2bf')
     ,            (
                   'user_3', 'user.3@email.com', '2a1093c4c4d5493b4cd0c67d9368c17f5532c5e4')
     ,            (
                   'user_4', 'user.4@email.com', '2de2972e50c06709e87918ed976244b6f93cd815');


-- create a root folder


BEGIN;
-- Get user ID for user_1
  WITH user_1 AS (SELECT id FROM users WHERE username = 'user_1'
      )
     ,
-- Create a new resource and get its ID
      new_resource AS ( INSERT INTO resources(type, created_by, updated_by) VALUES ('folder', (SELECT id FROM user_1
          ), (SELECT id FROM user_1
          )) RETURNING id
      )
     ,
-- Create a new resource and retrieve the new resource ID
      new_folder AS (INSERT INTO folders(resource_id, parent_folder_id, name) VALUES ((SELECT id FROM new_resource
          ), NULL, 'folder_1') RETURNING id
      )

-- Add corresponding role-based access for the new resource
INSERT
  INTO user_role_resource (resource_id, user_id, role_id)
VALUES (
             (SELECT id FROM new_resource), (SELECT id FROM user_1), (SELECT id FROM roles WHERE roles.name = 'owner'));
COMMIT;
