-- Pokrenuti kao SEDS_DW nakon što Pentaho ECTL napuni skladište podataka.
-- Jedan red predstavlja jedan kalendarski mesec i jednu biblioteku.

WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE MATERIALIZED VIEW mv_mesecni_pregled_biblioteka
  BUILD IMMEDIATE
  REFRESH COMPLETE ON DEMAND
AS
SELECT TRUNC(d.datum, 'MM') AS mesec_datum,
       d.godina,
       d.mesec,
       d.naziv_meseca,
       g.grad_id,
       g.naziv AS grad,
       b.biblioteka_id,
       b.naziv AS biblioteka,
       COUNT(*) AS broj_pozajmica,
       SUM(CASE WHEN f.datum_vracanja_id IS NOT NULL THEN 1 ELSE 0 END) AS broj_vracenih_pozajmica,
       SUM(CASE WHEN f.broj_dana_kasnjenja > 0 THEN 1 ELSE 0 END) AS broj_zakasnelih_pozajmica,
       SUM(NVL(f.broj_dana_kasnjenja, 0)) AS ukupan_broj_dana_kasnjenja
  FROM fact_pozajmica f
  JOIN dim_vreme d ON d.vreme_id = f.datum_pozajmice_id
  JOIN dim_odeljenje o ON o.odeljenje_id = f.odeljenje_id
  JOIN dim_biblioteka b ON b.biblioteka_id = o.biblioteka_id
  JOIN dim_grad g ON g.grad_id = b.grad_id
 GROUP BY TRUNC(d.datum, 'MM'),
          d.godina,
          d.mesec,
          d.naziv_meseca,
          g.grad_id,
          g.naziv,
          b.biblioteka_id,
          b.naziv;
