# Problem to Solve

If you’re not already familiar, Harvard has a course shopping tool called my.harvard, with which students explore
(and ultimately register for!) classes. To keep track of courses, students, and their registrations, my.harvard
presumably uses some kind of underlying database. And yet, if you’ve ever used it, you’ll know that my.harvard isn’t
especially… quick.

Here’s your chance to make my.harvard just a little bit faster!
In this problem, take some Harvard course data and create indexes to speed up typical queries on the database.
Keep in mind that indexing every column isn’t always the best solution: you’ll need to consider trade-offs in terms of
space and time, ultimately representing Harvard’s courses and students in the most efficient way possible.

## Schema

```mermaid
erDiagram
  Student }o--|{ Course: "enrolls in"
  Course }|--o{ Requirement: "satisfies"
```

#### `students` table

| name | type    | constraint  | comment                      |
|------|---------|-------------|------------------------------|
| id   | INTEGER | PRIMARY KEY | which is the student’s ID.   |
| name | TEXT    | NOT NULL    | which is the student’s name. |

#### `courses` table

| name       | type    | constraint  | comment                                                                                                      |
|------------|---------|-------------|--------------------------------------------------------------------------------------------------------------|
| id         | INTEGER | PRIMARY KEY | which is the courses’s ID.                                                                                   |
| department | TEXT    | NOT NULL    | which is the department in which the course is taught (e.g., “Computer Science”, “Economics”, “Philosophy”). |
| number     | INTEGER | NOT NULL    | which is the course number (e.g., 50, 12, 330).                                                              |
| semester   | TEXT    | NOT NULL    | which is the semester in which the class was taught (e.g., “Spring 2024”, “Fall 2023”).                      |
| title      | TEXT    | NOT NULL    | which is the title of the course (e.g., “Introduction to Computer Science”).                                 |

#### `enrollments` table

| name       | type    | constraint  | comment                                                         |
|------------|---------|-------------|-----------------------------------------------------------------|
| id         | INTEGER | PRIMARY KEY | which is the ID to identify the enrollment.                     |
| student_id | INTEGER | FOREIGN KEY | which is the ID of the student enrolled.                        |
| course_id  | INTEGER | FOREIGN KEY | which is the ID of the course in which the student is enrolled. |

#### `requirements` table

| name | type    | constraint  | comment                               |
|------|---------|-------------|---------------------------------------|
| id   | INTEGER | PRIMARY KEY | which is the ID of the requirement.   |
| name | INTEGER | NOT NULL    | which is the name of the requirement. |

#### `satisfies` table

| name           | type    | constraint  | comment                                                              |
|----------------|---------|-------------|----------------------------------------------------------------------|
| id             | INTEGER | PRIMARY KEY | which is the ID of the course-requirement pair.                      |
| course_id      | INTEGER | FOREIGN KEY | which is the ID of a given course.                                   |
| requirement_id | INTEGER | FOREIGN KEY | which is the ID of the requirement which the given course satisfies. |

## Specification

In `indexes.sql`, write a set of SQL statements that create indexes which will speed up typical queries on the
`harvard.db` database. The number of indexes you create, as well as the columns they include, is entirely up to you.
Be sure to balance speed with disk space, only creating indexes you need.

When engineers optimize a database, they often care about the typical queries run on the database.
Such queries highlight patterns with which a database is accessed, thus revealing the best columns and tables on which
to create indexes.
