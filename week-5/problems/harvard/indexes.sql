CREATE INDEX IF NOT EXISTS enrollments_student_id_index ON enrollments (student_id);
CREATE INDEX IF NOT EXISTS enrollments_course_id_index ON enrollments (course_id);

CREATE INDEX IF NOT EXISTS courses_department_semester_index ON courses (semester, department);

CREATE INDEX IF NOT EXISTS satisfies_course_id_index ON satisfies (course_id);
