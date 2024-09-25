CREATE TABLE IF NOT EXISTS meteorites_temp (
  name      TEXT,
  id        TEXT,
  nametype  TEXT,
  class     TEXT,
  mass      TEXT,
  discovery TEXT,
  year      TEXT,
  lat       TEXT,
  long      TEXT
  );

.IMPORT --CSV --skip 1 meteorites.csv  "meteorites_temp"


CREATE TABLE IF NOT EXISTS meteorites (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,                      -- represents the unique ID of the meteorite.
  name      TEXT NOT NULL,                                          -- represents the given name of the meteorite.
  class     TEXT NOT NULL,                                          -- is the classification of the meteorite, according to the traditional classification scheme.
  mass      NUMERIC,                                                -- is the weight of the meteorite, in grams.
  discovery TEXT NOT NULL CHECK ( discovery IN ('Fell', 'Found') ), -- is either “Fell” or "Found". "Fell" indicates the meteorite was seen falling to Earth, whereas "Found" indicates the meteorite was found only after landing on Earth.
  year      INTEGER,                                                -- is the year in which the meteorite was discovered.
  lat       REAL,                                                   -- is the latitude at which the meteorite landed.
  long      REAL                                                    -- is the longitude at which the meteorite landed.
  );


INSERT INTO meteorites
  ( name, class, mass, discovery, year, lat, long )
SELECT t.name,
       t.class,
       ROUND(CAST(NULLIF(t.class, '') AS NUMERIC), 2),
       t.discovery,
       CAST(NULLIF(t.year, '') AS INTEGER),
       ROUND(CAST(NULLIF(t.lat, '') AS REAL), 2),
       ROUND(CAST(NULLIF(t.long, '') AS REAL), 2)
FROM meteorites_temp t
WHERE t.nametype NOT LIKE 'relict'
ORDER BY CAST(NULLIF(t.year, '') AS INTEGER) ASC, t.name ASC;


DROP TABLE IF EXISTS meteorites_temp;
