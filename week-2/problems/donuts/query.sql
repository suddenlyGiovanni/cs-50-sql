SELECT i.*
FROM ingredient i;

-- look up donut_name = 'Belgian Dark Chocolate' | 'Back-To-School Sprinkles'
SELECT i.name
FROM donut                        d
       JOIN main.donut_ingredient di ON di.donut_id = d.id
       JOIN main.ingredient       i ON i.id = di.ingredient_id
WHERE d.name = :donut_name;


SELECT concat_ws(' ', c.first_name, c.last_name) AS name, o.order_number, d.name, i.quantity
FROM "order"                o
       JOIN main.order_item i ON i.order_id = o.id
       JOIN main.donut      d ON d.id = i.donut_id
       JOIN main.customer   c ON c.id = o.customer_id
WHERE c.first_name = 'Luis' AND c.last_name = 'Singh';
