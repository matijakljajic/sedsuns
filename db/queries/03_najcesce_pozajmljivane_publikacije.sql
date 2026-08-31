-- Najčešće pozajmljivane publikacije u svakoj godini.

WITH publikacije_po_godini AS (
  SELECT d.godina,
         p.publikacija_id,
         p.naslov,
         p.tip_publikacije,
         p.izdavac,
         COUNT(*) AS broj_pozajmica
    FROM seds_dw.fact_pozajmica f
    JOIN seds_dw.dim_vreme d ON d.vreme_id = f.datum_pozajmice_id
    JOIN seds_dw.dim_publikacija p ON p.publikacija_id = f.publikacija_id
   GROUP BY d.godina, p.publikacija_id, p.naslov, p.tip_publikacije, p.izdavac
),
rangirane_publikacije AS (
  SELECT godina,
         publikacija_id,
         naslov,
         tip_publikacije,
         izdavac,
         broj_pozajmica,
         ROW_NUMBER() OVER (
           PARTITION BY godina
           ORDER BY broj_pozajmica DESC, naslov, publikacija_id
         ) AS rang_u_godini
    FROM publikacije_po_godini
)
SELECT godina,
       rang_u_godini,
       naslov,
       tip_publikacije,
       izdavac,
       broj_pozajmica
  FROM rangirane_publikacije
 WHERE rang_u_godini <= 10
 ORDER BY godina, rang_u_godini, naslov;
