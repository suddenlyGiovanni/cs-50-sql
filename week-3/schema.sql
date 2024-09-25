-- The Boston MFA (Museum of Fine Arts)
DROP TABLE IF EXISTS collections;
CREATE TABLE IF NOT EXISTS collections (
  id               INTEGER PRIMARY KEY AUTOINCREMENT, -- The table contains an ID which serves as the primary key.
  title            TEXT NOT NULL,                     -- the title for a piece of artwork
  accession_number TEXT NOT NULL UNIQUE,              -- accession_number which is a unique ID used by the museum internally.
  acquired         TEXT                               -- date indicating when the art was acquired.
    CONSTRAINT valid_acquired_date_format CHECK ( acquired ISNULL OR
                                                  acquired GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]')
  );


DROP TABLE IF EXISTS artists;
CREATE TABLE IF NOT EXISTS artists (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
  );


DROP TABLE IF EXISTS created;
CREATE TABLE IF NOT EXISTS created (
  artist_id     INTEGER NOT NULL,
  collection_id INTEGER NOT NULL,
  PRIMARY KEY (artist_id, collection_id),
  FOREIGN KEY (artist_id) REFERENCES artists (id)
    ON DELETE CASCADE,
  FOREIGN KEY (collection_id) REFERENCES collections (id)
    ON DELETE CASCADE
  );
