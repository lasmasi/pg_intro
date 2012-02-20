REM --- EXERCISE 1 - Import ESRI Shapefile greater_london_const_region.shp ---

REM *** 1: Going to the sample data folder ***
pause
cd ..\data\bline\



REM *** 2: Show shp2pgsql help ***
pause
shp2pgsql



REM *** 3: Generate basic SQL file from ESRI shapefile greater_london_const_region.shp***
pause
shp2pgsql greater_london_const_region.shp london>london_data.sql
REM *Generate SQL file from ESRI shapefile with spatial reference system EPSG:27700, geometry column "geom" as simple geometries with geometry index
REM shp2pgsql -s 27700 -I -S -g geom greater_london_const_region.shp london>london_data.sql
REM *Load SQL file to db
REM psql -h localhost -p 5432 -U test -d pg_intro -f london_data.sql



REM *** 4: Delete table "london" if it exists ***
pause
psql -h localhost -p 5432 -U test -d pg_intro -c "DROP TABLE IF EXISTS london"



REM *** 5: Convert SHP to SQL and pipe it into the database ***
pause
shp2pgsql -s 27700 -I -S -g geom greater_london_const_region.shp london | psql -h localhost -p 5432 -U test pg_intro



REM --- TABLE LOADED! ---
pause

