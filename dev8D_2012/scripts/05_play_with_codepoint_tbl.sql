/*
  Exercise 2 - Play with table "codepoint"
*/

--Add column centroid for points
ALTER TABLE codepoint DROP COLUMN IF EXISTS centroid; --clean up
SELECT AddGeometryColumn ('public','codepoint','centroid',27700,'POINT',2);

--Create centroids with ST_MakePoint() http://www.postgis.org/docs/ST_MakePoint.html
--ST_MakePoint(double precision x, double precision y) - Creates a 2D point geometry
--ST_SetSRID(geometry geom, integer srid) - Sets the SRID on a geometry to a particular integer value ( http://www.postgis.org/docs/ST_SetSRID.html
UPDATE codepoint
SET centroid = ST_SetSRID( --MUST set spatial reference system!! 27700 - for OSGB36
	ST_MakePoint(
		eastings, --x
		northings --y
	), 27700);

--View metadata of British national coorinate system (OSGB36, EPSG:27700)
SELECT * FROM spatial_ref_sys WHERE srid = 27700;

--Add spatial index to speed up queries
CREATE INDEX codepoint_centroid_gist
  ON codepoint
  USING gist
  (centroid);

--Physically reorder all the data rows in the same order as the index criteria, this will create performance advantages for reads
--http://www.postgis.org/docs/ch06.html#id2635907
CLUSTER codepoint_centroid_gist ON codepoint; 

--View postcodes with QGIS (external)



