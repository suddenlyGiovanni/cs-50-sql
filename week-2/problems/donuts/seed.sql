INSERT INTO ingredient
  ( name, unit, unit_price )
VALUES
  ( 'Cocoa',      'pound', 5.00 ),
  ( 'Sugar',      'pound', 2.00 ),
  ( 'Flour',      'pound', 0    ),
  ( 'Buttermilk', 'pound', 0    ),
  ( 'Sprinkles',  'pound', 0    );

-- ___


BEGIN TRANSACTION;
INSERT INTO donut
  ( name, unit_price, gluten_free )
VALUES
  ( 'Belgian Dark Chocolate', 4.00, FALSE );

WITH donut_id AS (
                   SELECT d.id
                   FROM donut d
                   WHERE d.name = 'Belgian Dark Chocolate'
                 ),
     ingredient_ids AS (
                   SELECT id FROM ingredient WHERE name IN ('Cocoa', 'Flour', 'Buttermilk', 'Sugar')
                 )
INSERT
INTO donut_ingredient
  ( donut_id, ingredient_id )
SELECT (
         SELECT id
         FROM donut_id
       ),
       id
FROM ingredient_ids;
END;


BEGIN TRANSACTION;
INSERT INTO donut
  ( name, unit_price, gluten_free )
VALUES
  ( 'Back-To-School Sprinkles', 4.00, FALSE );

WITH donut_id AS (
                   SELECT d.id
                   FROM donut d
                   WHERE d.name = 'Back-To-School Sprinkles'
                 ),
     ingredient_ids AS (
                   SELECT id FROM ingredient WHERE name IN ('Flour', 'Buttermilk', 'Sugar', 'Sprinkles')
                 )
INSERT
INTO donut_ingredient
  ( donut_id, ingredient_id )
SELECT (
         SELECT id
         FROM donut_id
       ),
       id
FROM ingredient_ids;
END;

--  ___

BEGIN TRANSACTION;
INSERT INTO customer
  ( first_name, last_name )
VALUES
  ( 'Luis', 'Singh' );


INSERT INTO "order"
  ( customer_id, order_number )
VALUES
  ( (
      SELECT c.id FROM customer c WHERE c.first_name = 'Luis' AND c.last_name = 'Singh'
    ), 1 );



WITH order_id AS (
                   SELECT o.id
                   FROM "order" o
                   WHERE order_number = 1 AND
                         customer_id = (
                                         SELECT c.id
                                         FROM customer c
                                         WHERE c.first_name = 'Luis' AND c.last_name = 'Singh'
                                       )
                 )
INSERT
INTO order_item
  ( order_id, donut_id, quantity )
VALUES
  ( (
      SELECT id
      FROM order_id
    ), (
         SELECT d.id
         FROM donut d
         WHERE d.name = 'Belgian Dark Chocolate'
       ), 3 ),
  ( (
      SELECT id
      FROM order_id
    ), (
         SELECT d.id
         FROM donut d
         WHERE d.name = 'Back-To-School Sprinkles'
       ), 2 );

END TRANSACTION;
