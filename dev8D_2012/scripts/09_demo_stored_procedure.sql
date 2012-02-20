CREATE OR REPLACE FUNCTION find_nearest_amenity(x double precision, y double precision, amenity text)
RETURNS refcursor AS
$BODY$
/*
--Let's find and use coordinates of Dev8D venue and see what are our nearest amenities
SELECT
	name::varchar(200), ST_AsText(way)::varchar(200) , ST_AsText(ST_Transform(way, 4326))::varchar(200)
FROM planet_osm_point
WHERE name ILIKE '%university%' AND name ILIKE '%union%';

Example:
	SELECT find_nearest_amenity(-0.1311228, 51.5225802, 'pub');
	FETCH ALL FROM ref;

	SELECT find_nearest_amenity(-0.1311228, 51.5225802, 'restaurant');
	FETCH ALL FROM ref;

	SELECT find_nearest_amenity(-0.1311228, 51.5225802, 'atm');
	FETCH ALL FROM ref;

	SELECT find_nearest_amenity(-0.1311228, 51.5225802, 'bicycle_parking');
	FETCH ALL FROM ref;

	SELECT find_nearest_amenity(-0.1311228, 51.5225802, 'supermarket');
	FETCH ALL FROM ref;

	SELECT find_nearest_amenity(-0.1311228, 51.5225802, 'hotel');
	FETCH ALL FROM ref;
	
*/

DECLARE
	v_myref		REFCURSOR	:='ref';
	v_loc_geom	GEOMETRY;
	v_loc_geog	GEOMETRY;
	
BEGIN
	v_loc_geom = ST_SetSRID(ST_Point(x,y),4326);				--construct geometry from lat lon input
	
	RAISE INFO 'Location: %', St_AsText(v_loc_geom);

	v_loc_geog = CAST(v_loc_geom AS GEOGRAPHY);
	
	OPEN v_myref FOR
	SELECT
		a.osm_id, a.name, a.amenity, a.operator,
		ST_X(a.geom) AS lat, ST_Y(a.geom) AS lon, 			--another 2 PostGIS functions ST_X() and ST_Y()
		ST_Distance(v_loc_geog, a.geog) AS dist_m,			--ST_Distance()
		tags
	FROM amenity a
	WHERE
		( a.amenity = $3 OR $3 = ANY (avals(a.tags)) )
		AND ST_DWithin(v_loc_geog, a.geog, 500)
	ORDER BY dist_m ASC
	LIMIT 10;
	
RETURN v_myref;

END;$BODY$
  LANGUAGE 'plpgsql';




