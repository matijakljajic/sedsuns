-- Pokrenuti kao SYSTEM nad FREEPDB1.
-- Kreira posebne tablespace-ove kako projektne tabele ne bi bile smeštene u SYSTEM.

DECLARE
  l_tablespace_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_tablespace_count
    FROM dba_tablespaces
   WHERE tablespace_name = 'SEDS_OLTP_DATA';

  IF l_tablespace_count = 0 THEN
    EXECUTE IMMEDIATE q'[
      CREATE TABLESPACE seds_oltp_data
        DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/seds_oltp_data01.dbf'
        SIZE 512M
        AUTOEXTEND ON NEXT 128M
        MAXSIZE 4G
    ]';
  END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE USER seds_oltp
      IDENTIFIED BY SEDS_OLTP
      DEFAULT TABLESPACE seds_oltp_data
      TEMPORARY TABLESPACE temp
      QUOTA UNLIMITED ON seds_oltp_data
  ]';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1920 THEN
      RAISE;
    END IF;
END;
/

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE
  TO seds_oltp;

DECLARE
  l_tablespace_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_tablespace_count
    FROM dba_tablespaces
   WHERE tablespace_name = 'SEDS_DW_DATA';

  IF l_tablespace_count = 0 THEN
    EXECUTE IMMEDIATE q'[
      CREATE TABLESPACE seds_dw_data
        DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/seds_dw_data01.dbf'
        SIZE 512M
        AUTOEXTEND ON NEXT 128M
        MAXSIZE 4G
    ]';
  END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE USER seds_dw
      IDENTIFIED BY SEDS_DW
      DEFAULT TABLESPACE seds_dw_data
      TEMPORARY TABLESPACE temp
      QUOTA UNLIMITED ON seds_dw_data
  ]';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1920 THEN
      RAISE;
    END IF;
END;
/

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE MATERIALIZED VIEW, CREATE SEQUENCE, CREATE PROCEDURE
  TO seds_dw;
