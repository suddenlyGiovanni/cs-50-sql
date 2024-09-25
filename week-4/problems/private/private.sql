DROP TABLE IF EXISTS cypher;
CREATE TABLE IF NOT EXISTS cypher (
  sentence_number  INTEGER NOT NULL,
  character_number INTEGER NOT NULL,
  message_length   INTEGER NOT NULL,
  message          TEXT    NOT NULL,
  PRIMARY KEY (sentence_number, character_number, message_length)
  );

INSERT INTO cypher
  ( sentence_number, character_number, message_length, message )
VALUES
  ( 14,   98, 4,  (
                    SELECT SUBSTRING(sentence, 98, 4)
                    FROM sentences
                    WHERE id = 14
                  ) ),
  ( 114,  3,  5,  (
                    SELECT SUBSTRING(sentence, 3, 5)
                    FROM sentences
                    WHERE id = 114
                  ) ),
  ( 618,  72, 9,  (
                    SELECT SUBSTRING(sentence, 72, 9)
                    FROM sentences
                    WHERE id = 618
                  ) ),
  ( 630,  7,  3,  (
                    SELECT SUBSTRING(sentence, 7, 3)
                    FROM sentences
                    WHERE id = 630
                  ) ),
  ( 932,  12, 5,  (
                    SELECT SUBSTRING(sentence, 12, 5)
                    FROM sentences
                    WHERE id = 932
                  ) ),
  ( 2230, 50, 7,  (
                    SELECT SUBSTRING(sentence, 50, 7)
                    FROM sentences
                    WHERE id = 2230
                  ) ),
  ( 2346, 44, 10, (
                    SELECT SUBSTRING(sentence, 44, 10)
                    FROM sentences
                    WHERE id = 2346
                  ) ),
  ( 3041, 14, 5,  (
                    SELECT SUBSTRING(sentence, 14, 5)
                    FROM sentences
                    WHERE id = 3041
                  ) );

DROP VIEW message;
CREATE VIEW message AS
SELECT c.message AS phrase
FROM cypher c;


-- SELECT phrase
-- FROM message;
