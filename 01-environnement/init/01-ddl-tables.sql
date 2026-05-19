-- =============================================================================
-- NANOORBIT — SCRIPT DDL (création du schéma)
-- Module BDOE633 — Administration et Optimisation des Bases de Données
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- =============================================================================
-- Ce script crée les 11 tables du système NanoOrbit, leurs contraintes et
-- l'ordre de dépendances des clés étrangères.
--
-- IMPORTANT — posture BDOE633 :
--   La base est livrée clé en main. Toutes les tables sont créées dans le
--   tablespace par défaut du schéma, SANS optimisation de stockage et SANS
--   index superflus. La réorganisation en tablespaces par famille de données
--   est l'objet de la séance 3 (étape 1 du fil rouge).
--
-- Ordre de création imposé par les dépendances FK :
--   1. ORBITE              6. STATION_SOL
--   2. SATELLITE           7. AFFECTATION_STATION
--   (+) HISTORIQUE_STATUT  8. MISSION
--   3. INSTRUMENT          9. FENETRE_COM
--   4. EMBARQUEMENT       10. PARTICIPATION
--   5. CENTRE_CONTROLE
-- =============================================================================

SET DEFINE OFF;

PROMPT ============================================================
PROMPT  NanoOrbit — Creation du schema (11 tables)
PROMPT ============================================================


-- ---------------------------------------------------------------------------
-- TABLE 1 — ORBITE
-- Referentiel des plans orbitaux. Aucune dependance FK.
-- id_orbite : cle technique auto-incrementee.
-- RG-O02 : unicite de la combinaison (altitude, inclinaison).
-- ---------------------------------------------------------------------------
PROMPT > Creation ORBITE...

CREATE TABLE ORBITE (
    id_orbite         NUMBER GENERATED ALWAYS AS IDENTITY,
    type_orbite       VARCHAR2(10)   NOT NULL,
    altitude          NUMBER(6,1)    NOT NULL,
    inclinaison       NUMBER(5,2)    NOT NULL,
    periode_orbitale  NUMBER(6,2)    NOT NULL,
    excentricite      NUMBER(6,4)    NOT NULL,
    zone_couverture   VARCHAR2(80)   NOT NULL,
    CONSTRAINT pk_orbite        PRIMARY KEY (id_orbite),
    CONSTRAINT uq_orbite_alt_inc UNIQUE (altitude, inclinaison),
    CONSTRAINT ck_orbite_type   CHECK (type_orbite IN ('SSO','LEO','MEO','GEO')),
    CONSTRAINT ck_orbite_alt    CHECK (altitude > 0),
    CONSTRAINT ck_orbite_inc    CHECK (inclinaison BETWEEN 0 AND 180)
);


-- ---------------------------------------------------------------------------
-- TABLE 2 — SATELLITE
-- Parc de CubeSats. Depend de : ORBITE.
-- id_satellite : code alphanumerique metier (ex : SAT-001), immuable.
-- RG-S06 : le statut 'Desorbite' bloque toute nouvelle fenetre ou mission.
-- ---------------------------------------------------------------------------
PROMPT > Creation SATELLITE...

CREATE TABLE SATELLITE (
    id_satellite      VARCHAR2(10)   NOT NULL,
    nom_satellite     VARCHAR2(40)   NOT NULL,
    date_lancement    DATE           NOT NULL,
    masse             NUMBER(5,2)    NOT NULL,
    format_cubesat    VARCHAR2(4)    NOT NULL,
    statut            VARCHAR2(15)   NOT NULL,
    duree_vie_prevue  NUMBER(3)      NOT NULL,
    capacite_batterie NUMBER(4)      NOT NULL,
    id_orbite         NUMBER         NOT NULL,
    CONSTRAINT pk_satellite      PRIMARY KEY (id_satellite),
    CONSTRAINT fk_satellite_orb  FOREIGN KEY (id_orbite) REFERENCES ORBITE (id_orbite),
    CONSTRAINT ck_sat_format     CHECK (format_cubesat IN ('1U','3U','6U','12U')),
    CONSTRAINT ck_sat_statut     CHECK (statut IN ('Opérationnel','En veille','Défaillant','Désorbité')),
    CONSTRAINT ck_sat_masse      CHECK (masse > 0),
    CONSTRAINT ck_sat_duree      CHECK (duree_vie_prevue > 0)
);


-- ---------------------------------------------------------------------------
-- TABLE (+) HISTORIQUE_STATUT
-- Trace les changements de statut des satellites. Depend de : SATELLITE.
-- Cette table N'EST PAS peuplee par INSERT manuel : elle est alimentee
-- exclusivement par le trigger T5 (trg_historique_statut).
-- Creee juste apres SATELLITE conformement a l'ordre DDL.
-- ---------------------------------------------------------------------------
PROMPT > Creation HISTORIQUE_STATUT...

CREATE TABLE HISTORIQUE_STATUT (
    id_historique     NUMBER GENERATED ALWAYS AS IDENTITY,
    id_satellite      VARCHAR2(10)   NOT NULL,
    ancien_statut     VARCHAR2(15),
    nouveau_statut    VARCHAR2(15)   NOT NULL,
    date_changement   TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    motif             VARCHAR2(200),
    CONSTRAINT pk_historique     PRIMARY KEY (id_historique),
    CONSTRAINT fk_hist_satellite FOREIGN KEY (id_satellite) REFERENCES SATELLITE (id_satellite)
);


-- ---------------------------------------------------------------------------
-- TABLE 3 — INSTRUMENT
-- Catalogue global des instruments. Aucune dependance FK.
-- resolution NULLABLE : un recepteur AIS n'a pas de resolution au sol.
-- ---------------------------------------------------------------------------
PROMPT > Creation INSTRUMENT...

CREATE TABLE INSTRUMENT (
    ref_instrument    VARCHAR2(15)   NOT NULL,
    type_instrument   VARCHAR2(30)   NOT NULL,
    modele            VARCHAR2(40)   NOT NULL,
    resolution        NUMBER(6,1),
    consommation      NUMBER(5,2)    NOT NULL,
    masse             NUMBER(5,3)    NOT NULL,
    CONSTRAINT pk_instrument    PRIMARY KEY (ref_instrument),
    CONSTRAINT ck_instr_conso   CHECK (consommation >= 0),
    CONSTRAINT ck_instr_masse   CHECK (masse > 0)
);


-- ---------------------------------------------------------------------------
-- TABLE 4 — EMBARQUEMENT
-- Instruments montes sur les satellites. Depend de : SATELLITE, INSTRUMENT.
-- PK composite (id_satellite, ref_instrument).
-- RG-S04 : date_integration et etat_fonctionnement propres a chaque embarquement.
-- ---------------------------------------------------------------------------
PROMPT > Creation EMBARQUEMENT...

CREATE TABLE EMBARQUEMENT (
    id_satellite        VARCHAR2(10) NOT NULL,
    ref_instrument      VARCHAR2(15) NOT NULL,
    date_integration    DATE         NOT NULL,
    etat_fonctionnement VARCHAR2(15) NOT NULL,
    CONSTRAINT pk_embarquement   PRIMARY KEY (id_satellite, ref_instrument),
    CONSTRAINT fk_emb_satellite  FOREIGN KEY (id_satellite)   REFERENCES SATELLITE (id_satellite),
    CONSTRAINT fk_emb_instrument FOREIGN KEY (ref_instrument) REFERENCES INSTRUMENT (ref_instrument),
    CONSTRAINT ck_emb_etat       CHECK (etat_fonctionnement IN ('Nominal','Dégradé','Hors service'))
);


-- ---------------------------------------------------------------------------
-- TABLE 5 — CENTRE_CONTROLE
-- Centres d'operation NanoOrbit. Aucune dependance FK.
-- id_centre : cle technique auto-incrementee.
-- ---------------------------------------------------------------------------
PROMPT > Creation CENTRE_CONTROLE...

CREATE TABLE CENTRE_CONTROLE (
    id_centre       NUMBER GENERATED ALWAYS AS IDENTITY,
    nom_centre      VARCHAR2(40)   NOT NULL,
    ville           VARCHAR2(30)   NOT NULL,
    region_geo      VARCHAR2(20)   NOT NULL,
    fuseau_horaire  VARCHAR2(30)   NOT NULL,
    statut          VARCHAR2(10)   NOT NULL,
    CONSTRAINT pk_centre      PRIMARY KEY (id_centre),
    CONSTRAINT ck_centre_stat CHECK (statut IN ('Actif','Inactif'))
);


-- ---------------------------------------------------------------------------
-- TABLE 6 — STATION_SOL
-- Stations d'antenne mondiales. Aucune dependance FK directe.
-- RG-G03 : le statut 'Maintenance' bloque toute nouvelle fenetre (trigger T1).
-- ---------------------------------------------------------------------------
PROMPT > Creation STATION_SOL...

CREATE TABLE STATION_SOL (
    code_station     VARCHAR2(12)   NOT NULL,
    nom_station      VARCHAR2(40)   NOT NULL,
    latitude         NUMBER(8,4)    NOT NULL,
    longitude        NUMBER(8,4)    NOT NULL,
    diametre_antenne NUMBER(4,1)    NOT NULL,
    bande_frequence  VARCHAR2(2)    NOT NULL,
    debit_max        NUMBER(6)      NOT NULL,
    statut           VARCHAR2(12)   NOT NULL,
    CONSTRAINT pk_station      PRIMARY KEY (code_station),
    CONSTRAINT ck_station_band CHECK (bande_frequence IN ('S','X','Ka','Ku','UHF')),
    CONSTRAINT ck_station_lat  CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT ck_station_lon  CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_station_stat CHECK (statut IN ('Active','Maintenance','Inactive'))
);


-- ---------------------------------------------------------------------------
-- TABLE 7 — AFFECTATION_STATION
-- Rattachement d'une station a un centre de controle.
-- Depend de : CENTRE_CONTROLE, STATION_SOL. PK composite.
-- ---------------------------------------------------------------------------
PROMPT > Creation AFFECTATION_STATION...

CREATE TABLE AFFECTATION_STATION (
    id_centre        NUMBER       NOT NULL,
    code_station     VARCHAR2(12) NOT NULL,
    date_affectation DATE         NOT NULL,
    CONSTRAINT pk_affectation     PRIMARY KEY (id_centre, code_station),
    CONSTRAINT fk_aff_centre      FOREIGN KEY (id_centre)    REFERENCES CENTRE_CONTROLE (id_centre),
    CONSTRAINT fk_aff_station     FOREIGN KEY (code_station) REFERENCES STATION_SOL (code_station)
);


-- ---------------------------------------------------------------------------
-- TABLE 8 — MISSION
-- Missions scientifiques. Aucune dependance FK directe.
-- RG-M01 : date_fin NULLABLE (missions a duree indeterminee).
-- RG-M04 : le statut 'Terminee' bloque tout nouvel ajout de satellite (trigger T4).
-- ---------------------------------------------------------------------------
PROMPT > Creation MISSION...

CREATE TABLE MISSION (
    id_mission     VARCHAR2(15)  NOT NULL,
    nom_mission    VARCHAR2(40)  NOT NULL,
    objectif       VARCHAR2(200) NOT NULL,
    zone_geo_cible VARCHAR2(60)  NOT NULL,
    date_debut     DATE          NOT NULL,
    date_fin       DATE,
    statut_mission VARCHAR2(12)  NOT NULL,
    CONSTRAINT pk_mission      PRIMARY KEY (id_mission),
    CONSTRAINT ck_mission_stat CHECK (statut_mission IN ('Active','Terminée','Suspendue')),
    CONSTRAINT ck_mission_date CHECK (date_fin IS NULL OR date_fin >= date_debut)
);


-- ---------------------------------------------------------------------------
-- TABLE 9 — FENETRE_COM
-- Creneaux de communication. Depend de : SATELLITE, STATION_SOL.
-- id_fenetre : cle technique auto-incrementee.
-- RG-F04 : duree comprise entre 1 et 900 secondes.
-- RG-F05 : volume_donnees NULLABLE (NULL obligatoire pour les fenetres Planifiees).
-- ---------------------------------------------------------------------------
PROMPT > Creation FENETRE_COM...

CREATE TABLE FENETRE_COM (
    id_fenetre      NUMBER GENERATED ALWAYS AS IDENTITY,
    datetime_debut  TIMESTAMP      NOT NULL,
    duree           NUMBER(4)      NOT NULL,
    elevation_max   NUMBER(5,2)    NOT NULL,
    volume_donnees  NUMBER(8),
    statut          VARCHAR2(12)   NOT NULL,
    id_satellite    VARCHAR2(10)   NOT NULL,
    code_station    VARCHAR2(12)   NOT NULL,
    CONSTRAINT pk_fenetre      PRIMARY KEY (id_fenetre),
    CONSTRAINT fk_fen_satellite FOREIGN KEY (id_satellite) REFERENCES SATELLITE (id_satellite),
    CONSTRAINT fk_fen_station   FOREIGN KEY (code_station) REFERENCES STATION_SOL (code_station),
    CONSTRAINT ck_fen_duree     CHECK (duree BETWEEN 1 AND 900),
    CONSTRAINT ck_fen_elev      CHECK (elevation_max BETWEEN 0 AND 90),
    CONSTRAINT ck_fen_statut    CHECK (statut IN ('Planifiée','Réalisée','Annulée')),
    CONSTRAINT ck_fen_volume    CHECK (volume_donnees IS NULL OR volume_donnees >= 0)
);


-- ---------------------------------------------------------------------------
-- TABLE 10 — PARTICIPATION
-- Roles des satellites dans les missions. Depend de : SATELLITE, MISSION.
-- PK composite (id_satellite, id_mission).
-- ---------------------------------------------------------------------------
PROMPT > Creation PARTICIPATION...

CREATE TABLE PARTICIPATION (
    id_satellite   VARCHAR2(10) NOT NULL,
    id_mission     VARCHAR2(15) NOT NULL,
    role_satellite VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_participation     PRIMARY KEY (id_satellite, id_mission),
    CONSTRAINT fk_part_satellite    FOREIGN KEY (id_satellite) REFERENCES SATELLITE (id_satellite),
    CONSTRAINT fk_part_mission      FOREIGN KEY (id_mission)   REFERENCES MISSION (id_mission)
);


PROMPT
PROMPT ============================================================
PROMPT  Schema NanoOrbit cree : 11 tables.
PROMPT  Etape suivante : 02-dml-donnees.sql
PROMPT ============================================================
