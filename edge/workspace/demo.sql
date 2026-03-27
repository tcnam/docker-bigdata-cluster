show databases;
drop database raw;

create database raw;
CREATE DATABASE IF NOT EXISTS raw;
create database com;
create database cur;
SELECT * FROM (VALUES (1, 'test'), (2, 'demo')) AS t(id, name);
EXPLAIN EXTENDED SELECT * FROM your_table;

drop table if exists raw.regions_spark;
drop table if exists raw.regions_hive;
drop table if exists raw.regions_delta;


--SET spark.sql.dialect;
CREATE TABLE raw.regions_spark( 
	region_id      string,       
    region_name    string,
    table_type		string
)
USING PARQUET; -- Uses Spark's native vectorized reader;

-- Create a Delta table
CREATE TABLE raw.regions_delta ( 
	region_id      string,       
    region_name    string,
    table_type		string
) USING DELTA;

CREATE TABLE raw.regions_hive( 
	region_id      string,       
    region_name    string,
    table_type		string
)
COMMENT 'User information table'
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
STORED AS TEXTFILE;



DESCRIBE EXTENDED raw.regions_spark;
describe extended raw.regions_hive;

INSERT INTO raw.regions_spark VALUES 
    ('1', 'Europe', 'spark'),
    ('2', 'Americas', 'spark'),
    ('3', 'Asia', 'spark'),
    ('4', 'Middle East and Africa', 'spark');

INSERT INTO raw.regions_hive VALUES 
    ('1', 'Europe', 'hive'),
    ('2', 'Americas', 'hive'),
    ('3', 'Asia', 'hive'),
    ('4', 'Middle East and Africa', 'hive');



-- Try an operation that only Delta supports
INSERT INTO raw.regions_delta VALUES 
    ('1', 'Europe', 'delta'),
    ('2', 'Americas', 'delta'),
    ('3', 'Asia', 'delta'),
    ('4', 'Middle East and Africa', 'delta')
;

DELETE FROM raw.regions_delta WHERE region_id = '1';

select *
from raw.regions_spark
union all
select *
from raw.regions_hive
union all
select *
from raw.regions_delta;

-- Check the history (A classic Delta feature)
DESCRIBE HISTORY raw.test_delta;

DESCRIBE TABLE EXTENDED raw.test_delta;
DESCRIBE TABLE EXTENDED database_name.table_name;