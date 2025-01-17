INSERT INTO collections
  ( title, accession_number, acquired )
VALUES
  ( 'Farmers working at dawn', '11.6152', '1911-08-03' ),
  ( 'Imaginative landscape',   '56.496',  NULL         ),
  ( 'Profusion of flowers',    '56.257',  '1956-04-12' ),
  ( 'Spring outing',           '14.76',   '1914-01-08' );


INSERT INTO artists
  ( name )
VALUES
  ( 'Li Yin'              ),
  ( 'Qian Weicheng'       ),
  ( 'Unidentified artist' ),
  ( 'Zhou Chen'           );



INSERT INTO created
  ( artist_id, collection_id )
VALUES
  ( (
      SELECT id
      FROM artists
      WHERE name = 'Li Yin'
    ), (
         SELECT id
         FROM collections
         WHERE title = 'Imaginative landscape'
       ) ),
  ( (
      SELECT id
      FROM artists
      WHERE name = 'Qian Weicheng'
    ), (
         SELECT id
         FROM collections
         WHERE title = 'Profusion of flowers'
       ) ),
  ( (
      SELECT id
      FROM artists
      WHERE name = 'Unidentified artist'
    ), (
         SELECT id
         FROM collections
         WHERE title = 'Farmers working at dawn'
       ) ),
  ( (
      SELECT id
      FROM artists
      WHERE name = 'Zhou Chen'
    ), (
         SELECT id
         FROM collections
         WHERE title = 'Spring outing'
       ) );
