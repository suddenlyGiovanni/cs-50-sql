-- The app needs to rank a user’s “best friends,” similar to Snapchat’s “Friend Emojis” feature.
-- Find the user IDs of the top 3 users to whom creativewisdom377 sends messages most frequently.
-- Order the user IDs by the number of messages creativewisdom377 has sent to those users, most to least.
--
-- Ensure your query uses the search_messages_by_from_user_id index, which is defined as follows:
--
-- ```sqlite
-- CREATE INDEX search_messages_by_from_user_id ON messages (from_user_id);
-- ```


-- plan:
-- 1. find, with a subquery, which user id creativewisdom377 has
-- 2. find all the messages `creativewisdom377` is the sender (`from_user_id`)
-- 3. group his message by the receiver (`to_user_id`)
-- 4. order in descending order the users by number of messages received
-- 5. limit the view to the top 3 messaged user_id

SELECT m.to_user_id
FROM messages m
WHERE m.from_user_id = (
                         SELECT id
                         FROM users
                         WHERE username = 'creativewisdom377'
                       )
GROUP BY m.to_user_id
ORDER BY COUNT(m.to_user_id) DESC
LIMIT 3;
