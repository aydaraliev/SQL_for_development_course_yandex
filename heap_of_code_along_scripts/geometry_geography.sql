CREATE EXTENSION PostGIS;

SELECT PostGIS_full_version();

SELECT ST_GeomFromText('LINESTRING(-5 0, -4 4, -2 -4, 1 2, 12 0)');

SELECT ST_GeomFromText('LINESTRING(-3 5, 2 5, -3 1, 2 1, -3 -4 )');

SELECT '010500000003000000010200000002000000000000000000'
           '14C0000000000000104000000000000014C0000000000000'
           '10C001020000000200000000000000000014C00000000000'
           '00000000000000000000C000000000000000000102000000'
           '0500000000000000000000C0000000000000104000000000'
           '000000400000000000001040000000000000004000000000'
           '000010C000000000000000C000000000000010C000000000'
           '000000C00000000000001040'::geometry;

SELECT ST_GeomFromText('POLYGON(
    (0 0, 0 10, 6 10, 6 0, 0 0),
    (0.5 0.5, 0.5 5, 5.5 5, 5.5 0.5, 0.5 0.5),
    (0.5 5.5, 0.5 9.5, 5.5 9.5, 5.5 5.5, 0.5 5.5)
)');

SELECT ST_GeomFromText('MULTILINESTRING((-4 4, -4 -4, 4 4, 4 -4), (-1 5, 1 5))');

SELECT ST_GeomFromText(
               'MULTIPOLYGON(
                   ((30 20, 45 40, 10 40, 30 20)),
                   ((15 5, 40 10, 10 20, 5 10, 15 5))
               )');

CREATE TABLE my_geodata
(
    id    SERIAL PRIMARY KEY,
    place TEXT,
    gm    GEOMETRY,
    gg    GEOGRAPHY
);

INSERT INTO my_geodata (place, gg, gm)
VALUES ('Moscow Kremlin',
        'POINT(37.617330 55.750997)',
        'POINT(37.617330 55.750997)');

SELECT *
FROM my_geodata;

SELECT id,
       place,
       ST_AsText(gm) geometry_text,
       ST_AsText(gg) geography_text
FROM my_geodata;

INSERT INTO my_geodata (place, gg, gm)
VALUES (NULL,
        'LINESTRING(-73.99945 40.708231, -73.9937 40.703676)',
        'LINESTRING(-73.99945 40.708231, -73.9937 40.703676)');

SELECT *
FROM my_geodata
WHERE id = 2;

UPDATE my_geodata
SET place = 'Brooklyn Bridge, New-York'
WHERE id = 2;

INSERT INTO my_geodata (place, gg, gm)
VALUES (NULL,
        'POLYGON((
         37.6180 55.7545,
         37.6215 55.7526,
         37.6225 55.7535,
         37.6190 55.7552,
         37.6180 55.7545
         ))',
        'POLYGON((
         37.6180 55.7545,
         37.6215 55.7526,
         37.6225 55.7535,
         37.6190 55.7552,
         37.6180 55.7545
         ))');

SELECT *
FROM my_geodata
WHERE id = 3;

UPDATE my_geodata
SET place = 'Red square, Moscow'
WHERE id = 3;

SELECT ST_GeomFromGeoJSON('
    {"type": "Point",
     "coordinates": [39.88223925980441,59.22361416209884]}
');