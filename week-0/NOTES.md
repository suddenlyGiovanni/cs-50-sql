## SQL

SQL stands for "Structured Query Language". It is a language used to interact with databases, via which you
can`CREATE` | `READ` | `UPDATE` | `DELETE` data in a database.

### SQL Commands

given the 'longlist.db' based:

#### `SELECT`

enables to select what columns you want to see from a table.

```sqlite
-- select all columns from the table 'longlist'
SELECT *
FROM "longlist";
```

```sqlite
-- select the specified subset of columns from the table 'longlist'
SELECT "title", "author", "year"
FROM "longlist";
```

#### `LIMIT`

if a database had millions of rows, it might not make sense to select all of its rows. Instead, we might want
to merely take a peek at the data it contains. We use the SQL keyword `LIMIT` to specify the number of rows in the
query output.

```sqlite
SELECT *
FROM "longlist"
-- limit the number of rows to 10
LIMIT 10;
```

#### `WHERE`

the keyword `WHERE`  is used to select rows based on a condition; it will output the rows for which the specified
condition is true.

```sqlite
SELECT "title", "author"
FROM "longlist"
-- select rows where the column 'year' is equal to 2023
WHERE "year" = 2023;
```

Aside: the matching parameter needs to conform to the data type of the column; e.g. if the column is of type
`INTEGER`, you need to pass in an integer parameter.

##### WHERE predicates

the operators that can be used in SQL are

- `=` "equal to",
- `!=` | `<>` "not equal to"

```sqlite
SELECT "title", "format"
FROM "longlist"
-- Note that hardcover is in single quotes because it is an SQL string and not an identifier.
WHERE format != 'hardcover';
```

```sqlite
SELECT "title", "format"
FROM "longlist"
WHERE format <> 'hardcover';
```

Another way to do the same is to use the `NOT` keyword, as `NOT` negates a condition.

```sqlite
SELECT "title", "format"
FROM "longlist"
WHERE NOT format = 'hardcover';
```

To combine conditions, we can use the SQL keywords `AND` and `OR`. We can also use parentheses to indicate how to
combine the conditions in a compound conditional statement.

```sqlite
SELECT "title", "author", "year"
FROM "longlist"
WHERE "year" = 2022
-- where either condition is true, as in boolean logic.
   OR year = 2023;
```

```sqlite
SELECT "title", "author", "year"
FROM "longlist"
WHERE ("year" = 2022
  OR year = 2023)
--   where the previous condition and the new one has to be true at the same time.
  AND format != 'hardcover';
```

##### `NULL`

It is possible that tables may have missing data. `NULL` is a type used to indicate that certain data does not have
a valur,or does not exist in the table.

```sqlite
SELECT "title", "translator"
FROM "longlist"
WHERE "translator" IS NULL;
```

```sqlite
SELECT "title", "translator"
FROM "longlist"
WHERE "translator" IS NOT NULL;
```

#### `LIKE`

This keyword is used to select data that roughly matches the specified string. For example, `LIKE` could be used to
books that have a certain word or phrase in their title.

`LIKE` is combined with the operators

- `%` matches any characters around a given string
- `_` matches a single character

e.g. to select the book with the word "love" in their title, we can use

```sqlite
SELECT "title"
FROM "longlist"
-- matches the substring "love" where it can have any preceding or following characters
WHERE "title" LIKE '%love%';
```

| title                      |
|:---------------------------|
| Love in the Big City       |
| More Than I Love My Life   |
| Love in the New Millennium |
| Die, My Love               |
|                            |

E.G. to select the books whose title begin with "The", we can run

```sqlite
SELECT "title"
FROM "longlist"
-- this condition will return all the title starting with "The" but might also match title that begins with
-- "Their" or "They".
WHERE "title" LIKE 'The%';
```

| title                                 |
|:--------------------------------------|
| The Gospel According to the New World |
| The Birthday Party                    |
| The Book of Mother                    |
| The Books of Jacob                    |
| The War of the Poor                   |
| The Dangers of Smoking in Bed         |
| The Employees                         |
| The Pear Field                        |
| The Perfect Nine                      |
| The Adventures of China Iron          |

To only match titles starting with "The_" we need to include the whitespace in the filter...

```sqlite
SELECT "title"
FROM "longlist"
WHERE "title" LIKE 'The %';
```

Using the `_` single character wildcard enabled to match both title containing "Book" and "Books".

```sqlite
SELECT "title"
FROM "longlist"
WHERE title LIKE '%Book_%'
ORDER BY "title" ASC;
```

| title              |
|:-------------------|
| The Book of Mother |
| The Books of Jacob |

##### Ranges operators

```sqlite
SELECT title, year
FROM longlist
WHERE year = 2019
   OR year = 2020
   OR year = 2021
   OR year = 2022;
```

a query that is trying to match multiple condition of type range, can be express with the range operators

- `<`   less then
- `<=`  less or equal to
- `>`   greater
- `>=`  grater or equal to

```sqlite
SELECT title, year
FROM longlist
WHERE year >= 2019
  AND year <= 2022;
```

Another way to get the same results is using the keywords `BETWEEN` and `AND` to specify inclusive ranges. We can run

```sqlite
SELECT title, year
FROM longlist
WHERE year BETWEEN 2019 AND 2022;
```

```sqlite
SELECT title, rating, votes, pages
FROM longlist
WHERE rating > 4.0
  AND votes > 10000
  AND pages < 300;
```

| title                                 | rating | votes | pages |
|:--------------------------------------|:-------|:------|:------|
| When We Cease to Understand the World | 4.14   | 23251 | 192   |
| Hurricane Season                      | 4.08   | 22551 | 229   |
| The Years                             | 4.18   | 16888 | 232   |

#### `OREDER BY`

The `OREDER BY` keyword allows us to organize the returned rows in some specified order.

```sqlite
SELECT "title", "rating"
FROM "longlist"
-- omitting the ordering direction will default it to be in ascending order `ASC`
ORDER BY "rating"
LIMIT 10;
```

This gives us the 10 worst rated titles.

| title                                 | rating |
|:--------------------------------------|:-------|
| The Gospel According to the New World | 3.05   |
| The Pine Islands                      | 3.16   |
| Love in the New Millennium            | 3.17   |
| After the Sun                         | 3.25   |
| I Live in the Slums                   | 3.29   |
| The War of the Poor                   | 3.36   |
| An Inventory of Losses                | 3.36   |
| The Death of Murat Idrissi            | 3.36   |
| The Dinner Guest                      | 3.41   |
| Red Dog                               | 3.42   |

we can specify the ordering direction with `ASC` and `DESC`:

```sqlite
SELECT "title", "rating"
FROM "longlist"
ORDER BY "rating" DESC
LIMIT 10;
```

| title                                 | rating |
|:--------------------------------------|:-------|
| The Eighth Life                       | 4.52   |
| A New Name: Septology VI-VII          | 4.5    |
| The Other Name: Septology I-II        | 4.19   |
| The Years                             | 4.18   |
| Still Born                            | 4.14   |
| When We Cease to Understand the World | 4.14   |
| Elena Knows                           | 4.1    |
| The Flying Mountain                   | 4.1    |
| Hurricane Season                      | 4.08   |
| The Books of Jacob                    | 4.06   |

___

### Aggregate Functions (one output -> reduce)

`COUNT`, `AVG` , `MIN`, `MAX` and `SUM` are called aggregate functions and allows us to perform the corresponding
operations over multiple rows of data. By their very nature, each of the following aggregate function will return
only a single output - the aggregated value.

#### `AVG`

```sqlite
SELECT AVG("rating")
FROM longlist;
```

| AVG\("rating"\)   |
|:------------------|
| 3.753717948717949 |

`ROUND` off the number X to Y digits to the right of the decimal point. If the Y argument is omitted, 0 is assumed

```sqlite
SELECT ROUND(AVG("rating"), 2)
FROM longlist;
```

| ROUND\(AVG\("rating"\), 2\) |
|:----------------------------|
| 3.75                        |

to rename the column in which the results are displayed we can use the `AS` keyword

```sqlite
SELECT ROUND(AVG("rating"), 2) AS "average rating"
FROM longlist;
```

| average rating |
|:---------------|
| 3.75           |

#### `MAX`

to select the maximum rating in the database

```sqlite
SELECT MAX(rating) AS "maximum rating"
FROM longlist;
```

| maximum rating |
|:---------------|
| 4.52           |

#### `MIN`

to select the minimum rating in the database

```sqlite
SELECT MIN(rating) AS "minimum rating"
FROM longlist;
```

| minimum rating |
|:---------------|
| 3.05           |

#### `COUNT`

To count the total number of votes in the database

```sqlite
SELECT COUNT("votes")
FROM longlist;
```

| COUNT\("votes"\) |
|:-----------------|
| 78               |

To count the number of books in our database

```sqlite
SELECT COUNT(*)
FROM longlist;
```

| COUNT\(\*\) |
|:------------|
| 78          |

```sqlite
SELECT COUNT(translator)
FROM longlist;
```

| COUNT\(translator\) |
|:--------------------|
| 76                  |

We observe that the number of translators is fewer than the number of rows in the database. This is because the COUNT
function does not count NULL values.

by leveraging the `DISTINCT` keyword we are able to filter for only unique entries

```sqlite
SELECT COUNT(DISTINCT "publisher")
FROM longlist;
```

| COUNT\(DISTINCT publisher\) |
|:----------------------------|
| 33                          |
