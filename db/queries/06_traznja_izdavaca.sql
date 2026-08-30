-- Tražnja za izdanjima izdavača, normalizovana brojem naslova i dostupnih primeraka.

WITH koriscenje_publikacija AS (
  SELECT p.publikacija_id,
         p.izdavac,
         p.broj_primeraka,
         COUNT(f.pozajmica_id) AS broj_pozajmica
    FROM seds_dw.dim_publikacija p
    LEFT JOIN seds_dw.fact_pozajmica f ON f.publikacija_id = p.publikacija_id
   GROUP BY p.publikacija_id, p.izdavac, p.broj_primeraka
),
traznja_po_izdavacu AS (
  SELECT izdavac,
         COUNT(*) AS broj_naslova,
         SUM(broj_primeraka) AS broj_primeraka,
         SUM(broj_pozajmica) AS broj_pozajmica,
         ROUND(SUM(broj_pozajmica) / COUNT(*), 2) AS pozajmice_po_naslovu,
         ROUND(SUM(broj_pozajmica) / NULLIF(SUM(broj_primeraka), 0), 2) AS pozajmice_po_primerku
    FROM koriscenje_publikacija
   GROUP BY izdavac
)
SELECT izdavac,
       broj_naslova,
       broj_primeraka,
       broj_pozajmica,
       pozajmice_po_naslovu,
       pozajmice_po_primerku,
       DENSE_RANK() OVER (ORDER BY pozajmice_po_primerku DESC NULLS LAST) AS rang_po_traznji
  FROM traznja_po_izdavacu
 ORDER BY rang_po_traznji, izdavac;
