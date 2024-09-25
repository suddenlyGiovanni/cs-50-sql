-- For any two users, the app needs to quickly show a list of the friends they have in common.
-- Given two usernames, lovelytrust487 and exceptionalinspiration482, find the user IDs of their mutual friends.
-- A mutual friend is a user that both lovelytrust487 and exceptionalinspiration482 count among their friends.
--
-- Ensure your query uses the index automatically created on primary key columns of the friends table.
-- This index is called sqlite_autoindex_friends_1.

WITH user_1 AS (
                 SELECT u.id AS user_id
                 FROM users u
                 WHERE username = 'lovelytrust487'
               ),
     user_2 AS (
                 SELECT u.id AS user_id FROM users u WHERE username = 'exceptionalinspiration482'
               )
SELECT f.friend_id
FROM friends f
WHERE f.user_id = (
                    SELECT user_id
                    FROM user_1
                  )
INTERSECT
SELECT f.friend_id
FROM friends f
WHERE f.user_id = (
                    SELECT user_id
                    FROM user_2
                  );
