-- =============================================================================
-- NANOORBIT — SCRIPT TRIGGERS METIER
-- Module BDOE633 — Administration et Optimisation des Bases de Données
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- =============================================================================
-- Ce script cree les 5 triggers metier qui implementent les regles de gestion
-- non exprimables par des contraintes statiques.
--
-- A executer APRES 02-dml-donnees.sql.
--
-- Recapitulatif :
--   T1 — trg_valider_fenetre      BEFORE INSERT ON FENETRE_COM   (RG-S06, RG-G03)
--   T2 — trg_no_chevauchement     BEFORE INS/UPD ON FENETRE_COM  (RG-F02, RG-F03)
--   T3 — trg_volume_realise       BEFORE INS/UPD ON FENETRE_COM  (RG-F05)
--   T4 — trg_mission_terminee     BEFORE INSERT ON PARTICIPATION (RG-M04)
--   T5 — trg_historique_statut    AFTER UPDATE OF statut ON SATELLITE
--
-- Codes d'erreur applicatifs :
--   ORA-20001 — satellite desorbite
--   ORA-20002 — station en maintenance
--   ORA-20003 — chevauchement de fenetres
--   ORA-20004 — mission terminee
-- =============================================================================

SET DEFINE OFF;

PROMPT ============================================================
PROMPT  NanoOrbit — Creation des 5 triggers metier
PROMPT ============================================================


-- ---------------------------------------------------------------------------
-- T1 — trg_valider_fenetre
-- BEFORE INSERT ON FENETRE_COM
-- Bloque la creation d'une fenetre si le satellite est desorbite (RG-S06)
-- ou si la station est en maintenance (RG-G03).
-- ---------------------------------------------------------------------------
PROMPT > Creation T1 - trg_valider_fenetre...

CREATE OR REPLACE TRIGGER trg_valider_fenetre
BEFORE INSERT ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_statut_sat     SATELLITE.statut%TYPE;
    v_statut_station STATION_SOL.statut%TYPE;
BEGIN
    SELECT statut INTO v_statut_sat
    FROM   SATELLITE
    WHERE  id_satellite = :NEW.id_satellite;

    IF v_statut_sat = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Satellite ' || :NEW.id_satellite ||
            ' désorbité : aucune fenêtre de communication possible (RG-S06).');
    END IF;

    SELECT statut INTO v_statut_station
    FROM   STATION_SOL
    WHERE  code_station = :NEW.code_station;

    IF v_statut_station = 'Maintenance' THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Station ' || :NEW.code_station ||
            ' en maintenance : aucune fenêtre de communication possible (RG-G03).');
    END IF;
END;
/
SHOW ERRORS


-- ---------------------------------------------------------------------------
-- T2 — trg_no_chevauchement
-- BEFORE INSERT OR UPDATE ON FENETRE_COM
-- Verifie l'absence de chevauchement temporel pour un meme satellite
-- et pour une meme station (RG-F02, RG-F03).
-- Une fenetre occupe l'intervalle [datetime_debut ; datetime_debut + duree].
-- ---------------------------------------------------------------------------
PROMPT > Creation T2 - trg_no_chevauchement...

CREATE OR REPLACE TRIGGER trg_no_chevauchement
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_conflits  NUMBER;
    v_fin_new   TIMESTAMP;
BEGIN
    v_fin_new := :NEW.datetime_debut + NUMTODSINTERVAL(:NEW.duree, 'SECOND');

    -- Chevauchement sur le meme satellite
    SELECT COUNT(*) INTO v_conflits
    FROM   FENETRE_COM f
    WHERE  f.id_satellite = :NEW.id_satellite
      AND  (:NEW.id_fenetre IS NULL OR f.id_fenetre <> :NEW.id_fenetre)
      AND  f.datetime_debut < v_fin_new
      AND  f.datetime_debut + NUMTODSINTERVAL(f.duree, 'SECOND') > :NEW.datetime_debut;

    IF v_conflits > 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Chevauchement de fenêtres pour le satellite ' ||
            :NEW.id_satellite || ' (RG-F02).');
    END IF;

    -- Chevauchement sur la meme station
    SELECT COUNT(*) INTO v_conflits
    FROM   FENETRE_COM f
    WHERE  f.code_station = :NEW.code_station
      AND  (:NEW.id_fenetre IS NULL OR f.id_fenetre <> :NEW.id_fenetre)
      AND  f.datetime_debut < v_fin_new
      AND  f.datetime_debut + NUMTODSINTERVAL(f.duree, 'SECOND') > :NEW.datetime_debut;

    IF v_conflits > 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Chevauchement de fenêtres pour la station ' ||
            :NEW.code_station || ' (RG-F03).');
    END IF;
END;
/
SHOW ERRORS


-- ---------------------------------------------------------------------------
-- T3 — trg_volume_realise
-- BEFORE INSERT OR UPDATE ON FENETRE_COM
-- Force volume_donnees a NULL si le statut de la fenetre est different
-- de 'Réalisée' (RG-F05). Correction silencieuse, sans erreur.
-- ---------------------------------------------------------------------------
PROMPT > Creation T3 - trg_volume_realise...

CREATE OR REPLACE TRIGGER trg_volume_realise
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
BEGIN
    IF :NEW.statut <> 'Réalisée' THEN
        :NEW.volume_donnees := NULL;
    END IF;
END;
/
SHOW ERRORS


-- ---------------------------------------------------------------------------
-- T4 — trg_mission_terminee
-- BEFORE INSERT ON PARTICIPATION
-- Bloque l'ajout d'un satellite a une mission dont le statut est 'Terminée'
-- (RG-M04).
-- ---------------------------------------------------------------------------
PROMPT > Creation T4 - trg_mission_terminee...

CREATE OR REPLACE TRIGGER trg_mission_terminee
BEFORE INSERT ON PARTICIPATION
FOR EACH ROW
DECLARE
    v_statut_mission MISSION.statut_mission%TYPE;
BEGIN
    SELECT statut_mission INTO v_statut_mission
    FROM   MISSION
    WHERE  id_mission = :NEW.id_mission;

    IF v_statut_mission = 'Terminée' THEN
        RAISE_APPLICATION_ERROR(-20004,
            'Mission ' || :NEW.id_mission ||
            ' terminée : ajout de satellite impossible (RG-M04).');
    END IF;
END;
/
SHOW ERRORS


-- ---------------------------------------------------------------------------
-- T5 — trg_historique_statut
-- AFTER UPDATE OF statut ON SATELLITE
-- Trace tout changement de statut dans la table HISTORIQUE_STATUT.
-- Ne fait rien si l'ancien et le nouveau statut sont identiques.
-- ---------------------------------------------------------------------------
PROMPT > Creation T5 - trg_historique_statut...

CREATE OR REPLACE TRIGGER trg_historique_statut
AFTER UPDATE OF statut ON SATELLITE
FOR EACH ROW
WHEN (OLD.statut <> NEW.statut)
BEGIN
    INSERT INTO HISTORIQUE_STATUT (id_satellite, ancien_statut, nouveau_statut, motif)
    VALUES (:NEW.id_satellite, :OLD.statut, :NEW.statut,
            'Changement de statut enregistré automatiquement');
END;
/
SHOW ERRORS


PROMPT
PROMPT ============================================================
PROMPT  5 triggers metier crees.
PROMPT  Etape suivante : 04-package.sql
PROMPT ============================================================
