-- Unit test for validate_parent_folder_id function and trigger
DO
$$
    DECLARE
        -- users
        _user_name             VARCHAR := 'test_user_' || gen_random_uuid();
        _user_id               INT;

        -- resources
        _resources_folder_a_id INT;
        _resources_folder_b_id INT;
        _resources_file_a_id   INT;
        _resources_file_b_id   INT;

        -- folders
        _folder_a_id           INT;
        _folder_b_id           INT;

        -- files
        _file_a_id             INT;
    BEGIN

        -- Create a test user
           INSERT INTO users (username, email, hashed_password)
           VALUES (_user_name, _user_name || '@email.com', 'dummy_hash')
        RETURNING id INTO _user_id;

        -- DESCRIBE: folder validation:

        -- Test: Create a top-level folder
        BEGIN
               INSERT INTO resources (type, created_by, updated_by)
               VALUES ('folder', _user_id, _user_id)
            RETURNING id INTO _resources_folder_a_id;

               INSERT INTO folders (resource_id, name)
               VALUES (_resources_folder_a_id, 'test_folder_a')
            RETURNING id INTO _folder_a_id;

            RAISE NOTICE 'Test passed "Create a top-level FOLDER": File with valid parent folder inserted successfully';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test failed "Create a top-level folder": %', sqlerrm;
        END;


        -- Test: Insert a folder with a valid parent folder
        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('folder', _user_id, _user_id, _folder_a_id)
            RETURNING id INTO _resources_folder_b_id;

               INSERT INTO folders (resource_id, name)
               VALUES (_resources_folder_b_id, 'test_folder_b')
            RETURNING id INTO _folder_b_id;

            RAISE NOTICE 'Test passed "Insert a FOLDER with a valid parent folder": Folder with valid parent folder inserted successfully';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test failed "Insert a FOLDER with a valid parent folder": %', sqlerrm;
        END;

        -- Test: Insert a folder with a non-existent parent folder (should fail)
        BEGIN
            INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
            VALUES ('folder', _user_id, _folder_a_id, 99999);
            RAISE NOTICE 'Test failed "Insert a FOLDER with a non-existent parent folder (should fail)": Folder with non-existent parent folder inserted';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test passed "Insert a FOLDER with a non-existent parent folder (should fail)": Expected error - %', sqlerrm;
        END;

        -- Test: Insert a file with a valid parent folder
        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('file', _user_id, _user_id, _folder_a_id)
            RETURNING id INTO _resources_file_a_id;

               INSERT INTO files (resource_id, name, mime_type, storage_path)
               VALUES (_resources_file_a_id, 'test_file_a', 'text/plain', 'test_file_a.txt')
            RETURNING id INTO _file_a_id;

            RAISE NOTICE 'Test passed "Insert a FILE with a valid parent folder": File with valid parent folder inserted successfully';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test failed "Insert a FILE with a valid parent folder": %', sqlerrm;
        END;

-- Test: Insert a file with a NULL parent folder (should fail)
        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('file', _user_id, _user_id, NULL)
            RETURNING id
                INTO _resources_file_b_id;

            RAISE NOTICE 'Test failed "Insert a FILE with a NULL parent folder (should fail)": File with NULL parent folder inserted';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test passed "Insert a FILE with a NULL parent folder (should fail)": Expected error - %', sqlerrm;
        END;


-- Clean up
        DELETE FROM resources WHERE created_by = _user_id;
        DELETE FROM users WHERE id = _user_id;
    END
$$ LANGUAGE plpgsql;
