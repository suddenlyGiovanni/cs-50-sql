SET search_path TO virtual_file_system, public;

/*
*  Unit test for ownership assignment on valid resource creation
*/
DO
$$
    DECLARE
        -- users A:
        _random_a_uuid          UUID    := gen_random_uuid();
        _user_a_id              INT;
        _user_a_name            VARCHAR := 'test_user_a_' || _random_a_uuid;
        _user_a_email           VARCHAR := _user_a_name || '@test.com';


        -- Folders
        _resources_folder_a_id  INT;
        _folder_a_id            INT;
        _folder_a_name          VARCHAR := 'test_folder_' || _random_a_uuid || '_a';
        _resources_folder_aa_id INT;
        _folder_aa_id           INT;
        _folder_aa_name         VARCHAR := 'test_folder_' || _random_a_uuid || '_aa';


    BEGIN
        RAISE NOTICE 'Running `resources_ownership_assignment_trigger` tests';
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- Arrange: Create test users:
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_a_name, _user_a_email, gen_random_uuid())
            RETURNING id
                INTO _user_a_id;


            -- Create a parent folder resource -- no top level checks here as it top level
               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_user_a_id, _user_a_id, 'folder', NULL)
            RETURNING id INTO _resources_folder_a_id;


            IF exists(
                SELECT 1
                  FROM virtual_file_system.public.user_role_resource urr
                 WHERE urr.resource_id = _resources_folder_a_id
                   AND urr.user_id = _user_a_id
                   AND urr.role_id = (
                     SELECT roles.id
                       FROM roles
                      WHERE roles.name = 'admin'
                                     )
                     ) THEN
                RAISE NOTICE 'Test 1 pass: "Should automatically assign a `admin` to the user creating a new root resource"';
            ELSE
                RAISE NOTICE 'Test 1 failed: "Should automatically assign a `admin` to the user creating a new root resource"';
            END IF;


            -- Set `Admin` role for `_resources_folder_a_id` for user `_user_a_id`
            -- INSERT
            --   INTO virtual_file_system.public.user_role_resource (resource_id, user_id, role_id)
            -- VALUES (_resources_folder_a_id, _user_a_id, (
            --     SELECT id
            --       FROM roles
            --      WHERE name = 'admin'::ROLE_TYPE
            --                                             ))
            --     ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;


            -- Create root folder `_folder_a_name`
               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_a_id, _folder_a_name)
            RETURNING id INTO _folder_a_id;


            -- Test 1: Should automatically assign a `owner` to the user creating a new resource
            BEGIN
                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('folder', _user_a_id, _user_a_id, _resources_folder_a_id)
                RETURNING id INTO _resources_folder_aa_id;

                   INSERT
                     INTO folders (resource_id, name)
                   VALUES (_resources_folder_aa_id, _folder_aa_name)
                RETURNING id INTO _folder_aa_id;

                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.user_role_resource urr
                     WHERE urr.resource_id = _resources_folder_aa_id
                       AND urr.user_id = _user_a_id
                       AND urr.role_id = (
                         SELECT roles.id
                           FROM roles
                          WHERE roles.name = 'owner'
                                         )
                         ) THEN
                    RAISE NOTICE 'Test 1 pass: "Should automatically assign a `owner` to the user creating a new resource"';
                ELSE
                    RAISE NOTICE 'Test 1 failed: "Should automatically assign a `owner` to the user creating a new resource"';
                END IF;
            END;


        EXCEPTION
            WHEN OTHERS THEN --
                RAISE NOTICE 'Exception: %', sqlerrm;
            -- Ensure that the exception won't prevent execution of the cleanup section
        END;

        -- Tear down: Cleanup test data
        BEGIN
            DELETE FROM virtual_file_system.public.files f WHERE f.id = _folder_aa_id;
            DELETE FROM virtual_file_system.public.files f WHERE f.id = _folder_a_id;
            DELETE
              FROM virtual_file_system.public.user_role_resource urr
             WHERE urr.resource_id = _resources_folder_aa_id
               AND urr.user_id = _user_a_id;
            DELETE
              FROM virtual_file_system.public.user_role_resource urr
             WHERE urr.resource_id = _resources_folder_a_id
               AND urr.user_id = _user_a_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_aa_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_a_id;
            DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_a_id;
            RAISE NOTICE 'Cleanup `resources_ownership_assignment_trigger` test data completed';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
        END;
    END;
$$;
