DROP INDEX IF EXISTS enrollments_student_id_index;
DROP INDEX IF EXISTS enrollments_course_id_index;


DROP INDEX IF EXISTS courses_department_semester_index;

DROP INDEX IF EXISTS satisfies_course_id_index;

VACUUM;
