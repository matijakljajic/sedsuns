-- Run as SEDS_OLTP against FREEPDB1.
-- This script creates the OLTP schema from 00_relational_model.mmd.

WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE TABLE grad (
  grad_id NUMBER(10) CONSTRAINT pk_grad PRIMARY KEY,
  naziv   VARCHAR2(100 CHAR) CONSTRAINT nn_grad_naziv NOT NULL,
  CONSTRAINT uq_grad_naziv UNIQUE (naziv)
);

CREATE TABLE biblioteka (
  biblioteka_id NUMBER(10) CONSTRAINT pk_biblioteka PRIMARY KEY,
  naziv         VARCHAR2(150 CHAR) CONSTRAINT nn_biblioteka_naziv NOT NULL,
  adresa        VARCHAR2(200 CHAR) CONSTRAINT nn_biblioteka_adresa NOT NULL,
  grad_id       NUMBER(10) CONSTRAINT nn_biblioteka_grad NOT NULL,
  CONSTRAINT fk_biblioteka_grad
    FOREIGN KEY (grad_id) REFERENCES grad (grad_id)
);

CREATE TABLE odeljenje (
  odeljenje_id  NUMBER(10) CONSTRAINT pk_odeljenje PRIMARY KEY,
  naziv         VARCHAR2(150 CHAR) CONSTRAINT nn_odeljenje_naziv NOT NULL,
  biblioteka_id NUMBER(10) CONSTRAINT nn_odeljenje_biblioteka NOT NULL,
  CONSTRAINT fk_odeljenje_biblioteka
    FOREIGN KEY (biblioteka_id) REFERENCES biblioteka (biblioteka_id),
  CONSTRAINT uq_odeljenje_biblioteka_naziv UNIQUE (biblioteka_id, naziv)
);

CREATE TABLE tip_publikacije (
  tip_publikacije_id NUMBER(10) CONSTRAINT pk_tip_publikacije PRIMARY KEY,
  naziv              VARCHAR2(50 CHAR) CONSTRAINT nn_tip_publikacije_naziv NOT NULL,
  CONSTRAINT uq_tip_publikacije_naziv UNIQUE (naziv)
);

CREATE TABLE izdavac (
  izdavac_id NUMBER(10) CONSTRAINT pk_izdavac PRIMARY KEY,
  naziv      VARCHAR2(150 CHAR) CONSTRAINT nn_izdavac_naziv NOT NULL,
  drzava     VARCHAR2(100 CHAR) CONSTRAINT nn_izdavac_drzava NOT NULL
);

CREATE TABLE autor (
  autor_id         NUMBER(10) CONSTRAINT pk_autor PRIMARY KEY,
  ime              VARCHAR2(100 CHAR) CONSTRAINT nn_autor_ime NOT NULL,
  prezime          VARCHAR2(100 CHAR),
  godina_rodjenja  NUMBER(4) CONSTRAINT nn_autor_godina_rodjenja NOT NULL,
  drzava           VARCHAR2(100 CHAR) CONSTRAINT nn_autor_drzava NOT NULL,
  CONSTRAINT ck_autor_godina_rodjenja CHECK (godina_rodjenja BETWEEN 1000 AND 9999)
);

CREATE TABLE publikacija (
  publikacija_id       NUMBER(10) CONSTRAINT pk_publikacija PRIMARY KEY,
  naslov               VARCHAR2(1000 CHAR) CONSTRAINT nn_publikacija_naslov NOT NULL,
  isbn                 VARCHAR2(13 CHAR) CONSTRAINT nn_publikacija_isbn NOT NULL,
  godina_izdanja       NUMBER(4) CONSTRAINT nn_publikacija_godina_izdanja NOT NULL,
  broj_strana          NUMBER(5) CONSTRAINT nn_publikacija_broj_strana NOT NULL,
  tip_publikacije_id   NUMBER(10) CONSTRAINT nn_publikacija_tip NOT NULL,
  izdavac_id           NUMBER(10) CONSTRAINT nn_publikacija_izdavac NOT NULL,
  CONSTRAINT uq_publikacija_isbn UNIQUE (isbn),
  CONSTRAINT ck_publikacija_godina_izdanja CHECK (godina_izdanja BETWEEN 1000 AND 9999),
  CONSTRAINT ck_publikacija_broj_strana CHECK (broj_strana > 0),
  CONSTRAINT fk_publikacija_tip
    FOREIGN KEY (tip_publikacije_id) REFERENCES tip_publikacije (tip_publikacije_id),
  CONSTRAINT fk_publikacija_izdavac
    FOREIGN KEY (izdavac_id) REFERENCES izdavac (izdavac_id)
);

CREATE TABLE publikacija_autor (
  publikacija_id NUMBER(10) CONSTRAINT nn_publikacija_autor_publikacija NOT NULL,
  autor_id       NUMBER(10) CONSTRAINT nn_publikacija_autor_autor NOT NULL,
  CONSTRAINT pk_publikacija_autor PRIMARY KEY (publikacija_id, autor_id),
  CONSTRAINT fk_publikacija_autor_publikacija
    FOREIGN KEY (publikacija_id) REFERENCES publikacija (publikacija_id),
  CONSTRAINT fk_publikacija_autor_autor
    FOREIGN KEY (autor_id) REFERENCES autor (autor_id)
);

CREATE TABLE primerak (
  primerak_id        NUMBER(10) CONSTRAINT pk_primerak PRIMARY KEY,
  inventarski_broj   VARCHAR2(20 CHAR) CONSTRAINT nn_primerak_inventarski_broj NOT NULL,
  datum_nabavke      DATE CONSTRAINT nn_primerak_datum_nabavke NOT NULL,
  fizicko_stanje     VARCHAR2(30 CHAR) CONSTRAINT nn_primerak_fizicko_stanje NOT NULL,
  publikacija_id     NUMBER(10) CONSTRAINT nn_primerak_publikacija NOT NULL,
  odeljenje_id       NUMBER(10) CONSTRAINT nn_primerak_odeljenje NOT NULL,
  CONSTRAINT uq_primerak_inventarski_broj UNIQUE (inventarski_broj),
  CONSTRAINT ck_primerak_fizicko_stanje
    CHECK (fizicko_stanje IN ('odlično', 'dobro', 'zadovoljavajuće', 'oštećeno')),
  CONSTRAINT fk_primerak_publikacija
    FOREIGN KEY (publikacija_id) REFERENCES publikacija (publikacija_id),
  CONSTRAINT fk_primerak_odeljenje
    FOREIGN KEY (odeljenje_id) REFERENCES odeljenje (odeljenje_id)
);

CREATE TABLE clan (
  clan_id            NUMBER(10) CONSTRAINT pk_clan PRIMARY KEY,
  ime                VARCHAR2(100 CHAR) CONSTRAINT nn_clan_ime NOT NULL,
  prezime            VARCHAR2(100 CHAR) CONSTRAINT nn_clan_prezime NOT NULL,
  pol                CHAR(1 CHAR) CONSTRAINT nn_clan_pol NOT NULL,
  datum_rodjenja     DATE CONSTRAINT nn_clan_datum_rodjenja NOT NULL,
  email              VARCHAR2(320 CHAR) CONSTRAINT nn_clan_email NOT NULL,
  datum_uclanjenja   DATE CONSTRAINT nn_clan_datum_uclanjenja NOT NULL,
  CONSTRAINT uq_clan_email UNIQUE (email),
  CONSTRAINT ck_clan_pol CHECK (pol IN ('M', 'Ž', 'N')),
  CONSTRAINT ck_clan_datumi CHECK (datum_uclanjenja >= datum_rodjenja)
);

CREATE TABLE status_pozajmice (
  status_pozajmice_id NUMBER(10) CONSTRAINT pk_status_pozajmice PRIMARY KEY,
  naziv               VARCHAR2(50 CHAR) CONSTRAINT nn_status_pozajmice_naziv NOT NULL,
  CONSTRAINT uq_status_pozajmice_naziv UNIQUE (naziv)
);

CREATE TABLE pozajmica (
  pozajmica_id          NUMBER(10) CONSTRAINT pk_pozajmica PRIMARY KEY,
  datum_pozajmice       DATE CONSTRAINT nn_pozajmica_datum_pozajmice NOT NULL,
  rok_vracanja          DATE CONSTRAINT nn_pozajmica_rok_vracanja NOT NULL,
  datum_vracanja        DATE,
  clan_id               NUMBER(10) CONSTRAINT nn_pozajmica_clan NOT NULL,
  primerak_id           NUMBER(10) CONSTRAINT nn_pozajmica_primerak NOT NULL,
  status_pozajmice_id   NUMBER(10) CONSTRAINT nn_pozajmica_status NOT NULL,
  CONSTRAINT ck_pozajmica_datumi
    CHECK (
      rok_vracanja >= datum_pozajmice
      AND (datum_vracanja IS NULL OR datum_vracanja >= datum_pozajmice)
    ),
  CONSTRAINT fk_pozajmica_clan
    FOREIGN KEY (clan_id) REFERENCES clan (clan_id),
  CONSTRAINT fk_pozajmica_primerak
    FOREIGN KEY (primerak_id) REFERENCES primerak (primerak_id),
  CONSTRAINT fk_pozajmica_status
    FOREIGN KEY (status_pozajmice_id) REFERENCES status_pozajmice (status_pozajmice_id)
);
