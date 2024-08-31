/* 1. Вы работаете над историческим проектом «Кремли России». Ваша задача — создать
   таблицу kremlins, в которой будет три столбца:
    id — первичный ключ, автоинкремент, тип integer.
    name — обязательное текстовое поле, с уникальными названиями объектов. Данные должны
           проверяться на уникальность.
    point — обязательное поле с типом данных geometry, ограниченным до точек и SRID = 4326. */

CREATE TABLE kremlins
(
    id    SERIAL PRIMARY KEY,
    name  TEXT                  NOT NULL UNIQUE,
    point geometry(POINT, 4326) NOT NULL
);

/* 2. Коллега прислал вам данные для проекта «Кремли России» в формате GeoJSON. Они находятся
   в прекоде. Ваша задача — вставить данные в таблицу kremlins, которую вы создали в
   предыдущем задании. */

DO
$$
    DECLARE
        json_data    JSON := '{
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {"name": "Kazan Kremlin"},
          "geometry": {
            "coordinates": [
              49.106086,
              55.799176
            ],
            "type": "Point"
          }
        }
      ]
    }';
        feature      JSON;
        feature_name TEXT;
        coordinates  JSON;
        longitude    FLOAT8;
        latitude     FLOAT8;
    BEGIN
        feature := (json_data -> 'features')::json -> 0;
        feature_name := feature -> 'properties' ->> 'name';
        coordinates := feature -> 'geometry' -> 'coordinates';
        longitude := (coordinates ->> 0)::FLOAT8;
        latitude := (coordinates ->> 1)::FLOAT8;
        INSERT INTO kremlins (name, point)
        VALUES (feature_name, ST_SetSRID(ST_Point(longitude, latitude), 4326));
    END
$$;

/* 3. Из внешнего источника вы получили новые данные для проекта «Кремли России». Они пришли
с другим SRID, чем у вас в таблице. Вставьте данные таким образом, чтобы они корректно
считывались и отображались на карте в pgAdmin в нужном месте. */

-- Zaraysk Kremlin
-- 'SRID=3857;POINT(4327175.14880196 7314886.348288048)'

INSERT INTO kremlins (name, point)
VALUES ('Zaraysk Kremlin',
        ST_Transform(ST_SetSRID(ST_Point(4327175.14880196, 7314886.348288048),
                                3857), 4326));

/* 4. База данных продолжает наполняться. На этот раз пришли данные из Нижнего Новгорода,
с ними всё нормально и нет никаких хитростей. Коллега-фронтендер попросил прислать ему
координаты этого кремля в формате GeoJSON, чтобы он смог поработать с ним на веб-интерфейсе.
Напишите запрос для вставки данных, который вернёт столбец point в формате GeoJSON. */

-- Nizhny Novgorod Kremlin
-- POINT(44.003760539 56.328624716)

WITH inserted AS (
    INSERT INTO kremlins (name, point)
        VALUES ('Nizhny Novgorod Kremlin', ST_SetSRID(
                ST_Point(44.003760539, 56.328624716), 4326))
        RETURNING point)
SELECT ST_AsGeoJSON(point) AS geojson_point
FROM inserted;
