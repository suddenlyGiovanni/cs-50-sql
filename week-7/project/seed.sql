INSERT
  INTO users (username, email, hashed_password)
VALUES ('user_1', 'user.1@email.com', 'e09b4a4e5ad92e5a70aca91b9e382867246b33db')
     , ('user_2', 'user.2@email.com', '7c3bcbab4141b30131d2736f8e0eb3ae93e0c2bf')
     , ('user_3', 'user.3@email.com', '2a1093c4c4d5493b4cd0c67d9368c17f5532c5e4')
     , ('user_4', 'user.4@email.com', '2de2972e50c06709e87918ed976244b6f93cd815');


/*
 * Create a folder structure as follows for user_1:
 *
 * A
 * ├── AA_1
 * │   └── AAA_1
 * │       └── AAAA_1
 * └── AA_2
*/
DO
$$
    DECLARE
        folder_a_id      INT;
        folder_aa_1_id   INT;
        folder_aa_2_id   INT;
        folder_aaa_1_id  INT;
        folder_aaaa_1_id INT;
        _username        TEXT := 'user_1';
    BEGIN
        -- Create folder "A"
        SELECT INTO folder_a_id mkdir('A', _username);

        -- Create sub-folder "B1" under folder "A"
        SELECT INTO folder_aa_1_id
               mkdir('AA_1', _username, parent_folder_id => folder_a_id);

        -- Create sub-folder "AA_2" under folder "A"
        SELECT INTO folder_aa_2_id
               mkdir('AA_2', _username, parent_folder_id => folder_a_id);

        -- Create sub-folder "AAA_1" under folder "AA_2"
        SELECT INTO folder_aaa_1_id
               mkdir('AAA_1', _username, parent_folder_id => folder_aa_1_id);

        -- Create sub-folder "AAAA_1" under folder "AAA_1"
        SELECT INTO folder_aaaa_1_id
               mkdir('AAAA_1', _username, parent_folder_id => folder_aaa_1_id);
    END
$$;


/*
* test folder circular dependency
*/
DO
$$
    DECLARE
        _update_row_count SMALLINT;
    BEGIN

        /*
         *  Cyclic Graph Test
         *
         *  A
         *  ├── AA_1
         *  │    └── AAA_1
         *  │         └── AAAA_1
         *  │              │
         *  └──────────────┘
         *              ▲
         *              │
         *              └── back to A
         *
         */

        -- ACT: Attempt to create a circular dependency
           UPDATE resources
              SET parent_folder_id = (
                  SELECT folders.id
                    FROM folders
                   WHERE folders.name = 'AAAA_1'
                   LIMIT 1
                                     )
            WHERE resources.id = (
                SELECT folders.resource_id
                  FROM folders
                 WHERE folders.name = 'A'
                 LIMIT 1
                                 )
        RETURNING 1 INTO _update_row_count;


        /*
         * If no exception is thrown, raise an error indicating the test failed
         *
         * this statement should never be reached if the UPDATE fails as expected.
         */
        IF _update_row_count > 0 THEN
            RAISE EXCEPTION 'Test failed: Circular dependency was not detected by the validation triggers';
        END IF;


    EXCEPTION
        WHEN OTHERS THEN -- Catch any exception and output the message
            IF sqlerrm = 'Test failed: Circular dependency was not detected by the validation triggers' THEN
                -- ASSERTION FAILED
                RAISE NOTICE 'Test failed: Expected circular dependency was not detected by the validation triggers';
            ELSE
                -- ASSERTION PASSED
                RAISE NOTICE 'Test passed: Expected circular dependency detected with error - %', sqlerrm;
            END IF;
    END;
$$ LANGUAGE plpgsql;


/*
 * Create a folder structure as follows for user_2:
 *
 * B -|
 *
*/
DO
$$
    DECLARE
        folder_b_id INT;
        _username   TEXT := 'user_2';
    BEGIN
        -- Create folder "B"
        SELECT INTO folder_b_id mkdir('B', _username);
    END
$$;



DO
$$
    DECLARE
        _resource_aa_1_id INT := (
                                     SELECT f.resource_id
                                       FROM folders f
                                      WHERE f.name = 'AA_1'
                                 );
        _user_2_id        INT := (
                                     SELECT id
                                       FROM users u
                                      WHERE u.username = 'user_2'
                                 );
    BEGIN
        PERFORM virtual_file_system.public.chmod(_resource_aa_1_id, _user_2_id, 'admin');
    END
$$;
