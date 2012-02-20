/*
  This table was created manually based on files code-point-open-column-headers.csv, wc.csv
  Note, PostgreSQL will lowercase all names by default unless you enclose them in double quotes!
*/

DROP TABLE IF EXISTS codepoint; --remove this table if it exists (clean-up)
CREATE TABLE codepoint(
   Postcode varchar,
   Positional_quality_indicator int,
   Eastings int,
   Northings int,
   Country_code varchar,
   NHS_regional_HA_code varchar,
   NHS_HA_code varchar,
   Admin_county_code varchar,
   Admin_district_code varchar,
   Admin_ward_code varchar
);