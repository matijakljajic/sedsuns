-- Raspodela pozajmica prema starosti publikacije u trenutku pozajmljivanja.

SELECT d.godina,
       CASE
         WHEN d.godina < p.godina_izdanja THEN 'buduce izdanje'
         WHEN d.godina - p.godina_izdanja <= 5 THEN '0-5 godina'
         WHEN d.godina - p.godina_izdanja <= 15 THEN '6-15 godina'
         ELSE '16+ godina'
       END AS starosna_grupa_publikacije,
       COUNT(*) AS broj_pozajmica,
       ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (PARTITION BY d.godina), 2) AS procenat_u_godini
  FROM seds_dw.fact_pozajmica f
  JOIN seds_dw.dim_vreme d ON d.vreme_id = f.datum_pozajmice_id
  JOIN seds_dw.dim_publikacija p ON p.publikacija_id = f.publikacija_id
 GROUP BY d.godina,
          CASE
            WHEN d.godina < p.godina_izdanja THEN 'buduce izdanje'
            WHEN d.godina - p.godina_izdanja <= 5 THEN '0-5 godina'
            WHEN d.godina - p.godina_izdanja <= 15 THEN '6-15 godina'
            ELSE '16+ godina'
          END
 ORDER BY d.godina, starosna_grupa_publikacije;
