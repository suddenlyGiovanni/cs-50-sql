SELECT c.datetime, p.first_name, p.last_name, f.number, a.name, f."from", f.departure, f."to", f.arrival
FROM checkin          c
       JOIN flight    f ON f.id = c.flight_id
       JOIN passenger p ON p.id = c.passenger_id
       JOIN airline   a ON a.id = f.airline_id;


SELECT a.id, a.name
FROM airline                             a
       LEFT OUTER JOIN airline_concourse a_c ON a.id = a_c.airline_id
       JOIN            concourse         c ON a_c.concourse_name = c.name
GROUP BY a.id;
