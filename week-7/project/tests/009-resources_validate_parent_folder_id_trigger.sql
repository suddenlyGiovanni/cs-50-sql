-- Unit test for validate_parent_folder_id function and trigger
DO
$$
    DECLARE
        -- users
        _random_uuid           UUID    := gen_random_uuid();
        _user_name             VARCHAR := 'test_user_' || _random_uuid;
        _user_email            VARCHAR := _user_name || '@test.com';
        _user_id               INT;

        -- resources
        _resources_folder_a_id INT;
        _resources_folder_b_id INT;
        _resources_file_a_id   INT;
        _resources_file_b_id   INT;

        -- folders
        _folder_a_id           INT;
        _folder_a_name         VARCHAR := 'test_folder_' || _random_uuid || '_a';
        _folder_b_id           INT;
        _folder_b_name         VARCHAR := 'test_folder_' || _random_uuid || '_b';


        -- files
        _file_a_id             INT;
    BEGIN

        -- Create a test user
           INSERT INTO users (username, email, hashed_password)
           VALUES (_user_name, _user_email, _random_uuid)
        RETURNING id INTO _user_id;

        -- DESCRIBE: Folder validation:

        -- Test 1: Create a top-level folder
        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('folder', _user_id, _user_id, NULL) -- top-level folder
            RETURNING id INTO _resources_folder_a_id;

               INSERT INTO folders (resource_id, name)
               VALUES (_resources_folder_a_id, _folder_a_name)
            RETURNING id INTO _folder_a_id;

            RAISE NOTICE 'Test 1 passed "Create a top-level folder": File with valid parent folder inserted successfully';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test 1 failed "Create a top-level folder": %', sqlerrm;
        END;


        -- Test 2: Insert a folder with a valid parent folder
        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('folder', _user_id, _user_id, _resources_folder_a_id)
            RETURNING id INTO _resources_folder_b_id;

               INSERT INTO folders (resource_id, name)
               VALUES (_resources_folder_b_id, _folder_b_name)
            RETURNING id INTO _folder_b_id;

            RAISE NOTICE 'Test 2 passed "Insert a folder with a valid parent folder": Folder with valid parent folder inserted successfully';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test 2 failed "Insert a folder with a valid parent folder": %', sqlerrm;
        END;

        -- Test 3: Insert a folder with a non-existent parent folder (should fail)
        BEGIN
            INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
            VALUES ('folder', _user_id, _user_id, 99999);
            RAISE NOTICE 'Test 3 failed "Insert a folder with a non-existent parent folder (should fail)": Folder with non-existent parent folder inserted';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test 3 passed "Insert a folder with a non-existent parent folder (should fail)": Correctly errored with message - %', sqlerrm;
        END;


        -- DESCRIBE: File validation:
        -- Test 4: Insert a file with a valid parent folder
        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('file', _user_id, _user_id, _resources_folder_a_id)
            RETURNING id INTO _resources_file_a_id;

               INSERT INTO files (resource_id, name, mime_type, storage_path)
               VALUES (_resources_file_a_id, 'test_file_a', 'text/plain', 'test_file_a.txt')
            RETURNING id INTO _file_a_id;

            RAISE NOTICE 'Test 4 passed "Insert a file with a valid parent folder": File with valid parent folder inserted successfully';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test 4 failed "Insert a file with a valid parent folder": %', sqlerrm;
        END;

-- Test 5: Insert a file with a NULL parent folder (should fail)
        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('file', _user_id, _user_id, NULL)
            RETURNING id
                INTO _resources_file_b_id;

            RAISE NOTICE 'Test 5 failed "Insert a file with a NULL parent folder (should fail)": File with NULL parent folder inserted';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test 5 passed "Insert a file with a NULL parent folder (should fail)": Correctly errored with message - %', sqlerrm;
        END;


        -- Test 6: insert a file with an existing parent_folder_id but of the wrong type (should fail)
        BEGIN
            INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
            VALUES ('file', _user_id, _user_id, _resources_file_a_id);
            RAISE NOTICE 'Test 6 failed "Insert a file with a wrong parent folder type (should fail)": expected exception';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test 6 passed "Insert a file with a wrong parent folder type (should fail)": Correctly errored with message - %', sqlerrm;
        END;


-- Clean up
        DELETE FROM resources WHERE created_by = _user_id;
        DELETE FROM users WHERE id = _user_id;
    END
$$ LANGUAGE plpgsql;
