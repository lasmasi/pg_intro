REM --- EXERCISE 3 - Import OpenStreetMap file london_small.osm ---

REM *** 1: Going to the sample data folder "data" ***
pause
cd ..\data\

REM *** 2: Load file london_small.osm with osm2pgsql tool, please adjust path to the file "default.style"  ***
pause
osm2pgsql --create --database pg_intro --username test --password --host localhost --port 5432 --style ..\install\osm2pgsql\default.style --merc --hstore --slim london_small.osm

REM --- TABLE LOADED! ---
pause

