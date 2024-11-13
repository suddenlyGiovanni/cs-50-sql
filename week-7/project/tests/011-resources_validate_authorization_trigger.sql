/*
*  Unit test for auth validation trigger on resources table
*/
DO
$$
    DECLARE
        -- users A:
        _random_a_uuid            UUID    := gen_random_uuid();
        _user_a_id                INT;
        _user_a_name              VARCHAR := 'test_user_a_' || _random_a_uuid;
        _user_a_email             VARCHAR := _user_a_name || '@test.com';

        -- users B:
        _random_b_uuid            UUID    := gen_random_uuid();
        _user_b_id                INT;
        _user_b_name              VARCHAR := 'test_user_b_' || _random_b_uuid;
        _user_b_email             VARCHAR := _user_b_name || '@test.com';

        -- users C:
        _random_c_uuid            UUID    := gen_random_uuid();
        _user_c_id                INT;
        _user_c_name              VARCHAR := 'test_user_c_' || _random_c_uuid;
        _user_c_email             VARCHAR := _user_c_name || '@test.com';


        -- Folders
        _resources_folder_a_id    INT;
        _folder_a_id              INT;
        _folder_a_name            VARCHAR := 'test_folder_' || _random_a_uuid || '_a';

        --
        _resources_folder_aa_1_id INT;
        _folder_aa_id             INT;
        _folder_aa_1_name         VARCHAR := 'test_folder_' || _random_a_uuid || '_aa_1';


    BEGIN
        RAISE NOTICE 'Running `resources_validate_authorization_trigger` tests';
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- Arrange: Create test users:
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_a_name, _user_a_email, gen_random_uuid())
            RETURNING id
                INTO _user_a_id;

               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_b_name, _user_b_email, gen_random_uuid())
            RETURNING id
                INTO _user_b_id;


               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_c_name, _user_c_email, gen_random_uuid())
            RETURNING id
                INTO _user_c_id;


            -- Create a parent folder resource -- no top level checks here as it top level
               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_user_a_id, _user_a_id, 'folder', NULL)
            RETURNING id INTO _resources_folder_a_id;

            -- Set `Admin` role for `_resources_folder_a_id` for user `_user_a_id`
            INSERT
              INTO virtual_file_system.public.user_role_resource (resource_id, user_id, role_id)
            VALUES (_resources_folder_a_id, _user_a_id, (
                SELECT id
                  FROM roles
                 WHERE name = 'admin'::ROLE_TYPE
                                                        ))
                ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

            -- Create root folder `_folder_a_name`
               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_a_id, _folder_a_name)
            RETURNING id INTO _folder_a_id;


            -- Test 1: Should raise exception when a user with missing authorization tries to perform a resource insert
            BEGIN
                INSERT
                  INTO resources (type, created_by, updated_by, parent_folder_id)
                VALUES ('folder', _user_b_id, _user_b_id, _resources_folder_a_id);

                RAISE EXCEPTION 'Auth validation did not raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE
                                    '% does not have write permissions for this folder or any parent folders' THEN
                    RAISE NOTICE 'Test 1 passed: "Should raise exception when a user with missing authorization tries to perform a resource insert" - Expected exception: %', sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 1 failed: "Should raise exception when a user with missing authorization tries to perform a resource insert" - Unexpected exception: %', sqlerrm;
                END IF;
            END;


        EXCEPTION
            WHEN OTHERS THEN --
                RAISE NOTICE 'Exception: %', sqlerrm;
            -- Ensure that the exception won't prevent execution of the cleanup section
        END;

        -- Cleanup
        DELETE FROM virtual_file_system.public.files f WHERE f.id = _folder_a_id;
        DELETE
          FROM virtual_file_system.public.user_role_resource urr
         WHERE urr.resource_id = _resources_folder_a_id
           AND urr.user_id = _user_a_id;
        DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_a_id;
        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_c_id;
        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_b_id;
        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_a_id;
        RAISE NOTICE 'Cleanup `resources_validate_authorization_trigger` tests data completed';
    END;
$$;
