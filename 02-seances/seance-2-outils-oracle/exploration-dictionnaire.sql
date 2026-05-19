-- =============================================================================
-- NANOORBIT — EXPLORATION DU DICTIONNAIRE DE DONNEES
-- Module BDOE633 — Seance 2 — Plan d'administration et outils Oracle
-- =============================================================================
-- Script de demonstration et d'exploration de la base NanoOrbit.
-- A executer connecte en tant que NANOORBIT_ADMIN sur FREEPDB1.
--
-- Objectif pedagogique : decouvrir une base que l'on herite en s'appuyant sur
-- le dictionnaire de donnees Oracle. Chaque requete repond a une question
-- concrete de l'administrateur qui prend possession de la base.
--
-- Ce script ne MODIFIE rien : il ne fait que lire le dictionnaire.
-- =============================================================================

SET LINESIZE 120
SET PAGESIZE 50
SET SERVEROUTPUT ON
SET SQLBLANKLINES ON

PROMPT
PROMPT ============================================================
PROMPT  EXPLORATION DE LA BASE NANOORBIT
PROMPT ============================================================


-- ===========================================================================
-- 1. QUI SUIS-JE, OU SUIS-JE ?
-- ===========================================================================
PROMPT
PROMPT --- 1.1 Utilisateur et base courante ---
SELECT USER                                   AS schema_courant,
       SYS_CONTEXT('USERENV','CON_NAME')       AS pluggable_database,
       SYS_CONTEXT('USERENV','DB_NAME')        AS instance
FROM   DUAL;

PROMPT
PROMPT --- 1.2 Version d'Oracle ---
SELECT banner_full AS version_oracle FROM v$version;


-- ===========================================================================
-- 2. QUELLES TABLES COMPOSENT LA BASE ?
-- ===========================================================================
PROMPT
PROMPT --- 2.1 Liste des tables et nombre de lignes ---
-- num_rows provient des statistiques ; il peut etre vide si les statistiques
-- n'ont jamais ete calculees. Voir requete 2.2 pour un comptage exact.
SELECT table_name, num_rows, tablespace_name
FROM   user_tables
ORDER  BY table_name;

PROMPT
PROMPT --- 2.2 Comptage exact des lignes par table ---
-- Note : 'UNION ALL' est place en fin de ligne. Place en debut de ligne,
-- SQL*Plus l'interpreterait a tort comme une nouvelle commande (SP2-0734).
SELECT table_nom, nb_lignes FROM (
    SELECT 'ORBITE'              AS table_nom, COUNT(*) AS nb_lignes FROM ORBITE UNION ALL
    SELECT 'SATELLITE',           COUNT(*) FROM SATELLITE           UNION ALL
    SELECT 'INSTRUMENT',          COUNT(*) FROM INSTRUMENT          UNION ALL
    SELECT 'EMBARQUEMENT',        COUNT(*) FROM EMBARQUEMENT        UNION ALL
    SELECT 'CENTRE_CONTROLE',     COUNT(*) FROM CENTRE_CONTROLE     UNION ALL
    SELECT 'STATION_SOL',         COUNT(*) FROM STATION_SOL         UNION ALL
    SELECT 'AFFECTATION_STATION', COUNT(*) FROM AFFECTATION_STATION UNION ALL
    SELECT 'MISSION',             COUNT(*) FROM MISSION             UNION ALL
    SELECT 'FENETRE_COM',         COUNT(*) FROM FENETRE_COM         UNION ALL
    SELECT 'PARTICIPATION',       COUNT(*) FROM PARTICIPATION       UNION ALL
    SELECT 'HISTORIQUE_STATUT',   COUNT(*) FROM HISTORIQUE_STATUT
)
ORDER BY table_nom;


-- ===========================================================================
-- 3. COMMENT LE STOCKAGE EST-IL ORGANISE ?
-- ===========================================================================
PROMPT
PROMPT --- 3.1 Occupation disque reelle par segment ---
-- USER_SEGMENTS donne la taille physiquement allouee a chaque objet.
SELECT segment_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024, 2) AS taille_mo
FROM   user_segments
ORDER  BY bytes DESC;

PROMPT
PROMPT --- 3.2 Repartition des objets par tablespace ---
-- Point d'attention : a la livraison, toutes les tables sont dans le meme
-- tablespace. La reorganisation par famille de donnees est l'objet de la seance 3.
SELECT tablespace_name,
       segment_type,
       COUNT(*)                  AS nb_objets,
       ROUND(SUM(bytes)/1024/1024, 2) AS total_mo
FROM   user_segments
GROUP  BY tablespace_name, segment_type
ORDER  BY tablespace_name, segment_type;

PROMPT
PROMPT --- 3.3 Fichiers de donnees et tablespaces de l'instance ---
SELECT tablespace_name,
       file_name,
       ROUND(bytes/1024/1024, 2)      AS taille_mo,
       autoextensible
FROM   dba_data_files
ORDER  BY tablespace_name;


-- ===========================================================================
-- 4. QUELLE EST LA STRUCTURE DES TABLES ?
-- ===========================================================================
PROMPT
PROMPT --- 4.1 Contraintes par table (P=PK, R=FK, C=CHECK, U=UNIQUE) ---
SELECT table_name,
       constraint_type,
       COUNT(*) AS nb_contraintes
FROM   user_constraints
WHERE  constraint_type IN ('P','R','C','U')
GROUP  BY table_name, constraint_type
ORDER  BY table_name, constraint_type;

PROMPT
PROMPT --- 4.2 Cles etrangeres : qui depend de qui ? ---
SELECT c.table_name           AS table_enfant,
       c.constraint_name      AS nom_fk,
       r.table_name           AS table_parent
FROM   user_constraints c
JOIN   user_constraints r ON c.r_constraint_name = r.constraint_name
WHERE  c.constraint_type = 'R'
ORDER  BY c.table_name;

PROMPT
PROMPT --- 4.3 Index existants ---
-- A la livraison, seuls les index des cles primaires et contraintes UNIQUE
-- existent. L'ajout d'index pour la performance sera etudie en seance 6.
SELECT table_name,
       index_name,
       uniqueness
FROM   user_indexes
ORDER  BY table_name, index_name;


-- ===========================================================================
-- 5. QUELS MECANISMES ACTIFS PROTEGENT LES DONNEES ?
-- ===========================================================================
PROMPT
PROMPT --- 5.1 Triggers metier ---
SELECT trigger_name,
       triggering_event,
       table_name,
       status
FROM   user_triggers
ORDER  BY trigger_name;

PROMPT
PROMPT --- 5.2 Objets programmes (package) ---
SELECT object_name,
       object_type,
       status
FROM   user_objects
WHERE  object_type IN ('PACKAGE','PACKAGE BODY')
ORDER  BY object_name, object_type;


-- ===========================================================================
-- 6. QUELLE EST L'ACTIVITE SUR L'INSTANCE ?
-- ===========================================================================
PROMPT
PROMPT --- 6.1 Sessions actives ---
-- V$SESSION donne une photographie des connexions en cours.
SELECT sid,
       username,
       status,
       machine,
       program
FROM   v$session
WHERE  username IS NOT NULL
ORDER  BY username, sid;

PROMPT
PROMPT --- 6.2 Date et mode de la base ---
SELECT name        AS base,
       log_mode    AS mode_archivage,
       open_mode   AS mode_ouverture
FROM   v$database;


-- ===========================================================================
-- 7. APERCU METIER DE LA BASE NANOORBIT
-- ===========================================================================
PROMPT
PROMPT --- 7.1 Repartition des satellites par statut ---
SELECT statut, COUNT(*) AS nb
FROM   SATELLITE
GROUP  BY statut
ORDER  BY statut;

PROMPT
PROMPT --- 7.2 Repartition des fenetres de communication par statut ---
SELECT statut, COUNT(*) AS nb, NVL(SUM(volume_donnees),0) AS volume_total_mo
FROM   FENETRE_COM
GROUP  BY statut
ORDER  BY statut;

PROMPT
PROMPT --- 7.3 Volume telecharge par centre de controle ---
SELECT cc.nom_centre,
       COUNT(f.id_fenetre)            AS nb_fenetres,
       NVL(SUM(f.volume_donnees), 0)  AS volume_total_mo
FROM   CENTRE_CONTROLE cc
JOIN   AFFECTATION_STATION a ON a.id_centre   = cc.id_centre
JOIN   STATION_SOL s         ON s.code_station = a.code_station
LEFT JOIN FENETRE_COM f      ON f.code_station = s.code_station
                            AND f.statut = 'Réalisée'
GROUP  BY cc.nom_centre
ORDER  BY cc.nom_centre;


PROMPT
PROMPT ============================================================
PROMPT  FIN DE L'EXPLORATION
PROMPT
PROMPT  A partir de ces constats, completez la trame du plan
PROMPT  d'administration (trame-plan-administration.md).
PROMPT ============================================================
