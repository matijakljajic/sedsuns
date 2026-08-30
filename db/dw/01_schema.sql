-- Run as SEDS_DW against FREEPDB1.
-- The grain of fact_pozajmica is one row per OLTP loan.

WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE TABLE dim_vreme (
  vreme_id      NUMBER(8) CONSTRAINT pk_dim_vreme PRIMARY KEY,
  datum         DATE CONSTRAINT nn_dim_vreme_datum NOT NULL,
  dan           NUMBER(2) CONSTRAINT nn_dim_vreme_dan NOT NULL,
  mesec         NUMBER(2) CONSTRAINT nn_dim_vreme_mesec NOT NULL,
  naziv_meseca  VARCHAR2(20 CHAR) CONSTRAINT nn_dim_vreme_naziv_meseca NOT NULL,
  kvartal       NUMBER(1) CONSTRAINT nn_dim_vreme_kvartal NOT NULL,
  godina        NUMBER(4) CONSTRAINT nn_dim_vreme_godina NOT NULL,
  dan_u_nedelji VARCHAR2(20 CHAR) CONSTRAINT nn_dim_vreme_dan_u_nedelji NOT NULL,
  CONSTRAINT uq_dim_vreme_datum UNIQUE (datum),
  CONSTRAINT ck_dim_vreme_dan CHECK (dan BETWEEN 1 AND 31),
  CONSTRAINT ck_dim_vreme_mesec CHECK (mesec BETWEEN 1 AND 12),
  CONSTRAINT ck_dim_vreme_kvartal CHECK (kvartal BETWEEN 1 AND 4)
);

CREATE TABLE dim_clan (
  clan_id         NUMBER(10) CONSTRAINT pk_dim_clan PRIMARY KEY,
  pol             CHAR(1 CHAR) CONSTRAINT nn_dim_clan_pol NOT NULL,
  datum_rodjenja  DATE CONSTRAINT nn_dim_clan_datum_rodjenja NOT NULL,
  CONSTRAINT ck_dim_clan_pol CHECK (pol IN ('M', 'Ž', 'N'))
);

CREATE TABLE dim_publikacija (
  publikacija_id    NUMBER(10) CONSTRAINT pk_dim_publikacija PRIMARY KEY,
  naslov            VARCHAR2(1000 CHAR) CONSTRAINT nn_dim_publikacija_naslov NOT NULL,
  isbn              VARCHAR2(13 CHAR) CONSTRAINT nn_dim_publikacija_isbn NOT NULL,
  godina_izdanja    NUMBER(4) CONSTRAINT nn_dim_publikacija_godina NOT NULL,
  broj_strana       NUMBER(5) CONSTRAINT nn_dim_publikacija_broj_strana NOT NULL,
  tip_publikacije   VARCHAR2(50 CHAR) CONSTRAINT nn_dim_publikacija_tip NOT NULL,
  izdavac           VARCHAR2(150 CHAR) CONSTRAINT nn_dim_publikacija_izdavac NOT NULL,
  drzava_izdavaca   VARCHAR2(100 CHAR) CONSTRAINT nn_dim_publikacija_drzava NOT NULL,
  broj_autora       NUMBER(4) CONSTRAINT nn_dim_publikacija_broj_autora NOT NULL,
  broj_primeraka    NUMBER(10) CONSTRAINT nn_dim_publikacija_broj_primeraka NOT NULL,
  CONSTRAINT uq_dim_publikacija_isbn UNIQUE (isbn),
  CONSTRAINT ck_dim_publikacija_strana CHECK (broj_strana > 0),
  CONSTRAINT ck_dim_publikacija_autora CHECK (broj_autora >= 0),
  CONSTRAINT ck_dim_publikacija_primeraka CHECK (broj_primeraka >= 0)
);

CREATE TABLE dim_autor (
  autor_id         NUMBER(10) CONSTRAINT pk_dim_autor PRIMARY KEY,
  ime              VARCHAR2(100 CHAR) CONSTRAINT nn_dim_autor_ime NOT NULL,
  prezime          VARCHAR2(100 CHAR),
  godina_rodjenja  NUMBER(4) CONSTRAINT nn_dim_autor_godina NOT NULL,
  drzava           VARCHAR2(100 CHAR) CONSTRAINT nn_dim_autor_drzava NOT NULL
);

CREATE TABLE bridge_publikacija_autor (
  publikacija_id NUMBER(10) CONSTRAINT nn_bridge_pub_autor_pub NOT NULL,
  autor_id       NUMBER(10) CONSTRAINT nn_bridge_pub_autor_autor NOT NULL,
  tezina         NUMBER(10,9) CONSTRAINT nn_bridge_pub_autor_tezina NOT NULL,
  CONSTRAINT pk_bridge_pub_autor PRIMARY KEY (publikacija_id, autor_id),
  CONSTRAINT ck_bridge_pub_autor_tezina CHECK (tezina > 0 AND tezina <= 1),
  CONSTRAINT fk_bridge_pub_autor_pub
    FOREIGN KEY (publikacija_id) REFERENCES dim_publikacija (publikacija_id),
  CONSTRAINT fk_bridge_pub_autor_autor
    FOREIGN KEY (autor_id) REFERENCES dim_autor (autor_id)
);

CREATE TABLE dim_grad (
  grad_id NUMBER(10) CONSTRAINT pk_dim_grad PRIMARY KEY,
  naziv   VARCHAR2(100 CHAR) CONSTRAINT nn_dim_grad_naziv NOT NULL,
  CONSTRAINT uq_dim_grad_naziv UNIQUE (naziv)
);

CREATE TABLE dim_biblioteka (
  biblioteka_id NUMBER(10) CONSTRAINT pk_dim_biblioteka PRIMARY KEY,
  naziv         VARCHAR2(150 CHAR) CONSTRAINT nn_dim_biblioteka_naziv NOT NULL,
  grad_id       NUMBER(10) CONSTRAINT nn_dim_biblioteka_grad NOT NULL,
  CONSTRAINT fk_dim_biblioteka_grad
    FOREIGN KEY (grad_id) REFERENCES dim_grad (grad_id)
);

CREATE TABLE dim_odeljenje (
  odeljenje_id  NUMBER(10) CONSTRAINT pk_dim_odeljenje PRIMARY KEY,
  naziv         VARCHAR2(150 CHAR) CONSTRAINT nn_dim_odeljenje_naziv NOT NULL,
  biblioteka_id NUMBER(10) CONSTRAINT nn_dim_odeljenje_biblioteka NOT NULL,
  CONSTRAINT fk_dim_odeljenje_biblioteka
    FOREIGN KEY (biblioteka_id) REFERENCES dim_biblioteka (biblioteka_id),
  CONSTRAINT uq_dim_odeljenje_bibl_naziv UNIQUE (biblioteka_id, naziv)
);

CREATE TABLE dim_status_pozajmice (
  status_pozajmice_id NUMBER(10) CONSTRAINT pk_dim_status_pozajmice PRIMARY KEY,
  naziv               VARCHAR2(50 CHAR) CONSTRAINT nn_dim_status_pozajmice_naziv NOT NULL,
  CONSTRAINT uq_dim_status_pozajmice_naziv UNIQUE (naziv)
);

CREATE TABLE fact_pozajmica (
  pozajmica_id         NUMBER(10) CONSTRAINT pk_fact_pozajmica PRIMARY KEY,
  datum_pozajmice_id   NUMBER(8) CONSTRAINT nn_fact_poz_datum_poz NOT NULL,
  rok_vracanja_id       NUMBER(8) CONSTRAINT nn_fact_poz_rok_vracanja NOT NULL,
  datum_vracanja_id     NUMBER(8),
  clan_id               NUMBER(10) CONSTRAINT nn_fact_poz_clan NOT NULL,
  publikacija_id        NUMBER(10) CONSTRAINT nn_fact_poz_publikacija NOT NULL,
  odeljenje_id          NUMBER(10) CONSTRAINT nn_fact_poz_odeljenje NOT NULL,
  status_pozajmice_id   NUMBER(10) CONSTRAINT nn_fact_poz_status NOT NULL,
  broj_dana_pozajmice   NUMBER(6) CONSTRAINT nn_fact_poz_broj_dana NOT NULL,
  broj_dana_kasnjenja   NUMBER(6),
  CONSTRAINT ck_fact_poz_broj_dana CHECK (broj_dana_pozajmice >= 0),
  CONSTRAINT ck_fact_poz_kasnjenje CHECK (broj_dana_kasnjenja IS NULL OR broj_dana_kasnjenja >= 0),
  CONSTRAINT fk_fact_poz_datum_poz
    FOREIGN KEY (datum_pozajmice_id) REFERENCES dim_vreme (vreme_id),
  CONSTRAINT fk_fact_poz_rok_vracanja
    FOREIGN KEY (rok_vracanja_id) REFERENCES dim_vreme (vreme_id),
  CONSTRAINT fk_fact_poz_datum_vracanja
    FOREIGN KEY (datum_vracanja_id) REFERENCES dim_vreme (vreme_id),
  CONSTRAINT fk_fact_poz_clan
    FOREIGN KEY (clan_id) REFERENCES dim_clan (clan_id),
  CONSTRAINT fk_fact_poz_publikacija
    FOREIGN KEY (publikacija_id) REFERENCES dim_publikacija (publikacija_id),
  CONSTRAINT fk_fact_poz_odeljenje
    FOREIGN KEY (odeljenje_id) REFERENCES dim_odeljenje (odeljenje_id),
  CONSTRAINT fk_fact_poz_status
    FOREIGN KEY (status_pozajmice_id) REFERENCES dim_status_pozajmice (status_pozajmice_id)
);
