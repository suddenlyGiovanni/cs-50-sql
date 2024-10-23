INSERT INTO users (username, email, hashed_password)
VALUES ('user_1', 'user.1@email.com', 'e09b4a4e5ad92e5a70aca91b9e382867246b33db')
     , ('user_2', 'user.2@email.com', '7c3bcbab4141b30131d2736f8e0eb3ae93e0c2bf')
     , ('user_3', 'user.3@email.com', '2a1093c4c4d5493b4cd0c67d9368c17f5532c5e4')
     , ('user_4', 'user.4@email.com', '2de2972e50c06709e87918ed976244b6f93cd815');


/*
 * Create a folder structure as follows for user_1:
 *
 * A
 * ├── B1
 * │   └── C
 * │       └── D
 * └── B2
*/
DO
$$
    DECLARE
        folder_a_id  INT;
        folder_b1_id INT;
        folder_b2_id INT;
        folder_c_id  INT;
        folder_d_id  INT;
        _role_type   ROLE_TYPE := 'owner';
        _username    TEXT      := 'user_1';
    BEGIN
        -- Create folder "A"
        SELECT INTO folder_a_id mkdir('A', _username, _role_type);

        -- Create sub-folder "B1" under folder "A"
        SELECT INTO folder_b1_id mkdir('B1', _username, _role_type, folder_a_id);

        -- Create sub-folder "B2" under folder "A"
        SELECT INTO folder_b2_id mkdir('B2', _username, _role_type, folder_a_id);

        -- Create sub-folder "C" under folder "B1"
        SELECT INTO folder_c_id mkdir('C', _username, _role_type, folder_b1_id);

        -- Create sub-folder "D" under folder "C"
        SELECT INTO folder_d_id mkdir('D', _username, _role_type, folder_c_id);
    END
$$;
