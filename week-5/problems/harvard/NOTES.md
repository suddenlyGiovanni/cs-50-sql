# Notes

## Find a student’s historical course enrollments, based on their ID:

```sqlite
EXPLAIN QUERY PLAN
SELECT courses.title, courses.semester
FROM enrollments
       JOIN courses ON enrollments.course_id = courses.id
       JOIN students ON enrollments.student_id = students.id
WHERE students.id = 3;
```

| id | parent | notused | detail                                              |
|:---|:-------|:--------|:----------------------------------------------------|
| 4  | 0      | 0       | SEARCH students USING INTEGER PRIMARY KEY (rowid=?) |
| 7  | 0      | 0       | SCAN enrollments                                    |
| 13 | 0      | 0       | SEARCH courses USING INTEGER PRIMARY KEY (rowid=?)  |

optimizing the enrollment index

```sqlite
CREATE INDEX IF NOT EXISTS enrollments_student_id_index ON enrollments (student_id);
```

| id | parent | notused | detail                                                                     |
|:---|:-------|:--------|:---------------------------------------------------------------------------|
| 5  | 0      | 0       | SEARCH students USING INTEGER PRIMARY KEY (rowid=?)                        |
| 8  | 0      | 0       | SEARCH enrollments USING INDEX enrollments_student_id_index (student_id=?) |
| 14 | 0      | 0       | SEARCH courses USING INTEGER PRIMARY KEY (rowid=?)                         |

___

## Find all students who enrolled in Computer Science 50 in Fall 2023:

```sqlite
EXPLAIN QUERY PLAN
SELECT id, name
FROM students
WHERE id IN (
              SELECT student_id
              FROM enrollments
              WHERE course_id = (
                                  SELECT id
                                  FROM courses
                                  WHERE courses.department = 'Computer Science'
                                    AND courses.number = 50
                                    AND courses.semester = 'Fall 2023'
                                )
            );
```

| id | parent | notused | detail                                              |
|:---|:-------|:--------|:----------------------------------------------------|
| 2  | 0      | 0       | SEARCH students USING INTEGER PRIMARY KEY (rowid=?) |
| 6  | 0      | 0       | LIST SUBQUERY 2                                     |
| 8  | 6      | 0       | SCAN enrollments                                    |
| 13 | 6      | 0       | SCALAR SUBQUERY 1                                   |
| 17 | 13     | 0       | SCAN courses                                        |

optimizing the courses subquery

```sqlite
CREATE INDEX IF NOT EXISTS courses_index ON courses (number, semester);
```

| id | parent | notused | detail                                                                   |
|:---|:-------|:--------|:-------------------------------------------------------------------------|
| 2  | 0      | 0       | SEARCH students USING INTEGER PRIMARY KEY (rowid=?)                      |
| 6  | 0      | 0       | LIST SUBQUERY 2                                                          |
| 9  | 6      | 0       | SEARCH enrollments USING INDEX enrollments_course_id_index (course_id=?) |
| 12 | 6      | 0       | SCALAR SUBQUERY 1                                                        |
| 17 | 12     | 0       | SEARCH courses USING INDEX courses_index (number=? AND semester=?)       |

___

## Sort courses by most- to least-enrolled in Fall 2023:

```sqlite
EXPLAIN QUERY PLAN
SELECT courses.id, courses.department, courses.number, courses.title, COUNT(*) AS enrollment
FROM courses
       JOIN enrollments ON enrollments.course_id = courses.id
WHERE courses.semester = 'Fall 2023'
GROUP BY courses.id
ORDER BY enrollment DESC;
```

| id | parent | notused | detail                                                                            |
|:---|:-------|:--------|:----------------------------------------------------------------------------------|
| 8  | 0      | 0       | SCAN courses                                                                      |
| 12 | 0      | 0       | SEARCH enrollments USING COVERING INDEX enrollments_course_id_index (course_id=?) |
| 47 | 0      | 0       | USE TEMP B-TREE FOR ORDER BY                                                      |

optimizing the `courses` table by adding an index to the semester which we know it could be of the following type

```typescript
type Quarter = 'Fall' | 'Spring'
type Semester = `${Quarter} {number}`
```

```sqlite
DROP INDEX IF EXISTS courses_semester_index;
CREATE INDEX IF NOT EXISTS courses_semester_index ON courses (semester);
```

| id | parent | notused | detail                                                                            |
|:---|:-------|:--------|:----------------------------------------------------------------------------------|
| 9  | 0      | 0       | SEARCH courses USING INDEX courses_semester_index (semester=?)                    |
| 14 | 0      | 0       | SEARCH enrollments USING COVERING INDEX enrollments_course_id_index (course_id=?) |
| 49 | 0      | 0       | USE TEMP B-TREE FOR ORDER BY                                                      |

___

## Find all computer science courses taught in Spring 2024:

```sqlite
EXPLAIN QUERY PLAN
SELECT courses.id, courses.department, courses.number, courses.title
FROM courses
WHERE courses.department = 'Computer Science' AND courses.semester = 'Spring 2024';
```
