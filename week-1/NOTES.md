```sqlite
SELECT id AS "MacLehose Press publisher_id"
FROM publishers
WHERE publisher = 'MacLehose Press';
```

| MacLehose Press publisher_id |
|:-----------------------------|
| 12                           |

```sqlite
SELECT title AS "titles published by MacLehose Press"
FROM books
WHERE publisher_id = 12;
```

| titles published by MacLehose Press |
|:------------------------------------|
| Standing Heavy                      |
| Jimi Hendrix Live in Lviv           |
| An Inventory of Losses              |
| The Faculty of Dreams               |
| The Shape of the Ruins              |
| The Impostor                        |
| Vernon Subutex 1                    |

___

## Subqueries

now lets make it dynamic by making nesting one query in the other one;

```sqlite
SELECT title
FROM books
WHERE publisher_id = (SELECT id
                      FROM publishers
                      WHERE publisher = 'MacLehose Press');
```

| title                     |
|:--------------------------|
| Standing Heavy            |
| Jimi Hendrix Live in Lviv |
| An Inventory of Losses    |
| The Faculty of Dreams     |
| The Shape of the Ruins    |
| The Impostor              |
| Vernon Subutex 1          |

To find all the avg ratings for the book In Memory of Memory

```sqlite
SELECT ROUND(AVG(rating), 1)
FROM ratings
WHERE book_id = (SELECT id
                 FROM books
                 WHERE title = 'In Memory of Memory');
```

```sqlite
SELECT authors.name
FROM authors
WHERE id = (SELECT authored.author_id
            FROM authored
            WHERE book_id = (SELECT books.id
                             FROM books
                             WHERE books.title = 'Flights'));

```

```sqlite
SELECT authors.name
FROM authors
WHERE authors.id = (SELECT authored.author_id
                    FROM authored
                    WHERE authored.author_id = (SELECT books.id
                                                FROM books
                                                WHERE books.title = 'The Birthday Party'));

```

in order to get to the information that we want, we are forced to compute all subqueries not leveraging directry the
constraints imposed by the tables foreign keys...

## `IN`

This keyword is used to check whether the desired value is in a given list or set of values.
The relationship between authors and books is many-to-many. This means that it is possible a given author has
written more than one book. To find the names of all bools in the database written bt Fernanda Melchor, we would use
the `IN` keywords as follows.

```sqlite

SELECT title
FROM books
WHERE id IN (SELECT book_id
             FROM authored
             WHERE author_id = (SELECT id
                                FROM authors
                                WHERE name = 'Fernanda Melchor'));

```

## `JOIN`

this keyword allows us to combine two or more tables together.

```sqlite
SELECT *
FROM sea_lions;
```

| id    | name  | species                |
|:------|:------|:-----------------------|
| 10484 | Ayah  | Zalophus californianus |
| 11728 | Spot  | Zalophus californianus |
| 11729 | Tiger | Zalophus californianus |
| 11732 | Mabel | Zalophus californianus |
| 11734 | Rick  | Zalophus californianus |
| 11790 | Jolee | Zalophus californianus |

```sqlite
SELECT *
FROM migrations;
```

| id    | distance | days |
|:------|:---------|:-----|
| 10484 | 1000     | 107  |
| 11728 | 1531     | 56   |
| 11729 | 1370     | 37   |
| 11732 | 1622     | 62   |
| 11734 | 1491     | 58   |
| 11735 | 2723     | 82   |
| 11736 | 1571     | 52   |
| 11737 | 1957     | 92   |

and using an inner join

```sqlite
SELECT *
FROM sea_lions
       INNER JOIN migrations
                  ON migrations.id = sea_lions.id;
```

| id    | name  | species                | id    | distance | days |
|:------|:------|:-----------------------|:------|:---------|:-----|
| 10484 | Ayah  | Zalophus californianus | 10484 | 1000     | 107  |
| 11728 | Spot  | Zalophus californianus | 11728 | 1531     | 56   |
| 11729 | Tiger | Zalophus californianus | 11729 | 1370     | 37   |
| 11732 | Mabel | Zalophus californianus | 11732 | 1622     | 62   |
| 11734 | Rick  | Zalophus californianus | 11734 | 1491     | 58   |

the `ON` keyword is used to specifyed which value match between the table being joined.

### Kinds of Joins

##### `LEFT JOIN`

```sqlite
SELECT *
FROM sea_lions
       LEFT OUTER JOIN migrations ON migrations.id = sea_lions.id;
```

| id    | name  | species                | id    | distance | days |
|:------|:------|:-----------------------|:------|:---------|:-----|
| 10484 | Ayah  | Zalophus californianus | 10484 | 1000     | 107  |
| 11728 | Spot  | Zalophus californianus | 11728 | 1531     | 56   |
| 11729 | Tiger | Zalophus californianus | 11729 | 1370     | 37   |
| 11732 | Mabel | Zalophus californianus | 11732 | 1622     | 62   |
| 11734 | Rick  | Zalophus californianus | 11734 | 1491     | 58   |
| 11790 | Jolee | Zalophus californianus | null  | null     | null |

notice how Jolee 11790 is included in the new joined table even if it didn't appear in the "migrations" table;

#### `RIGHT JOIN`

```sqlite
SELECT *
FROM sea_lions RIGHT OUTER JOIN migrations
ON migrations.id = sea_lions.id;
```

| id    | name  | species                | id    | distance | days |
|:------|:------|:-----------------------|:------|:---------|:-----|
| 10484 | Ayah  | Zalophus californianus | 10484 | 1000     | 107  |
| 11728 | Spot  | Zalophus californianus | 11728 | 1531     | 56   |
| 11729 | Tiger | Zalophus californianus | 11729 | 1370     | 37   |
| 11732 | Mabel | Zalophus californianus | 11732 | 1622     | 62   |
| 11734 | Rick  | Zalophus californianus | 11734 | 1491     | 58   |
| null  | null  | null                   | 11735 | 2723     | 82   |
| null  | null  | null                   | 11736 | 1571     | 52   |
| null  | null  | null                   | 11737 | 1957     | 92   |

#### `FULL JOIN`

A `FULL JOIN` merges both tables keeping all values even if they do not match on the on condition.

```sqlite
SELECT *
FROM sea_lions FULL OUTER JOIN migrations
ON migrations.id = sea_lions.id;
```

| id    | name  | species                | id    | distance | days |
|:------|:------|:-----------------------|:------|:---------|:-----|
| 10484 | Ayah  | Zalophus californianus | 10484 | 1000     | 107  |
| 11728 | Spot  | Zalophus californianus | 11728 | 1531     | 56   |
| 11729 | Tiger | Zalophus californianus | 11729 | 1370     | 37   |
| 11732 | Mabel | Zalophus californianus | 11732 | 1622     | 62   |
| 11734 | Rick  | Zalophus californianus | 11734 | 1491     | 58   |
| 11790 | Jolee | Zalophus californianus | null  | null     | null |
| null  | null  | null                   | 11735 | 2723     | 82   |
| null  | null  | null                   | 11736 | 1571     | 52   |
| null  | null  | null                   | 11737 | 1957     | 92   |

#### `NATURAL JOIN`

```sqlite
SELECT *
FROM sea_lions
       NATURAL JOIN migrations;
```

___

### Sets and Groups;

the return of a sql query is called a result.

```sqlite
SELECT name
FROM translators;
```

```sqlite
SELECT name
FROM authors;
```

operators:

- `<left>` `UNION` `<right>`
  as the sum of two distinct sets.
  e.g. Authors `UNION` Translators translate to something like

```sqlite
SELECT name
FROM translators
UNION
SELECT name
FROM authors
```

```sqlite
SELECT 'author' AS "profession", name
FROM authors
UNION
SELECT 'translator' AS "profession", name
FROM translators
ORDER BY name ASC
LIMIT 10;
```

| profession | name                 |
|:-----------|:---------------------|
| author     | Adania Shibli        |
| translator | Adrian Nathan West   |
| author     | Ahmed Saadawi        |
| author     | Alia Trabucco Zerán  |
| translator | Alison L. Strayer    |
| author     | Amanda Svensson      |
| author     | Andrey Kurkov        |
| author     | Andrzej Tichy        |
| translator | Angela Rodel         |
| translator | Aniruddhan Vasudevan |

- `<left>`  `INTERSECT` `<right>`
  as intersection of two sets; it returns a subset of all the values that belongs to both sets.
  e.g. Authors `INTERSECT` Translators translates to something like: all authors that are also translators and vice
  versa.

```sqlite
SELECT name
FROM authors
INTERSECT
SELECT name
FROM translators;
```

| name              |
|:------------------|
| Ngũgĩ wa Thiong'o |

- `<left>` `EXCLUDE` `<right>`

```sqlite
SELECT name
FROM authors
EXCEPT
SELECT name
FROM translators;
```

the result excludes "Ngũgĩ wa Thiong'o" as it belongs to both translator and author;

```sqlite
SELECT book_id
FROM translated
WHERE translator_id = (SELECT id
                       FROM translators
                       WHERE name = "Sophie Hughes");
```

```sqlite
SELECT books.title AS "title worked by both Sophie Hughes' and Margaret Jull Costa "
FROM books
WHERE books.id = (SELECT translated.book_id
                  FROM translated
                  WHERE translated.translator_id = (SELECT id
                                                    FROM translators
                                                    WHERE translators.name = 'Sophie Hughes')
                  INTERSECT
                  SELECT translated.book_id
                  FROM translated
                  WHERE translated.translator_id = (SELECT id
                                                    FROM translators
                                                    WHERE translators.name = 'Margaret Jull Costa'))
```

| title worked by both Sophie Hughes' and Margaret Jull Costa |
|:------------------------------------------------------------|
| Mac and His Problem                                         |

___

### `GROUP BY`

```sqlite
SELECT AVG(ratings.rating)
FROM ratings;
```

| AVG\(ratings.rating\) |
|:----------------------|
| 3.8364408869644953    |

```sqlite
SELECT book_id, ROUND(AVG(rating), 2) AS "Avarage rating"
FROM ratings
GROUP BY ratings.book_id
LIMIT 10;
```

| book\_id | Avarage rating |
|:---------|:---------------|
| 1        | 3.77           |
| 2        | 3.97           |
| 3        | 3.04           |
| 4        | 3.57           |
| 5        | 4.06           |
| 6        | 3.76           |
| 7        | 3.64           |
| 8        | 3.82           |
| 9        | 4              |
| 10       | 4.04           |

```sqlite
SELECT book_id, ROUND(AVG(rating), 2) AS "average rating"
FROM ratings
GROUP BY ratings.book_id
HAVING "Avarage rating" > 4.0
ORDER BY "average rating" DESC
LIMIT 10;
```

| book\_id | average rating |
|:---------|:---------------|
| 42       | 4.51           |
| 22       | 4.5            |
| 45       | 4.19           |
| 65       | 4.18           |
| 28       | 4.14           |
| 11       | 4.14           |
| 71       | 4.11           |
| 18       | 4.09           |
| 48       | 4.08           |
| 5        | 4.06           |

```sqlite
SELECT book_id, COUNT(rating)
FROM ratings
GROUP BY ratings.book_id
```
