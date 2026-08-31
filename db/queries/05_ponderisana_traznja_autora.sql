-- Ponderisani obim pozajmica po autoru; pozajmica publikacije sa više autora deli se ravnomerno.

WITH autorske_pozajmice AS (
  SELECT d.godina,
         a.autor_id,
         a.ime,
         a.prezime,
         SUM(b.tezina) AS ponderisani_broj_pozajmica
    FROM seds_dw.fact_pozajmica f
    JOIN seds_dw.dim_vreme d ON d.vreme_id = f.datum_pozajmice_id
    JOIN seds_dw.bridge_publikacija_autor b ON b.publikacija_id = f.publikacija_id
    JOIN seds_dw.dim_autor a ON a.autor_id = b.autor_id
   GROUP BY d.godina, a.autor_id, a.ime, a.prezime
),
rangirani_autori AS (
  SELECT godina,
         autor_id,
         ime,
         prezime,
         ponderisani_broj_pozajmica,
         ROW_NUMBER() OVER (
           PARTITION BY godina
           ORDER BY ponderisani_broj_pozajmica DESC, prezime, ime, autor_id
         ) AS rang_u_godini
    FROM autorske_pozajmice
)
SELECT godina,
       rang_u_godini,
       ime,
       prezime,
       ROUND(ponderisani_broj_pozajmica, 2) AS ponderisani_broj_pozajmica
  FROM rangirani_autori
 WHERE rang_u_godini <= 10
 ORDER BY godina, rang_u_godini, prezime, ime;
