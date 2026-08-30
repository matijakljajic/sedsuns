-- Obim pozajmica po polu i starosnoj grupi članova, sa godišnjim procentualnim udelom.

SELECT d.godina,
       c.pol,
       CASE
         WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) < 18 THEN 'do 17'
         WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) BETWEEN 18 AND 25 THEN '18-25'
         WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) BETWEEN 26 AND 40 THEN '26-40'
         WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) BETWEEN 41 AND 65 THEN '41-65'
         ELSE '66+'
       END AS starosna_grupa,
       COUNT(*) AS broj_pozajmica,
       ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (PARTITION BY d.godina), 2) AS procenat_u_godini
  FROM seds_dw.fact_pozajmica f
  JOIN seds_dw.dim_vreme d ON d.vreme_id = f.datum_pozajmice_id
  JOIN seds_dw.dim_clan c ON c.clan_id = f.clan_id
 GROUP BY d.godina,
          c.pol,
          CASE
            WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) < 18 THEN 'do 17'
            WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) BETWEEN 18 AND 25 THEN '18-25'
            WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) BETWEEN 26 AND 40 THEN '26-40'
            WHEN FLOOR(MONTHS_BETWEEN(d.datum, c.datum_rodjenja) / 12) BETWEEN 41 AND 65 THEN '41-65'
            ELSE '66+'
          END
 ORDER BY d.godina, c.pol, starosna_grupa;
