-- Stopa zakašnjelih vraćanja i prosečno kašnjenje po biblioteci i godini.

SELECT godina,
       grad,
       biblioteka,
       SUM(broj_pozajmica) AS ukupan_broj_pozajmica,
       SUM(broj_vracenih_pozajmica) AS broj_vracenih_pozajmica,
       SUM(broj_zakasnelih_pozajmica) AS broj_zakasnelih_pozajmica,
       ROUND(
         100 * SUM(broj_zakasnelih_pozajmica)
           / NULLIF(SUM(broj_vracenih_pozajmica), 0),
         2
       ) AS procenat_zakasnelih_vracanja,
       ROUND(
         SUM(ukupan_broj_dana_kasnjenja)
           / NULLIF(SUM(broj_zakasnelih_pozajmica), 0),
         2
       ) AS prosecno_dana_kasnjenja
  FROM seds_dw.mv_mesecni_pregled_biblioteka
 GROUP BY godina, grad, biblioteka
 ORDER BY godina, procenat_zakasnelih_vracanja DESC NULLS LAST, biblioteka;
