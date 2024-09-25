-- Ingredients
-- We certainly need to keep track of our ingredients.
-- Some of the typical ingredients we use include flour, yeast, oil, butter, and several different types of sugar.
-- Moreover, we would love to keep track of the price we pay per unit of ingredient (whether it’s pounds, grams, etc.).
DROP TABLE IF EXISTS ingredient;
CREATE TABLE ingredient (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT    NOT NULL, -- ingredient name (e.g. flour, yeast, oil, butter, sugar)
  unit_price NUMERIC NOT NULL, -- price per unit (e.g. $5.00)
  unit       TEXT    NOT NULL  -- unit type (e.g. pounds, grams, etc. )
  );


-- Donuts
-- We’ll need to include our selection of donuts, past and present!
-- For each donut on the menu, we’d love to include three things:
-- * The name of the donut
-- * Whether the donut is gluten-free
-- * The price per donut,
-- * Oh, and it’s important that we be able to look up the ingredients for each of the donuts!
DROP TABLE IF EXISTS donut;
CREATE TABLE donut (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  unit_price  NUMERIC NOT NULL,
  gluten_free INTEGER CHECK ( gluten_free IN (FALSE, TRUE) ) DEFAULT FALSE
  );

DROP TABLE IF EXISTS donut_ingredient;
CREATE TABLE donut_ingredient (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  donut_id      INTEGER NOT NULL,
  ingredient_id INTEGER NOT NULL,
  FOREIGN KEY (donut_id) REFERENCES donut (id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredient (id)
  );


-- Orders
--
-- We love to see customers in person, though we realize a good number of people might order online nowadays.
-- We’d love to be able to keep track of those online orders.
-- We think we would need to store:
--
-- * An order number, to keep track of each order internally
-- * All the donuts in the order
-- * The customer who placed the order. We suppose we could assume only one customer places any given order.

DROP TABLE IF EXISTS "order";
CREATE TABLE "order" (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  order_number INTEGER NOT NULL DEFAULT 1, -- An order number, to keep track of each order internally
  customer_id  INTEGER NOT NULL,           -- The customer who placed the order
  UNIQUE (customer_id, order_number),
  CONSTRAINT positive_order_number CHECK ( order_number >= 0 ),
  FOREIGN KEY (customer_id) REFERENCES customer (id)
  );

DROP TABLE IF EXISTS order_item;
CREATE TABLE order_item (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  donut_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL CHECK ( quantity > 0 ) DEFAULT 1,
  FOREIGN KEY (order_id) REFERENCES "order" (id),
  FOREIGN KEY (donut_id) REFERENCES donut (id)
  );


-- Customers,
-- Oh, and we realize it would be lovely to keep track of some information about each of our customers.
-- We’d love to remember the history of the orders they’ve made.
-- In that case, we think we should store:
--
-- * A customer’s first and last name
-- * A history of their orders
DROP TABLE IF EXISTS customer;
CREATE TABLE customer (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT NOT NULL,
  last_name  TEXT NOT NULL
  --  no history is necessary as it can be computed by querying all the customer id orders
  );
