/*
  Exercise 4 - Demo app "POIs" (Points of Interest)
  Build data & query backend for GPS enabled mobile device to answer user's questions about the nearest POI, e.g. pub, caffee, atm etc.
  Workflow:
	Extract and sort all amenities from OSM tables and sort them according to type
	BUild stored procedure for querying data
*/


/*
  Clean database from old tables where exists
*/
DROP TABLE IF EXISTS amenity CASCADE;
DROP TABLE IF EXISTS amenity_drink CASCADE;
DROP TABLE IF EXISTS amenity_food CASCADE;
DROP TABLE IF EXISTS amenity_cash CASCADE;
DROP TABLE IF EXISTS amenity_other CASCADE;
DELETE FROM geometry_columns WHERE f_table_name LIKE 'amenity%'; --alternatively use postgis function: SELECT dropgeometrytable('amenity');



/*
  Create parent table "amenities" for all extracted POIs
*/
CREATE TABLE amenity (
	osm_id integer,
	amenity text,
	name text,
	operator text,
	tags hstore,
	geog GEOGRAPHY,			--GEOGRAPHY is similar to lat, lon but support mesurements in metric units
	CONSTRAINT amenity_pkey PRIMARY KEY (osm_id)
);
-- Create and register geometry column
SELECT addgeometrycolumn('', 'public', 'amenity', 'geom', 4326, 'GEOMETRY', 2);


/* 
  Create child tables of "amenities" table to seperate out some specific POIs: drinks, foods, cash
  Child tables allow as to partition data and could speed up queries on large datasets
*/
CREATE TABLE amenity_drink(
	CONSTRAINT amenity_drink_pkey PRIMARY KEY (osm_id),
	CONSTRAINT amenity_drink_amenity_check CHECK (amenity = ANY (ARRAY['cafe', 'bar', 'pub']))
) INHERITS (amenity);

CREATE TABLE amenity_food(
	CONSTRAINT amenity_food_pkey PRIMARY KEY (osm_id),
	CONSTRAINT amenity_food_amenity_check CHECK (amenity = ANY (ARRAY['restaurant', 'fast_food', 'pub']))
) INHERITS (amenity);

CREATE TABLE amenity_cash(
	CONSTRAINT amenity_cash_pkey PRIMARY KEY (osm_id),
	CONSTRAINT amenity_cash_amenity_check CHECK (amenity = ANY (ARRAY['atm', 'bank']))
) INHERITS (amenity);

CREATE TABLE amenity_other(
	CONSTRAINT amenity_other_pkey PRIMARY KEY (osm_id),
	CONSTRAINT amenity_cash_amenity_check CHECK (amenity != ANY (ARRAY['cafe', 'bar', 'pub','restaurant', 'fast_food', 'atm', 'bank']))
) INHERITS (amenity);


/*
  Register individual geometry columns
*/
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
    VALUES ('', 'public', 'amenity_drink', 'geom', 2, 4326, 'GEOMETRY');
INSERT INTO geometry_columns VALUES ('', 'public', 'amenity_food', 'geom', 2, 4326, 'GEOMETRY');
INSERT INTO geometry_columns VALUES ('', 'public', 'amenity_cash', 'geom', 2, 4326, 'GEOMETRY');
INSERT INTO geometry_columns VALUES ('', 'public', 'amenity_other', 'geom', 2, 4326, 'GEOMETRY');



/*
  Create spatial index on geometry column
*/
CREATE INDEX amenity_drink_gist ON amenity_drink USING gist(geom);
CREATE INDEX amenity_food_gist ON amenity_food USING gist(geom);
CREATE INDEX amenity_cash_gist ON amenity_cash USING gist(geom);
CREATE INDEX amenity_other_gist ON amenity_other USING gist(geom);

/*
  Create index on tags column
*/
CREATE INDEX amenity_drink_tags_idx ON amenity_drink USING gist(tags);
CREATE INDEX amenity_food_tags_idx ON amenity_food USING gist(tags);
CREATE INDEX amenity_cash_tags_idx ON amenity_cash USING gist(tags);
CREATE INDEX amenity_other_tags_idx ON amenity_other USING gist(tags);

/*
  Index values in the column "amenity"
*/
CREATE INDEX amenity_other_amenity_idx ON amenity_other USING btree(amenity);


/*
  We can create a trigger function that will automatically sort new data and stick rows in one of "amenities" child tables
*/
CREATE OR REPLACE FUNCTION tg_amenity_insert()
	RETURNS trigger AS
$$
/* Purpose: divert amenity inserts to relevant tables */
BEGIN
	RAISE INFO 'NEW ID: %', NEW.osm_id;
	
	IF NEW.amenity IN ('cafe', 'bar', 'pub') THEN
		INSERT INTO amenity_drink(osm_id, amenity, "name", "operator", tags, geog, geom)
		SELECT osm_id, amenity, "name", "operator", tags, CAST(geom AS GEOGRAPHY), geom
		FROM (SELECT NEW.*) AS foo
		WHERE 1 NOT IN (SELECT 1 FROM amenity WHERE osm_id=NEW.osm_id); --avoid duplicate inserts
		
	ELSIF NEW.amenity IN ('atm', 'bank') THEN
		INSERT INTO amenity_cash(osm_id, amenity, "name", "operator", tags, geog, geom)
		SELECT osm_id, amenity, "name", "operator", tags, CAST(geom AS GEOGRAPHY), geom
		FROM (SELECT NEW.*) AS foo
		WHERE 1 NOT IN (SELECT 1 FROM amenity WHERE osm_id=NEW.osm_id); --avoid duplicate inserts

	ELSIF NEW.amenity IN ('restaurant', 'fast_food') THEN
		INSERT INTO amenity_food(osm_id, amenity, "name", "operator", tags, geog, geom)
		SELECT osm_id, amenity, "name", "operator", tags, CAST(geom AS GEOGRAPHY), geom
		FROM (SELECT NEW.*) AS foo
		WHERE 1 NOT IN (SELECT 1 FROM amenity WHERE osm_id=NEW.osm_id); --avoid duplicate inserts
		
	ELSE
		INSERT INTO amenity_other(osm_id, amenity, "name", "operator", tags, geog, geom)
		SELECT osm_id, amenity, "name", "operator", tags, CAST(geom AS GEOGRAPHY), geom
		FROM (SELECT NEW.*) AS foo
		WHERE 1 NOT IN (SELECT 1 FROM amenity WHERE osm_id=NEW.osm_id); --avoid duplicate inserts
	END IF;

	RETURN NULL; --cancel original insert
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

/*
  Attach trigger function to the table "amenity"
*/
CREATE TRIGGER tg_amenity_insert BEFORE INSERT
ON amenity FOR EACH ROW
EXECUTE PROCEDURE tg_amenity_insert();



/*
  LOAD DATA
  Grab POIs from OSM tables and pipe them to amenities tables
*/
-- 'cafe', 'bar', 'pub'
INSERT INTO amenity(
	osm_id, amenity, "name", "operator", tags,
	geom)
SELECT
	osm_id, amenity, name, operator, tags,
	ST_Transform(ST_Transform(way, 27700),4326) AS geom				--transform to lat lon
	--ST_Transform(way, 4326) AS geom						--transform to lat lon
	--, ST_AsText(ST_Transform(way, 4326)) AS geomtext 				--show human readable format
FROM planet_osm_point
WHERE
	((tags->'amenity') IN ('cafe', 'bar', 'pub'));

-- 'atm', 'bank'
INSERT INTO amenity(
	osm_id, amenity, "name", "operator", tags,
	geom)
SELECT
	osm_id, amenity, name, operator, tags,
	ST_Transform(ST_Transform(way, 27700),4326) AS geom	--transform to lat lon
	--ST_Transform(way, 4326) AS geom			--transform to lat lon
	--, ST_AsText(ST_Transform(way, 4326)) AS geomtext 	--show human readable format
FROM planet_osm_point
WHERE ((tags->'amenity') IN ('atm', 'bank'));

-- 'restaurant', 'fast_food'
INSERT INTO amenity(
	osm_id, amenity, "name", "operator", tags,
	geom)
SELECT
	osm_id, amenity, name, operator, tags,
	ST_Transform(ST_Transform(way, 27700),4326) AS geom	--transform to lat lon
	--ST_Transform(way, 4326) AS geom			--transform to lat lon
	--, ST_AsText(ST_Transform(way, 4326)) AS geomtext 	--show human readable format
FROM planet_osm_point
WHERE
((tags->'amenity') IN ('restaurant', 'fast_food'))
OR
((tags->'food') = 'yes');

-- Or just do it all in one go and let the trigger sort data!
INSERT INTO amenity(
	osm_id, amenity, "name", "operator", tags,
	geom)
SELECT osm_id, amenity, name, operator, tags,
	ST_Transform(ST_Transform(way, 27700),4326) AS geom	--transform to lat lon
	--ST_Transform(way, 4326) AS geom	
FROM planet_osm_point;

/*
  At the end you should always gather table statistics to assist internal query planning and performance
  Execute one by one!
*/
/*
VACUUM ANALYZE VERBOSE amenity;
VACUUM ANALYZE VERBOSE amenity_drink;
VACUUM ANALYZE VERBOSE amenity_food;
VACUUM ANALYZE VERBOSE amenity_cash;
VACUUM ANALYZE VERBOSE amenity_other;
*/


