-- Mesečni obim pozajmica, promena u odnosu na prethodni mesec i kumulativni zbir.

WITH pozajmice_po_mesecu AS (
  SELECT mesec_datum,
         godina,
         mesec,
         naziv_meseca,
         SUM(broj_pozajmica) AS broj_pozajmica
    FROM seds_dw.mv_mesecni_pregled_biblioteka
   GROUP BY mesec_datum, godina, mesec, naziv_meseca
)
SELECT godina,
       mesec,
       naziv_meseca,
       broj_pozajmica,
       LAG(broj_pozajmica) OVER (ORDER BY mesec_datum) AS prethodni_mesec,
       broj_pozajmica - LAG(broj_pozajmica) OVER (ORDER BY mesec_datum) AS promena_u_odnosu_na_prethodni_mesec,
       SUM(broj_pozajmica) OVER (
         ORDER BY mesec_datum
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS kumulativno_pozajmica
  FROM pozajmice_po_mesecu
 ORDER BY mesec_datum;
