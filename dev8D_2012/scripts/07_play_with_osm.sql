/*
  Exercise 3 - Play with OpenStreetMap
*/

/*
  Visually inspect and evaluate planet* tables through pgAdmin III
*/
--Have a closer look at planet_osm_point table:
SELECT *
FROM planet_osm_point
LIMIT 100;

--Can we find Dev8D conference venue? :)
SELECT
	name, ST_AsText(way), ST_AsgeoJSON(way), *
FROM planet_osm_point
WHERE name ILIKE '%university%' AND name ILIKE '%union%';

-- Check out available tags by using skeys() function (part of hstore extension)
SELECT
	DISTINCT skeys(tags)::varchar(200) AS tag
FROM planet_osm_point
ORDER BY tag;

-- There are loads of differnet tags but we are interested in OSM amenities, let's query available types:
SELECT
	DISTINCT amenity
FROM planet_osm_point
ORDER BY amenity;

--Look at OSM points through QGIS and try to overly boundary dataset
--Ha! OSM and boundaries don't sit on each other but why??
--Must be using different coordinate system but which? Use ST_SRID() to find out!
--ST_SRID(geom) - Returns the spatial reference identifier for the ST_Geometry as defined in spatial_ref_sys table http://www.postgis.org/docs/ST_SRID.html
SELECT
	DISTINCT ST_SRID(way)
FROM planet_osm_point;

--SRID/SRS=900913 stands for Google projection
--We need to apply coordinate transformation to align boundaries with OSM
--For this use function ST_Transform() http://www.postgis.org/docs/ST_Transform.html
--ST_Transform(geom, srid) - Returns a new geometry with its coordinates transformed to the SRID referenced by the integer parameter 
ALTER TABLE london DROP COLUMN IF EXISTS geom900913; 				--clean up
SELECT AddGeometryColumn('public','london','geom900913',900913,'POLYGON',2);	--register new geometry column

UPDATE london
SET geom900913 = ST_Transform(geom,900913); --reproject boundaries

--Go and view data in QGIS now!
