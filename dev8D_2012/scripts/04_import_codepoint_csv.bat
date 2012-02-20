REM --- EXERCISE 2 - Import CSV File wc.csv ---

REM *** 1: Create table "cpoint" from prepared SQL file ***
pause
psql -h localhost -p 5432 -U test -d pg_intro -f 03_create_codepoint_tbl.sql


REM *** 2: Going to the sample data folder "codepoint" ***
pause
cd ..\data\codepoint\

REM *** 3: Load file wc.csv in to the table "codepoint" ***
psql -h localhost -p 5432 -U test -d pg_intro -c "\copy codepoint FROM 'wc.csv' WITH CSV"

REM --- TABLE LOADED! ---
pause

