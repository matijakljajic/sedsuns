-- Run as SEDS_DW against FREEPDB1 after all PDI transformations finish.

WHENEVER SQLERROR EXIT SQL.SQLCODE

SET PAGESIZE 200
SET LINESIZE 170

PROMPT === DW row-count validation ===

WITH expected_counts (table_name, expected_rows) AS (
  SELECT 'DIM_VREME',                 751     FROM dual UNION ALL
  SELECT 'DIM_GRAD',                  5       FROM dual UNION ALL
  SELECT 'DIM_BIBLIOTEKA',            5       FROM dual UNION ALL
  SELECT 'DIM_ODELJENJE',             15      FROM dual UNION ALL
  SELECT 'DIM_CLAN',                  142888  FROM dual UNION ALL
  SELECT 'DIM_STATUS_POZAJMICE',      3       FROM dual UNION ALL
  SELECT 'DIM_AUTOR',                 19307   FROM dual UNION ALL
  SELECT 'DIM_PUBLIKACIJA',           59599   FROM dual UNION ALL
  SELECT 'BRIDGE_PUBLIKACIJA_AUTOR',  60065   FROM dual UNION ALL
  SELECT 'FACT_POZAJMICA',            1400003 FROM dual
),
actual_counts (table_name, actual_rows) AS (
  SELECT 'DIM_VREME',                 COUNT(*) FROM dim_vreme UNION ALL
  SELECT 'DIM_GRAD',                  COUNT(*) FROM dim_grad UNION ALL
  SELECT 'DIM_BIBLIOTEKA',            COUNT(*) FROM dim_biblioteka UNION ALL
  SELECT 'DIM_ODELJENJE',             COUNT(*) FROM dim_odeljenje UNION ALL
  SELECT 'DIM_CLAN',                  COUNT(*) FROM dim_clan UNION ALL
  SELECT 'DIM_STATUS_POZAJMICE',      COUNT(*) FROM dim_status_pozajmice UNION ALL
  SELECT 'DIM_AUTOR',                 COUNT(*) FROM dim_autor UNION ALL
  SELECT 'DIM_PUBLIKACIJA',           COUNT(*) FROM dim_publikacija UNION ALL
  SELECT 'BRIDGE_PUBLIKACIJA_AUTOR',  COUNT(*) FROM bridge_publikacija_autor UNION ALL
  SELECT 'FACT_POZAJMICA',            COUNT(*) FROM fact_pozajmica
)
SELECT e.table_name,
       e.expected_rows,
       a.actual_rows,
       CASE WHEN e.expected_rows = a.actual_rows THEN 'PASS' ELSE 'FAIL' END AS result
  FROM expected_counts e
  JOIN actual_counts a ON a.table_name = e.table_name
 ORDER BY e.table_name;

PROMPT === DW foreign-key orphan check (every count must be 0) ===

SELECT check_name, orphan_rows
  FROM (
    SELECT 'DIM_BIBLIOTEKA -> DIM_GRAD' AS check_name, COUNT(*) AS orphan_rows
      FROM dim_biblioteka b WHERE NOT EXISTS (SELECT 1 FROM dim_grad g WHERE g.grad_id = b.grad_id)
    UNION ALL
    SELECT 'DIM_ODELJENJE -> DIM_BIBLIOTEKA', COUNT(*)
      FROM dim_odeljenje o WHERE NOT EXISTS (SELECT 1 FROM dim_biblioteka b WHERE b.biblioteka_id = o.biblioteka_id)
    UNION ALL
    SELECT 'BRIDGE -> DIM_PUBLIKACIJA', COUNT(*)
      FROM bridge_publikacija_autor b WHERE NOT EXISTS (SELECT 1 FROM dim_publikacija p WHERE p.publikacija_id = b.publikacija_id)
    UNION ALL
    SELECT 'BRIDGE -> DIM_AUTOR', COUNT(*)
      FROM bridge_publikacija_autor b WHERE NOT EXISTS (SELECT 1 FROM dim_autor a WHERE a.autor_id = b.autor_id)
    UNION ALL
    SELECT 'FACT -> DIM_VREME (loan)', COUNT(*)
      FROM fact_pozajmica f WHERE NOT EXISTS (SELECT 1 FROM dim_vreme d WHERE d.vreme_id = f.datum_pozajmice_id)
    UNION ALL
    SELECT 'FACT -> DIM_VREME (due)', COUNT(*)
      FROM fact_pozajmica f WHERE NOT EXISTS (SELECT 1 FROM dim_vreme d WHERE d.vreme_id = f.rok_vracanja_id)
    UNION ALL
    SELECT 'FACT -> DIM_VREME (return)', COUNT(*)
      FROM fact_pozajmica f WHERE f.datum_vracanja_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dim_vreme d WHERE d.vreme_id = f.datum_vracanja_id)
    UNION ALL
    SELECT 'FACT -> DIM_CLAN', COUNT(*)
      FROM fact_pozajmica f WHERE NOT EXISTS (SELECT 1 FROM dim_clan c WHERE c.clan_id = f.clan_id)
    UNION ALL
    SELECT 'FACT -> DIM_PUBLIKACIJA', COUNT(*)
      FROM fact_pozajmica f WHERE NOT EXISTS (SELECT 1 FROM dim_publikacija p WHERE p.publikacija_id = f.publikacija_id)
    UNION ALL
    SELECT 'FACT -> DIM_ODELJENJE', COUNT(*)
      FROM fact_pozajmica f WHERE NOT EXISTS (SELECT 1 FROM dim_odeljenje o WHERE o.odeljenje_id = f.odeljenje_id)
    UNION ALL
    SELECT 'FACT -> DIM_STATUS_POZAJMICE', COUNT(*)
      FROM fact_pozajmica f WHERE NOT EXISTS (SELECT 1 FROM dim_status_pozajmice s WHERE s.status_pozajmice_id = f.status_pozajmice_id)
  )
 ORDER BY check_name;

PROMPT === Warehouse-specific checks (every invalid count must be 0) ===

SELECT metric, invalid_rows
  FROM (
    SELECT 'Publications whose bridge weights do not sum to 1' AS metric, COUNT(*) AS invalid_rows
      FROM (
        SELECT publikacija_id
          FROM bridge_publikacija_autor
         GROUP BY publikacija_id
        HAVING ABS(SUM(tezina) - 1) > 0.000001
      )
    UNION ALL
    SELECT 'Negative planned loan duration', COUNT(*)
      FROM fact_pozajmica
     WHERE broj_dana_pozajmice < 0
    UNION ALL
    SELECT 'Negative late days', COUNT(*)
      FROM fact_pozajmica
     WHERE broj_dana_kasnjenja < 0
    UNION ALL
    SELECT 'Returned loans without late-days value', COUNT(*)
      FROM fact_pozajmica
     WHERE datum_vracanja_id IS NOT NULL
       AND broj_dana_kasnjenja IS NULL
  )
 ORDER BY metric;

PROMPT === Expected nullable fact attributes ===

SELECT 'FACT rows without DATUM_VRACANJA_ID' AS metric, COUNT(*) AS value
  FROM fact_pozajmica
 WHERE datum_vracanja_id IS NULL
UNION ALL
SELECT 'FACT rows without BROJ_DANA_KASNJENJA', COUNT(*)
  FROM fact_pozajmica
 WHERE broj_dana_kasnjenja IS NULL;

PROMPT === Constraint state (every constraint must be ENABLED and VALIDATED) ===

SELECT constraint_name, constraint_type, status, validated
  FROM user_constraints
 WHERE table_name IN (
   'DIM_VREME', 'DIM_GRAD', 'DIM_BIBLIOTEKA', 'DIM_ODELJENJE', 'DIM_CLAN',
   'DIM_STATUS_POZAJMICE', 'DIM_AUTOR', 'DIM_PUBLIKACIJA',
   'BRIDGE_PUBLIKACIJA_AUTOR', 'FACT_POZAJMICA'
 )
 ORDER BY table_name, constraint_name;
