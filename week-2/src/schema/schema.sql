-- Deletes prior tables if they exist


CREATE TABLE cards
(
	id INTEGER,
	PRIMARY KEY (id)
);


CREATE TABLE stations
(
	id   INTEGER,
	-- name of the station
	name TEXT NOT NULL UNIQUE,
	-- name of the line
	line TEXT NOT NULL,
	PRIMARY KEY (id)
);


CREATE TABLE swipes
(
	id         INTEGER,
	-- the relation to riders
	card_id    INTEGER,
	-- the relation to stations
	station_id INTEGER,
	type       TEXT    NOT NULL CHECK ( type IN ('enter', 'exit', 'deposit') ),
	datetime   NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
	amount     NUMERIC NOT NULL CHECK ( amount != 0 ),
	PRIMARY KEY (id),
	FOREIGN KEY (station_id) REFERENCES stations (id),
	FOREIGN KEY (card_id) REFERENCES cards (id)
);
