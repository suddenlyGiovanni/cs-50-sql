-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- CRUD on users:
-- Create a new user
INSERT INTO users (username, email, password, role)
VALUES ('root', 'root@email.com', '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8', 'root')
     , ('admin', 'admin@email.com', 'e481dc2af539d45245208c77f41aa6ca84d0322c', 'admin')
     , ('user_1', 'user.1@email.com', 'e09b4a4e5ad92e5a70aca91b9e382867246b33db', 'user')
     , ('user_2', 'user.2@email.com', '7c3bcbab4141b30131d2736f8e0eb3ae93e0c2bf', 'user')
     , ('user_3', 'user.3@email.com', '2a1093c4c4d5493b4cd0c67d9368c17f5532c5e4', 'user')
     , ('user_4', 'user.4@email.com', '2de2972e50c06709e87918ed976244b6f93cd815', 'user');

-- DELETE a user
DELETE
  FROM users
 WHERE username = 'user_4';

-- Read all users
SELECT *
  FROM users;

-- READ all active users
SELECT *
  FROM users_active;


-- CRUD on folders:
-- Create a new folder
  WITH root_user AS (
                    SELECT id
                      FROM users
                     WHERE username = 'root'
                    )
INSERT
  INTO folders (name, parent_folder_id, owner_id)
VALUES ('root_folder', NULL, (
                             SELECT id
                               FROM root_user
                             ))
     , ('folder_a', 1, (
                       SELECT id
                         FROM root_user
                       ));


INSERT INTO folders (name, parent_folder_id, owner_id)
VALUES ('folder_b', (
                    SELECT id
                      FROM folders f
                     WHERE f.name = 'root_folder'
                    ), (
                       SELECT id
                         FROM users
                        WHERE username = 'root'
                       ));

SELECT f.id
     , f.name
     , rf.name    AS parent_folder
     , u.username AS owner
  FROM folders     f
      JOIN users   u ON u.id = f.owner_id
      JOIN folders rf ON rf.id = f.parent_folder_id
;
