-- =====================================================
-- Hive Metastore
-- =====================================================

CREATE ROLE hive
WITH
    LOGIN
    PASSWORD 'hive';

CREATE DATABASE metastore
    OWNER hive
    ENCODING 'UTF8';

GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;


-- =====================================================
-- Airflow
-- =====================================================

CREATE ROLE airflow
WITH
    LOGIN
    PASSWORD 'airflow';

CREATE DATABASE airflow
    OWNER airflow
    ENCODING 'UTF8';

GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;