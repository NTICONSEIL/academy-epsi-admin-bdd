-- =============================================================================
-- NANOORBIT — PACKAGE pkg_nanoOrbit
-- Module BDOE633 — Administration et Optimisation des Bases de Données
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- =============================================================================
-- Ce script cree le package pkg_nanoOrbit qui encapsule les operations metier
-- de la plateforme NanoOrbit (SPEC puis BODY).
--
-- A executer APRES 03-triggers.sql.
--
-- Les procedures s'appuient sur les triggers de la couche table :
--   - planifier_fenetre declenche T1, T2, T3 (INSERT dans FENETRE_COM)
--   - mettre_en_revision declenche T5 (UPDATE du statut SATELLITE)
-- =============================================================================

SET DEFINE OFF;

PROMPT ============================================================
PROMPT  NanoOrbit — Creation du package pkg_nanoOrbit
PROMPT ============================================================


-- ===========================================================================
-- SPEC — Interface publique du package
-- ===========================================================================
PROMPT > Creation de la SPEC...

CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS

    -- Type public : statistiques d'un satellite
    TYPE t_stats_satellite IS RECORD (
        nb_fenetres        NUMBER,
        volume_total       NUMBER,
        duree_moy_secondes NUMBER
    );

    -- Constantes metier
    c_statut_min_fenetre CONSTANT VARCHAR2(15) := 'Opérationnel';
    c_duree_max_fenetre  CONSTANT NUMBER       := 900;
    c_seuil_revision     CONSTANT NUMBER       := 50;

    -- Procedures
    PROCEDURE planifier_fenetre (
        p_id_satellite    IN  VARCHAR2,
        p_code_station    IN  VARCHAR2,
        p_datetime_debut  IN  TIMESTAMP,
        p_duree           IN  NUMBER,
        p_id_fenetre      OUT NUMBER
    );

    PROCEDURE cloturer_fenetre (
        p_id_fenetre     IN NUMBER,
        p_volume_donnees IN NUMBER
    );

    PROCEDURE affecter_satellite_mission (
        p_id_satellite IN VARCHAR2,
        p_id_mission   IN VARCHAR2,
        p_role         IN VARCHAR2
    );

    PROCEDURE mettre_en_revision (
        p_id_satellite IN VARCHAR2
    );

    -- Fonctions
    FUNCTION calculer_volume_theorique (
        p_id_fenetre IN NUMBER
    ) RETURN NUMBER;

    FUNCTION statut_constellation RETURN VARCHAR2;

    FUNCTION stats_satellite (
        p_id_satellite IN VARCHAR2
    ) RETURN t_stats_satellite;

END pkg_nanoOrbit;
/
SHOW ERRORS


-- ===========================================================================
-- BODY — Implementation
-- ===========================================================================
PROMPT > Creation du BODY...

CREATE OR REPLACE PACKAGE BODY pkg_nanoOrbit AS

    -- -----------------------------------------------------------------------
    -- planifier_fenetre : cree une nouvelle fenetre de communication.
    -- L'INSERT declenche les triggers T1 (validation), T2 (chevauchement),
    -- T3 (volume force a NULL car statut 'Planifiée').
    -- -----------------------------------------------------------------------
    PROCEDURE planifier_fenetre (
        p_id_satellite    IN  VARCHAR2,
        p_code_station    IN  VARCHAR2,
        p_datetime_debut  IN  TIMESTAMP,
        p_duree           IN  NUMBER,
        p_id_fenetre      OUT NUMBER
    ) IS
    BEGIN
        IF p_duree < 1 OR p_duree > c_duree_max_fenetre THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Durée invalide : doit être comprise entre 1 et ' ||
                c_duree_max_fenetre || ' secondes.');
        END IF;

        INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max,
                                 volume_donnees, statut, id_satellite, code_station)
        VALUES (p_datetime_debut, p_duree, 0, NULL, 'Planifiée',
                p_id_satellite, p_code_station)
        RETURNING id_fenetre INTO p_id_fenetre;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20011,
                'Satellite ou station introuvable.');
    END planifier_fenetre;


    -- -----------------------------------------------------------------------
    -- cloturer_fenetre : passe une fenetre au statut 'Réalisée' et enregistre
    -- le volume de donnees telecharge.
    -- -----------------------------------------------------------------------
    PROCEDURE cloturer_fenetre (
        p_id_fenetre     IN NUMBER,
        p_volume_donnees IN NUMBER
    ) IS
    BEGIN
        IF p_volume_donnees < 0 THEN
            RAISE_APPLICATION_ERROR(-20012,
                'Le volume de données ne peut pas être négatif.');
        END IF;

        UPDATE FENETRE_COM
        SET    statut         = 'Réalisée',
               volume_donnees = p_volume_donnees
        WHERE  id_fenetre = p_id_fenetre;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013,
                'Fenêtre ' || p_id_fenetre || ' introuvable.');
        END IF;
    END cloturer_fenetre;


    -- -----------------------------------------------------------------------
    -- affecter_satellite_mission : ajoute un satellite a une mission.
    -- L'INSERT declenche le trigger T4 (mission terminee).
    -- -----------------------------------------------------------------------
    PROCEDURE affecter_satellite_mission (
        p_id_satellite IN VARCHAR2,
        p_id_mission   IN VARCHAR2,
        p_role         IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
        VALUES (p_id_satellite, p_id_mission, p_role);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20014,
                'Le satellite ' || p_id_satellite ||
                ' participe déjà à la mission ' || p_id_mission || '.');
    END affecter_satellite_mission;


    -- -----------------------------------------------------------------------
    -- mettre_en_revision : passe un satellite au statut 'En veille'.
    -- L'UPDATE declenche le trigger T5 (historisation du statut).
    -- -----------------------------------------------------------------------
    PROCEDURE mettre_en_revision (
        p_id_satellite IN VARCHAR2
    ) IS
    BEGIN
        UPDATE SATELLITE
        SET    statut = 'En veille'
        WHERE  id_satellite = p_id_satellite;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20015,
                'Satellite ' || p_id_satellite || ' introuvable.');
        END IF;
    END mettre_en_revision;


    -- -----------------------------------------------------------------------
    -- calculer_volume_theorique : volume theorique d'une fenetre
    -- = debit max de la station (Mbps) x duree (s) / 8, en mega-octets.
    -- -----------------------------------------------------------------------
    FUNCTION calculer_volume_theorique (
        p_id_fenetre IN NUMBER
    ) RETURN NUMBER IS
        v_debit  STATION_SOL.debit_max%TYPE;
        v_duree  FENETRE_COM.duree%TYPE;
    BEGIN
        SELECT s.debit_max, f.duree
        INTO   v_debit, v_duree
        FROM   FENETRE_COM f
        JOIN   STATION_SOL s ON s.code_station = f.code_station
        WHERE  f.id_fenetre = p_id_fenetre;

        RETURN ROUND(v_debit * v_duree / 8, 2);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END calculer_volume_theorique;


    -- -----------------------------------------------------------------------
    -- statut_constellation : resume textuel de l'etat de la constellation.
    -- -----------------------------------------------------------------------
    FUNCTION statut_constellation RETURN VARCHAR2 IS
        v_total       NUMBER;
        v_operationnels NUMBER;
        v_missions    NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total FROM SATELLITE;

        SELECT COUNT(*) INTO v_operationnels
        FROM   SATELLITE WHERE statut = 'Opérationnel';

        SELECT COUNT(*) INTO v_missions
        FROM   MISSION WHERE statut_mission = 'Active';

        RETURN v_operationnels || '/' || v_total ||
               ' satellites opérationnels, ' ||
               v_missions || ' missions actives';
    END statut_constellation;


    -- -----------------------------------------------------------------------
    -- stats_satellite : statistiques de communication d'un satellite
    -- (nombre de fenetres realisees, volume total, duree moyenne).
    -- -----------------------------------------------------------------------
    FUNCTION stats_satellite (
        p_id_satellite IN VARCHAR2
    ) RETURN t_stats_satellite IS
        v_stats t_stats_satellite;
    BEGIN
        SELECT COUNT(*),
               NVL(SUM(volume_donnees), 0),
               NVL(ROUND(AVG(duree), 1), 0)
        INTO   v_stats.nb_fenetres,
               v_stats.volume_total,
               v_stats.duree_moy_secondes
        FROM   FENETRE_COM
        WHERE  id_satellite = p_id_satellite
          AND  statut = 'Réalisée';

        RETURN v_stats;
    END stats_satellite;

END pkg_nanoOrbit;
/
SHOW ERRORS


PROMPT
PROMPT ============================================================
PROMPT  Package pkg_nanoOrbit cree (SPEC + BODY).
PROMPT  Initialisation du schema NanoOrbit terminee.
PROMPT ============================================================
