/*
  Connect to the database "postgres" and execute the following as postgres superuser
*/

--Create user "test"
CREATE USER test
LOGIN ENCRYPTED PASSWORD 'secret'
VALID UNTIL 'infinity';

--Create database "pg_intro"
CREATE DATABASE pg_intro
  WITH ENCODING='UTF8'
       OWNER=test
       TEMPLATE=template_postgis
       CONNECTION LIMIT=-1;

/*
  Connect to the database "pg_intro" and execute the following as postgres superuser
*/

--Install extensions hstore and intarray
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS intarray;

--grant permissions on postgis tables to user test
GRANT ALL ON TABLE geometry_columns TO test;
GRANT ALL ON TABLE spatial_ref_sys TO test;