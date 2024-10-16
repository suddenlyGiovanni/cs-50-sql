# Design Document

By [Giovanni Ravalico](https://github.com/suddenlyGiovanni)

Video overview: <URL HERE>

## Scope

In this section you should answer the following questions:

> [NOTE!] Scope Questions:
> 1. What is the purpose of your database?
> 2. Which people, places, things, etc. are you including in the scope of your database?
> 3. Which people, places, things, etc. are *outside* the scope of your database?

___

#### What is the purpose of your database?

A proof of concept for a Virtual File System (VFS)
build on top of a RDBMS to be used in the context of clouds application.

Prior history: [WinFS](https://en.wikipedia.org/wiki/WinFS) as an attempt to store data in a RDBMS.

#### Which people, places, things, etc. are you including in the scope of your database?

```text
Folder structure example:

  root/
  ├── folder1/
  │   ├── file1.txt
  │   ├── file2.md
  │   └── subfolder1/
  │       └── file3.json
  ├── folder2/
  │   └── subfolder2/
  │       ├── file4.csv
  │       └── file5.xml
  └── file6.jpg
```

As such, included in the database's scope is:

- Folder
- Files
- Users
- Permissions
- ~~ActivityLog~~

#### Which people, places, things, etc. are *outside* the scope of your database?

Multitenant support is out of the scope for this proof of concept database. And also the activity log.

## Functional Requirements

> [NOTE!] IMPLEMENT
>
> In this section, you should answer the following questions:
> * What should a user be able to do with your database?
> * What's beyond the scope of what a user should be able to do with your database?

### READ capabilities

As a User, GIVEN the correct permissions,

- I SHOULD be able to **QUERY**
	- the content of a folder at a specified path
    ```text
    ❯ ls ~/repos/courses/cs-50-sql/week-7/project
    Permissions Size User             Date Modified    Git Name
    .rw-r--r--@ 6.1k suddenlygiovanni 2024-10-09 17:37  -M  DESIGN.md
    .rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
    .rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql
    ```
	- the content of a file at a specified path
    ```text
    ❯ cat ~/repos/courses/cs-50-sql/week-7/project/DESIGN.md
    ```

IF I don't have the correct ownership and/or permissions to **VIEW
** a folder or a file content, THEN I should not be able to see any data.

### CREATE capabilities

- As a User, I should be able to **CREATE** a new `Folder` |
  `File` at an arbitrary path if I have the correct write permission;
  ```text
  cs-50-sql/week-7/project on  main [!]
  ❯ ls
  Permissions Size User             Date Modified    Git Name
  .rw-r--r--@ 3.3k suddenlygiovanni 2024-10-09 16:21  -M  DESIGN.md
  .rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
  .rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql

  ❯ touch foo_bar_baz.txt
  ❯ mkdir temp

  ❯ ls
  Permissions Size User             Date Modified    Git Name
  drwxr-xr-x@    - suddenlygiovanni 2024-10-09 17:16  --  temp/
  .rw-r--r--@ 5.8k suddenlygiovanni 2024-10-09 17:16  -M  DESIGN.md
  .rw-r--r--@    0 suddenlygiovanni 2024-10-09 17:16  -N  foo_bar_baz.txt
  .rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
  .rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql
  ```
  A `created event` should be recorded to the ActivityLogs with all the relevant transaction details
- IF my permissions are not enough, THEN the crate operation should be reverted.

### UPDATE capabilities

AS a User, GIVEN the correct permissions,

- I SHOULD be able to **UPDATE**
	- the name of the `Folder` | `File`
	  ```text
	  cs-50-sql/week-7/project on  main [!]
	  ❯ ls
	  Permissions Size User             Date Modified    Git Name
	  .rw-r--r--@ 3.3k suddenlygiovanni 2024-10-09 16:21  -M  DESIGN.md
	  .rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
	  .rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql

	  ❯ mv DESIGN.md NEW_DESIGN.md
	  ```
	- the content of the `File`

- I SHOULD be able to **MOVE** a `Folder` | `File`
  ```text
  cs-50-sql/week-7/project on  main [!]
  ❯ ls
  Permissions Size User             Date Modified    Git Name
  .rw-r--r--@ 3.3k suddenlygiovanni 2024-10-09 16:21  -M  DESIGN.md
  .rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
  .rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql

  ❯ mkdir temp
  ❯ mv DESIGN.md ./temp/DESIGN.md
  ❯ tree
  Permissions Size User             Date Modified Git Name
  drwxr-xr-x@    - suddenlygiovanni  9 Oct 16:48   -N  ./
  drwxr-xr-x@    - suddenlygiovanni  9 Oct 16:48   -N ├──  temp/
  .rw-r--r--@ 4.6k suddenlygiovanni  9 Oct 16:48   -N │  └──  DESIGN.md
  .rw-r--r--@   97 suddenlygiovanni  7 Oct  2023   -- ├──  queries.sql
  .rw-r--r--@  157 suddenlygiovanni  7 Oct  2023   -- └──  schema.sql
  ```

- I SHOULD be able to **CHANGE PERMISSION** for a `Folder` | `File`
  ```text
  cs-50-sql/week-7/project on  main [!]
  ❯ ls
  Permissions Size User             Date Modified    Git Name
  .rw-r--r--@ 3.3k suddenlygiovanni 2024-10-09 16:21  -M  DESIGN.md
  .rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
  .rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql

  ❯ chmod +x DESIGN.md

  ❯ ls
  Permissions Size User             Date Modified    Git Name
  .rwxr-xr-x@ 4.7k suddenlygiovanni 2024-10-09 16:59  -M  DESIGN.md*
  .rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
  .rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql
  ```

As a root User,

- I SHOULD be able to **CHANGE** the ownership of a `Folder` | `File`

For each update a `updated event` should be recorded to the ActivityLogs with all the relevant transaction details

### DELETE capabilities

As a root user, GIVEN my administrative permissions,

I SHOULD be able to **DELETE** any `Folder` | `File`

```text
cs-50-sql/week-7/project on  main [!]
❯ ls
Permissions Size User             Date Modified    Git Name
drwxr-xr-x@    - suddenlygiovanni 2024-10-09 17:16  --  temp/
.rw-r--r--@ 3.3k suddenlygiovanni 2024-10-09 16:21  -M  DESIGN.md
.rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
.rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql

❯ sudo rm DESIGN.md
❯ sudo rm -rf  ./temp

❯ ls
Permissions Size User             Date Modified    Git Name
.rw-r--r--@   97 suddenlygiovanni 2023-10-07 18:05  --  queries.sql
.rw-r--r--@  157 suddenlygiovanni 2023-10-07 18:05  --  schema.sql
```

A `deleted event` should be recorded to the ActivityLogs with all the relevant transaction details

## Representation

### Entities

In this section you should answer the following questions:

* Which entities will you choose to represent in your database?
* What attributes will those entities have?
* Why did you choose the types you did?
* Why did you choose the constraints you did?

Key Tables:

- **Users**: stores the information about users who interact with the VFS.
- **Permissions**: define access control for files and folders.
- **Files**: represents individual files with metadata such as the path, name, size, and the content (which is a URI that refers to a file in a storage bucket somewhere).
- **Folders**: Represents the directories containing files or other folders.
- ~~**ActivityLog**: Tracks all CRUD operations performed in the VFS.~~

#### Users

The `users` table stores the details about each user, such as:

- `id` , which specifies the unique ID for the user as an `INTEGER`. This column thus has the
  `PRIMARY KEY` constraint applied.
- `username`, which specifies the username as
  `TEXT`. It has also the constraint of having to be unique. It is also a good candidate for secondary index.
- `password`, hashed user password as `TEXT`
- `email`, which specifies the user's email as `TEXT`. it has to be unique

### Relationships

In this section you should include your entity relationship diagram and describe the relationships between the entities in your database.

```mermaid
erDiagram
    User {
        INTEGER user_id PK
        TEXT username UK "indexed"
        TEXT password
        TEXT email UK
        TEXT role "root | admin | user"
    }
```



```mermaid
---
title: Folder hierarchy structure
---
graph TB
    Folder_A --> Folder_B;
    Folder_A --> Folder_C
    Folder_B --> Folder_D;
```



```mermaid
erDiagram
    folder {
        INTEGER id PK
        TEXT name
        INTEGER parent_id FK
        INTEGER owner_id FK
    }
    folder ||--o| folder: "has zero or only one parent"
    folder |o--o{ folder: "have one or more children"
```


## Optimizations

In this section you should answer the following questions:

* Which optimizations (e.g., indexes, views) did you create? Why?

## Limitations

In this section you should answer the following questions:

* What are the limitations of your design?
* What might your database not be able to represent very well?


TODO: 
- [] Folders
- [] Folders
- [] Permissions
- [] Roles
- [] Users_resources
