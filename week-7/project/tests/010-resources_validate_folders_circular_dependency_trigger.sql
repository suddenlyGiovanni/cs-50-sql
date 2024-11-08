-- Unit test for validate_parent_folder_id function and trigger
DO
$$
    DECLARE
        _random_uuid           VARCHAR := gen_random_uuid();
        _user_name             VARCHAR := 'test_user_' || _random_uuid;
        _test_folder_a_name    VARCHAR := 'test_folder_' || _random_uuid || '_a';
        _test_folder_b_name    VARCHAR := 'test_folder_' || _random_uuid || '_b';
        _user_id               INT;
        _resources_folder_a_id INT;
        _resources_folder_b_id INT;
        _resources_folder_c_id INT;
        _folder_a_id           INT;
        _folder_b_id           INT;
    BEGIN
        -- Arrange
        -- Create a test user
           INSERT INTO users (username, email, hashed_password)
           VALUES (_user_name, _user_name || '@email.com', 'dummy_hash')
        RETURNING id INTO _user_id;


        -- Create a top-level folder
           INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
           VALUES ('folder', _user_id, _user_id, NULL) -- Root folder, parent_folder_id is NULL
        RETURNING id INTO _resources_folder_a_id;

           INSERT INTO folders (resource_id, name)
           VALUES (_resources_folder_a_id, _test_folder_a_name)
        RETURNING id INTO _folder_a_id;


        -- Create a folder inside the folder_a
           INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
           VALUES ('folder', _user_id, _user_id, _folder_a_id) -- Correct parent_folder_id
        RETURNING id INTO _resources_folder_b_id;

           INSERT INTO folders (resource_id, name)
           VALUES (_resources_folder_b_id, _test_folder_b_name)
        RETURNING id INTO _folder_b_id;


        --  Act: insert a folder creating a circular dependency.
        -- Assert: Expect transaction to fail.

        BEGIN
               INSERT INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('folder', _user_id, _user_id, _folder_a_id) -- Intentional circular dependency
            RETURNING id INTO _resources_folder_c_id;
            RAISE NOTICE 'Test failed "Insert a FOLDER with a circular dependency": Expected exception but transaction succeeded';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Test passed "Insert a FOLDER with a circular dependency":  %', sqlerrm;
        END;

        -- clean up

        DELETE FROM resources WHERE id = _resources_folder_c_id;
        DELETE FROM resources WHERE id = _resources_folder_b_id; -- should cascade delete folders 'test_folder_b';
        DELETE FROM resources WHERE id = _resources_folder_a_id; -- should cascade delete folders 'test_folder_a'
        DELETE FROM users WHERE id = _user_id;
    END
$$ LANGUAGE plpgsql;
