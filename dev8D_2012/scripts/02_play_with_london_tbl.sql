/*
  Exercise 1 - Play with table "london"
*/

/*
Add column "bbox" for bounding boxes:
	Docs:		http://www.postgis.org/docs/AddGeometryColumn.html
	SYNOPSIS: 	AddGeometryColumn(varchar catalog_name, varchar schema_name, varchar table_name, varchar column_name, integer srid, varchar type, integer dimension);
	EXAMPLE: 	SELECT AddGeometryColumn ('my_schema','my_spatial_table','the_geom',4326,'POINT',2);
*/
ALTER TABLE london DROP COLUMN IF EXISTS bbox; --clean up
SELECT AddGeometryColumn ('public','london','bbox',27700,'POLYGON',2);

--Calculate "bbox" values with function ST_Envelope() http://www.postgis.org/docs/ST_Envelope.html
--ST_Envelope(geometry g1) — Returns a geometry representing the double precision (float8) bounding box of the supplied geometry
UPDATE london
SET bbox = ST_Envelope(geom);

--View bbox with QGIS (external)



--Add column centroid for center points
ALTER TABLE london DROP COLUMN IF EXISTS centroid; --clean up
SELECT AddGeometryColumn ('public','london','centroid',27700,'POINT',2);

--Calculate centroid values with function ST_PointOnSurface() http://www.postgis.org/docs/ST_PointOnSurface.html
--ST_PointOnSurface(geometry g1) - Returns a POINT guaranteed to lie on the surface.
UPDATE london
SET centroid = ST_PointOnSurface(geom);

--View centroid with QGIS (external)

--Some more fancy stuff:
--Dissolve all London polygons in one uniform polygon with ST_Union() http://www.postgis.org/docs/ST_Union.html
--ST_Union(geometry set g1field) - Returns a geometry that represents the point set union of the 
DROP TABLE IF EXISTS london_all; --clean up first if needed
CREATE TABLE london_all(
	id serial,
	name text
); --create new table
SELECT AddGeometryColumn ('public','london_all','geom',27700,'POLYGON',2); --add geom column

INSERT INTO london_all(geom, name)
SELECT ST_Union(geom), 'London' FROM london; --insert dissolved london polygon

