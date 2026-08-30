-- Godišnje poređenje broja i prosečnog trajanja vraćenih pozajmica po biblioteci.

SELECT d_poz.godina,
       g.naziv AS grad,
       b.naziv AS biblioteka,
       COUNT(*) AS broj_vracenih_pozajmica,
       ROUND(AVG(f.broj_dana_pozajmice), 2) AS prosek_plan_dana,
       ROUND(AVG(d_vrac.datum - d_poz.datum), 2) AS prosek_stvar_dana
  FROM seds_dw.fact_pozajmica f
  JOIN seds_dw.dim_vreme d_poz ON d_poz.vreme_id = f.datum_pozajmice_id
  JOIN seds_dw.dim_vreme d_vrac ON d_vrac.vreme_id = f.datum_vracanja_id
  JOIN seds_dw.dim_odeljenje o ON o.odeljenje_id = f.odeljenje_id
  JOIN seds_dw.dim_biblioteka b ON b.biblioteka_id = o.biblioteka_id
  JOIN seds_dw.dim_grad g ON g.grad_id = b.grad_id
 GROUP BY d_poz.godina, g.naziv, b.naziv
 ORDER BY d_poz.godina, biblioteka;
