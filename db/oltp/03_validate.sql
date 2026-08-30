-- Run as SEDS_OLTP against FREEPDB1 after db/oltp/02_load.sh.
-- Expected row counts are derived from the supplied CSV shards, excluding headers.

WHENEVER SQLERROR EXIT SQL.SQLCODE

SET PAGESIZE 200
SET LINESIZE 160
SET FEEDBACK ON

PROMPT === Row-count validation ===

WITH expected_counts (table_name, expected_rows) AS (
  SELECT 'GRAD',                 5       FROM dual UNION ALL
  SELECT 'BIBLIOTEKA',           5       FROM dual UNION ALL
  SELECT 'ODELJENJE',            15      FROM dual UNION ALL
  SELECT 'TIP_PUBLIKACIJE',      2       FROM dual UNION ALL
  SELECT 'IZDAVAC',              23      FROM dual UNION ALL
  SELECT 'AUTOR',                19307   FROM dual UNION ALL
  SELECT 'PUBLIKACIJA',          59599   FROM dual UNION ALL
  SELECT 'PUBLIKACIJA_AUTOR',    60065   FROM dual UNION ALL
  SELECT 'PRIMERAK',             956069  FROM dual UNION ALL
  SELECT 'CLAN',                 142888  FROM dual UNION ALL
  SELECT 'STATUS_POZAJMICE',     3       FROM dual UNION ALL
  SELECT 'POZAJMICA',            1400003 FROM dual
),
actual_counts (table_name, actual_rows) AS (
  SELECT 'GRAD',                 COUNT(*) FROM grad UNION ALL
  SELECT 'BIBLIOTEKA',           COUNT(*) FROM biblioteka UNION ALL
  SELECT 'ODELJENJE',            COUNT(*) FROM odeljenje UNION ALL
  SELECT 'TIP_PUBLIKACIJE',      COUNT(*) FROM tip_publikacije UNION ALL
  SELECT 'IZDAVAC',              COUNT(*) FROM izdavac UNION ALL
  SELECT 'AUTOR',                COUNT(*) FROM autor UNION ALL
  SELECT 'PUBLIKACIJA',          COUNT(*) FROM publikacija UNION ALL
  SELECT 'PUBLIKACIJA_AUTOR',    COUNT(*) FROM publikacija_autor UNION ALL
  SELECT 'PRIMERAK',             COUNT(*) FROM primerak UNION ALL
  SELECT 'CLAN',                 COUNT(*) FROM clan UNION ALL
  SELECT 'STATUS_POZAJMICE',     COUNT(*) FROM status_pozajmice UNION ALL
  SELECT 'POZAJMICA',            COUNT(*) FROM pozajmica
)
SELECT e.table_name,
       e.expected_rows,
       a.actual_rows,
       CASE WHEN e.expected_rows = a.actual_rows THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_counts e
  JOIN actual_counts a ON a.table_name = e.table_name
 ORDER BY e.table_name;

PROMPT === Foreign-key orphan check (every count must be 0) ===

SELECT check_name, orphan_rows
  FROM (
    SELECT 'BIBLIOTEKA -> GRAD' AS check_name, COUNT(*) AS orphan_rows
      FROM biblioteka b WHERE NOT EXISTS (SELECT 1 FROM grad g WHERE g.grad_id = b.grad_id)
    UNION ALL
    SELECT 'ODELJENJE -> BIBLIOTEKA', COUNT(*)
      FROM odeljenje o WHERE NOT EXISTS (SELECT 1 FROM biblioteka b WHERE b.biblioteka_id = o.biblioteka_id)
    UNION ALL
    SELECT 'PUBLIKACIJA -> TIP_PUBLIKACIJE', COUNT(*)
      FROM publikacija p WHERE NOT EXISTS (SELECT 1 FROM tip_publikacije t WHERE t.tip_publikacije_id = p.tip_publikacije_id)
    UNION ALL
    SELECT 'PUBLIKACIJA -> IZDAVAC', COUNT(*)
      FROM publikacija p WHERE NOT EXISTS (SELECT 1 FROM izdavac i WHERE i.izdavac_id = p.izdavac_id)
    UNION ALL
    SELECT 'PUBLIKACIJA_AUTOR -> PUBLIKACIJA', COUNT(*)
      FROM publikacija_autor pa WHERE NOT EXISTS (SELECT 1 FROM publikacija p WHERE p.publikacija_id = pa.publikacija_id)
    UNION ALL
    SELECT 'PUBLIKACIJA_AUTOR -> AUTOR', COUNT(*)
      FROM publikacija_autor pa WHERE NOT EXISTS (SELECT 1 FROM autor a WHERE a.autor_id = pa.autor_id)
    UNION ALL
    SELECT 'PRIMERAK -> PUBLIKACIJA', COUNT(*)
      FROM primerak pr WHERE NOT EXISTS (SELECT 1 FROM publikacija p WHERE p.publikacija_id = pr.publikacija_id)
    UNION ALL
    SELECT 'PRIMERAK -> ODELJENJE', COUNT(*)
      FROM primerak pr WHERE NOT EXISTS (SELECT 1 FROM odeljenje o WHERE o.odeljenje_id = pr.odeljenje_id)
    UNION ALL
    SELECT 'POZAJMICA -> CLAN', COUNT(*)
      FROM pozajmica po WHERE NOT EXISTS (SELECT 1 FROM clan c WHERE c.clan_id = po.clan_id)
    UNION ALL
    SELECT 'POZAJMICA -> PRIMERAK', COUNT(*)
      FROM pozajmica po WHERE NOT EXISTS (SELECT 1 FROM primerak pr WHERE pr.primerak_id = po.primerak_id)
    UNION ALL
    SELECT 'POZAJMICA -> STATUS_POZAJMICE', COUNT(*)
      FROM pozajmica po WHERE NOT EXISTS (SELECT 1 FROM status_pozajmice s WHERE s.status_pozajmice_id = po.status_pozajmice_id)
  )
 ORDER BY check_name;

PROMPT === Expected nullable values ===

SELECT 'AUTOR rows without PREZIME' AS metric, COUNT(*) AS value
  FROM autor
 WHERE prezime IS NULL
UNION ALL
SELECT 'POZAJMICA rows without DATUM_VRACANJA', COUNT(*)
  FROM pozajmica
 WHERE datum_vracanja IS NULL;

PROMPT === Constraint state (every constraint must be ENABLED and VALIDATED) ===

SELECT constraint_name, constraint_type, status, validated
  FROM user_constraints
 WHERE table_name IN (
   'GRAD', 'BIBLIOTEKA', 'ODELJENJE', 'TIP_PUBLIKACIJE', 'IZDAVAC', 'AUTOR',
   'PUBLIKACIJA', 'PUBLIKACIJA_AUTOR', 'PRIMERAK', 'CLAN', 'STATUS_POZAJMICE', 'POZAJMICA'
 )
 ORDER BY table_name, constraint_name;
