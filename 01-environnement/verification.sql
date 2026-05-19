-- =============================================================================
-- NANOORBIT — SCRIPT DE VERIFICATION POST-INSTALLATION
-- Module BDOE633 — Administration et Optimisation des Bases de Données
-- =============================================================================
-- A executer connecte en tant que NANOORBIT_ADMIN sur FREEPDB1.
-- Verifie que la base NanoOrbit est correctement initialisee.
--
-- Resultats attendus :
--   Tables ............. 11
--   Triggers ............ 5
--   Package (SPEC+BODY) . 2
--   Lignes totales ...... 43  (hors HISTORIQUE_STATUT)
-- =============================================================================

SET SERVEROUTPUT ON;
SET LINESIZE 100;
SET PAGESIZE 50;
SET SQLBLANKLINES ON;

PROMPT
PROMPT ============================================================
PROMPT  VERIFICATION DE L'ENVIRONNEMENT NANOORBIT
PROMPT ============================================================
PROMPT

-- ---------------------------------------------------------------------------
-- 1. Utilisateur connecte
-- ---------------------------------------------------------------------------
PROMPT --- Utilisateur connecte ---
SELECT USER AS utilisateur_courant FROM DUAL;

-- ---------------------------------------------------------------------------
-- 2. Objets du schema
-- ---------------------------------------------------------------------------
PROMPT
PROMPT --- Objets du schema (attendu : 11 tables, 5 triggers, 2 packages) ---
SELECT object_type, COUNT(*) AS nombre
FROM   user_objects
WHERE  object_type IN ('TABLE','TRIGGER','PACKAGE','PACKAGE BODY','INDEX')
GROUP  BY object_type
ORDER  BY object_type;

-- ---------------------------------------------------------------------------
-- 3. Objets invalides (attendu : aucune ligne)
-- ---------------------------------------------------------------------------
PROMPT
PROMPT --- Objets invalides (attendu : aucun) ---
SELECT object_name, object_type, status
FROM   user_objects
WHERE  status <> 'VALID';

-- ---------------------------------------------------------------------------
-- 4. Volumetrie des tables peuplees
-- ---------------------------------------------------------------------------
PROMPT
PROMPT --- Volumetrie par table (attendu : 43 lignes au total) ---
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

-- ---------------------------------------------------------------------------
-- 5. Controle de coherence metier
-- ---------------------------------------------------------------------------
PROMPT
PROMPT --- Repartition des satellites par statut ---
SELECT statut, COUNT(*) AS nb FROM SATELLITE GROUP BY statut ORDER BY statut;

PROMPT
PROMPT --- Repartition des fenetres de communication par statut ---
SELECT statut, COUNT(*) AS nb FROM FENETRE_COM GROUP BY statut ORDER BY statut;

-- ---------------------------------------------------------------------------
-- 6. Test fonctionnel du package
-- ---------------------------------------------------------------------------
PROMPT
PROMPT --- Test du package pkg_nanoOrbit ---
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('statut_constellation : ' ||
        pkg_nanoOrbit.statut_constellation);
END;
/

-- ---------------------------------------------------------------------------
-- 7. Bilan
-- ---------------------------------------------------------------------------
PROMPT
DECLARE
    v_tables   NUMBER;
    v_triggers NUMBER;
    v_packages NUMBER;
    v_lignes   NUMBER;
    v_invalides NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_tables   FROM user_tables;
    SELECT COUNT(*) INTO v_triggers FROM user_triggers;
    SELECT COUNT(*) INTO v_packages FROM user_objects
        WHERE object_type IN ('PACKAGE','PACKAGE BODY');
    SELECT COUNT(*) INTO v_invalides FROM user_objects WHERE status <> 'VALID';

    SELECT (SELECT COUNT(*) FROM ORBITE)
         + (SELECT COUNT(*) FROM SATELLITE)
         + (SELECT COUNT(*) FROM INSTRUMENT)
         + (SELECT COUNT(*) FROM EMBARQUEMENT)
         + (SELECT COUNT(*) FROM CENTRE_CONTROLE)
         + (SELECT COUNT(*) FROM STATION_SOL)
         + (SELECT COUNT(*) FROM AFFECTATION_STATION)
         + (SELECT COUNT(*) FROM MISSION)
         + (SELECT COUNT(*) FROM FENETRE_COM)
         + (SELECT COUNT(*) FROM PARTICIPATION)
    INTO v_lignes FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  BILAN DE VERIFICATION');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('  Tables             : ' || v_tables   || '   (attendu : 11)');
    DBMS_OUTPUT.PUT_LINE('  Triggers           : ' || v_triggers || '   (attendu : 5)');
    DBMS_OUTPUT.PUT_LINE('  Package SPEC+BODY  : ' || v_packages || '   (attendu : 2)');
    DBMS_OUTPUT.PUT_LINE('  Lignes (10 tables) : ' || v_lignes   || '  (attendu : 43)');
    DBMS_OUTPUT.PUT_LINE('  Objets invalides   : ' || v_invalides|| '   (attendu : 0)');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');

    IF v_tables = 11 AND v_triggers = 5 AND v_packages = 2
       AND v_lignes = 43 AND v_invalides = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  RESULTAT : environnement NanoOrbit CONFORME.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  RESULTAT : ANOMALIE detectee — verifier les scripts init.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('============================================================');
END;
/
