-- =============================================================================
-- NANOORBIT — RÉORGANISATION DES TABLESPACES
-- Module BDOE633 — Séance 3 — CORRIGÉ INSTRUCTEUR
-- Livrable L1-C — Ne pas distribuer aux apprenants avant évaluation
-- =============================================================================

-- Connexion requise : SYSTEM / NanoOrbit_Sys2026 @ localhost:1521/FREEPDB1


-- ===========================================================================
-- ÉTAPE 1 — CRÉATION DES TABLESPACES
-- ===========================================================================

-- Tablespace pour les données RÉFÉRENTIEL (stables, RPO 24h)
CREATE TABLESPACE TBS_REFERENTIEL
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/tbs_referentiel.dbf'
  SIZE 10M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

-- Tablespace pour les données OPÉRATIONNELLES (vivantes, RPO 15 min)
CREATE TABLESPACE TBS_OPERATION
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/tbs_operation.dbf'
  SIZE 10M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

-- Tablespace pour les données HISTORIQUES (croissance continue, RPO 24h)
CREATE TABLESPACE TBS_HISTORIQUE
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/tbs_historique.dbf'
  SIZE 10M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M;


-- ===========================================================================
-- ÉTAPE 2 — DÉPLACEMENT DES TABLES
-- ===========================================================================
-- Famille RÉFÉRENTIEL → TBS_REFERENTIEL
ALTER TABLE NANOORBIT_ADMIN.ORBITE            MOVE TABLESPACE TBS_REFERENTIEL;
ALTER TABLE NANOORBIT_ADMIN.INSTRUMENT        MOVE TABLESPACE TBS_REFERENTIEL;
ALTER TABLE NANOORBIT_ADMIN.CENTRE_CONTROLE   MOVE TABLESPACE TBS_REFERENTIEL;
ALTER TABLE NANOORBIT_ADMIN.STATION_SOL       MOVE TABLESPACE TBS_REFERENTIEL;
ALTER TABLE NANOORBIT_ADMIN.MISSION           MOVE TABLESPACE TBS_REFERENTIEL;

-- Famille OPÉRATIONNELLE → TBS_OPERATION
ALTER TABLE NANOORBIT_ADMIN.SATELLITE           MOVE TABLESPACE TBS_OPERATION;
ALTER TABLE NANOORBIT_ADMIN.EMBARQUEMENT        MOVE TABLESPACE TBS_OPERATION;
ALTER TABLE NANOORBIT_ADMIN.AFFECTATION_STATION MOVE TABLESPACE TBS_OPERATION;
ALTER TABLE NANOORBIT_ADMIN.PARTICIPATION       MOVE TABLESPACE TBS_OPERATION;
ALTER TABLE NANOORBIT_ADMIN.FENETRE_COM         MOVE TABLESPACE TBS_OPERATION;

-- Famille HISTORIQUE → TBS_HISTORIQUE
ALTER TABLE NANOORBIT_ADMIN.HISTORIQUE_STATUT MOVE TABLESPACE TBS_HISTORIQUE;


-- ===========================================================================
-- ÉTAPE 3 — RECONSTRUCTION DES INDEX
-- ===========================================================================
-- Chaque MOVE invalide les index → REBUILD obligatoire dans le nouveau tablespace

-- Index de ORBITE → TBS_REFERENTIEL
ALTER INDEX NANOORBIT_ADMIN.PK_ORBITE         REBUILD TABLESPACE TBS_REFERENTIEL;
ALTER INDEX NANOORBIT_ADMIN.UQ_ORBITE_ALT_INC REBUILD TABLESPACE TBS_REFERENTIEL;

-- Index de INSTRUMENT → TBS_REFERENTIEL
ALTER INDEX NANOORBIT_ADMIN.PK_INSTRUMENT     REBUILD TABLESPACE TBS_REFERENTIEL;

-- Index de CENTRE_CONTROLE → TBS_REFERENTIEL
ALTER INDEX NANOORBIT_ADMIN.PK_CENTRE         REBUILD TABLESPACE TBS_REFERENTIEL;

-- Index de STATION_SOL → TBS_REFERENTIEL
ALTER INDEX NANOORBIT_ADMIN.PK_STATION        REBUILD TABLESPACE TBS_REFERENTIEL;

-- Index de MISSION → TBS_REFERENTIEL
ALTER INDEX NANOORBIT_ADMIN.PK_MISSION        REBUILD TABLESPACE TBS_REFERENTIEL;

-- Index de SATELLITE → TBS_OPERATION
ALTER INDEX NANOORBIT_ADMIN.PK_SATELLITE      REBUILD TABLESPACE TBS_OPERATION;

-- Index de EMBARQUEMENT → TBS_OPERATION
ALTER INDEX NANOORBIT_ADMIN.PK_EMBARQUEMENT   REBUILD TABLESPACE TBS_OPERATION;

-- Index de AFFECTATION_STATION → TBS_OPERATION
ALTER INDEX NANOORBIT_ADMIN.PK_AFFECTATION    REBUILD TABLESPACE TBS_OPERATION;

-- Index de PARTICIPATION → TBS_OPERATION
ALTER INDEX NANOORBIT_ADMIN.PK_PARTICIPATION  REBUILD TABLESPACE TBS_OPERATION;

-- Index de FENETRE_COM → TBS_OPERATION
ALTER INDEX NANOORBIT_ADMIN.PK_FENETRE        REBUILD TABLESPACE TBS_OPERATION;

-- Index de HISTORIQUE_STATUT → TBS_HISTORIQUE
ALTER INDEX NANOORBIT_ADMIN.PK_HISTORIQUE     REBUILD TABLESPACE TBS_HISTORIQUE;


-- ===========================================================================
-- ÉTAPE 4 — VÉRIFICATION
-- ===========================================================================
-- Contrôle 1 : répartition des tables (résultat attendu : TBS_HISTORIQUE=1, TBS_OPERATION=5, TBS_REFERENTIEL=5)
SELECT t.tablespace_name, COUNT(*) AS nb_tables
FROM dba_tables t
WHERE t.owner = 'NANOORBIT_ADMIN'
AND t.tablespace_name IN ('TBS_REFERENTIEL','TBS_OPERATION','TBS_HISTORIQUE')
GROUP BY t.tablespace_name
ORDER BY t.tablespace_name;

-- Contrôle 2 : aucun index UNUSABLE (résultat attendu : 0 ligne)
SELECT index_name, status
FROM dba_indexes
WHERE owner = 'NANOORBIT_ADMIN'
AND status = 'UNUSABLE';

-- =============================================================================
-- NOTES INSTRUCTEUR
-- =============================================================================
-- Connexion : ce script doit être exécuté en tant que SYSTEM (pas NANOORBIT_ADMIN)
-- car CREATE TABLESPACE et ALTER TABLE … MOVE sur un autre schéma requièrent
-- des privilèges DBA.
--
-- Erreur fréquente : oublier le REBUILD après le MOVE.
-- Symptôme : ORA-01502 "index … is in unusable state" à la prochaine écriture.
-- Correction : relancer les ALTER INDEX … REBUILD manquants.
--
-- Erreur fréquente : exécuter en tant que NANOORBIT_ADMIN → ORA-01031 (droits insuffisants)
-- =============================================================================
