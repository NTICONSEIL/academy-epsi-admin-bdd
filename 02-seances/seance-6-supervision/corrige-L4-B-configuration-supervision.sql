-- ==============================================================
-- CORRIGÉ L4-B — Configuration supervision Oracle · NanoOrbit
-- ==============================================================
-- Livrable L4-B — Corrigé instructeur
-- Usage interne EPSI. Ne pas distribuer avant évaluation.
--
-- Compétences : ASRBD1.7 · ASRBD1.8
-- Séance 6 — FOAD · BDOE633
--
-- Prérequis :
--   - Instance Oracle 23ai Free · conteneur nanoorbit-oracle
--   - PDB FREEPDB1 · schéma NANOORBIT_ADMIN
--   - Connexion SYS requise pour DBMS_SERVER_ALERT et V$ système
--
-- Exécution recommandée :
--   Étape 1 : connexion SYS (service FREE, CDB)
--     sqlplus sys/NanoOrbit_Sys2026@localhost:1521/FREE as sysdba
--   Étape 2 : connexion sur FREEPDB1 pour requêtes V$
--     ALTER SESSION SET CONTAINER = FREEPDB1;
--     -- ou connexion directe :
--     -- sqlplus sys/NanoOrbit_Sys2026@localhost:1521/FREEPDB1 as sysdba
-- ==============================================================


-- ==============================================================
-- PARTIE 1 — VÉRIFICATION PRÉALABLE DE L'ÉTAT DE L'INSTANCE
-- ==============================================================
-- Objectif : s'assurer que la base est en état nominal avant
-- de configurer la supervision.

-- 1.1 État de l'instance
SELECT instance_name,
       status,
       database_status,
       logins,
       TO_CHAR(startup_time, 'DD/MM/YYYY HH24:MI') startup
FROM   v$instance;
-- Résultat attendu : STATUS=OPEN, DATABASE_STATUS=ACTIVE, LOGINS=ALLOWED

-- 1.2 Mode archivelog (prérequis RPO 15 min)
SELECT log_mode FROM v$database;
-- Résultat attendu : ARCHIVELOG
-- Si NOARCHIVELOG : cf. procédure séance 5 pour activer

-- 1.3 Dernier archivage (vérification fraîcheur)
SELECT TO_CHAR(MAX(completion_time), 'DD/MM/YYYY HH24:MI:SS') dernier_archivage,
       COUNT(*) nb_archives_24h
FROM   v$archived_log
WHERE  completion_time > SYSDATE - 1;
-- Un archivage toutes les ~15 min est attendu si la base est active


-- ==============================================================
-- PARTIE 2 — OCCUPATION DES TABLESPACES NANOORBIT
-- ==============================================================
-- KPI 2 : surveillance de TBS_OPERATION, TBS_REFERENTIEL, TBS_HISTORIQUE

-- 2.1 État actuel des tablespaces NanoOrbit
SELECT t.tablespace_name,
       ROUND(t.total_mb, 1)                                          total_mb,
       ROUND(t.total_mb - NVL(f.free_mb, 0), 1)                     used_mb,
       ROUND(NVL(f.free_mb, 0), 1)                                   free_mb,
       ROUND((1 - NVL(f.free_mb, 0) / t.total_mb) * 100, 1)        pct_used,
       CASE
         WHEN (1 - NVL(f.free_mb, 0) / t.total_mb) >= 0.90 THEN '*** CRITICAL ***'
         WHEN (1 - NVL(f.free_mb, 0) / t.total_mb) >= 0.80 THEN '!  WARNING  !'
         ELSE 'OK'
       END AS statut
FROM (
    SELECT tablespace_name, SUM(bytes) / 1048576 total_mb
    FROM   dba_data_files
    GROUP BY tablespace_name
) t
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes) / 1048576 free_mb
    FROM   dba_free_space
    GROUP BY tablespace_name
) f ON t.tablespace_name = f.tablespace_name
WHERE  t.tablespace_name IN ('TBS_OPERATION', 'TBS_REFERENTIEL', 'TBS_HISTORIQUE')
ORDER BY pct_used DESC;

-- 2.2 Configuration des alertes automatiques Oracle (DBMS_SERVER_ALERT)
-- Exécuter en tant que SYS sur FREEPDB1

BEGIN
  -- Alerte sur TBS_OPERATION (famille opérationnelle — critique RPO/RTO)
  DBMS_SERVER_ALERT.SET_THRESHOLD(
    metrics_id              => DBMS_SERVER_ALERT.TABLESPACE_PCT_FULL,
    warning_operator        => DBMS_SERVER_ALERT.OPERATOR_GE,
    warning_value           => '80',
    critical_operator       => DBMS_SERVER_ALERT.OPERATOR_GE,
    critical_value          => '90',
    observation_period      => 1,
    consecutive_occurrences => 1,
    instance_name           => NULL,
    object_type             => DBMS_SERVER_ALERT.OBJECT_TYPE_TABLESPACE,
    object_name             => 'TBS_OPERATION'
  );

  -- Alerte sur TBS_HISTORIQUE (croissance continue)
  DBMS_SERVER_ALERT.SET_THRESHOLD(
    metrics_id              => DBMS_SERVER_ALERT.TABLESPACE_PCT_FULL,
    warning_operator        => DBMS_SERVER_ALERT.OPERATOR_GE,
    warning_value           => '80',
    critical_operator       => DBMS_SERVER_ALERT.OPERATOR_GE,
    critical_value          => '90',
    observation_period      => 1,
    consecutive_occurrences => 1,
    instance_name           => NULL,
    object_type             => DBMS_SERVER_ALERT.OBJECT_TYPE_TABLESPACE,
    object_name             => 'TBS_HISTORIQUE'
  );

  -- Alerte sur TBS_REFERENTIEL (données stables mais protéger SLA 99,9%)
  DBMS_SERVER_ALERT.SET_THRESHOLD(
    metrics_id              => DBMS_SERVER_ALERT.TABLESPACE_PCT_FULL,
    warning_operator        => DBMS_SERVER_ALERT.OPERATOR_GE,
    warning_value           => '80',
    critical_operator       => DBMS_SERVER_ALERT.OPERATOR_GE,
    critical_value          => '90',
    observation_period      => 1,
    consecutive_occurrences => 1,
    instance_name           => NULL,
    object_type             => DBMS_SERVER_ALERT.OBJECT_TYPE_TABLESPACE,
    object_name             => 'TBS_REFERENTIEL'
  );

  DBMS_OUTPUT.PUT_LINE('Alertes tablespaces NanoOrbit configurées avec succès.');
END;
/

-- 2.3 Vérification que les seuils sont bien enregistrés
SELECT object_name,
       metrics_name,
       warning_value,
       critical_value,
       observation_period
FROM   dba_thresholds
WHERE  object_name IN ('TBS_OPERATION', 'TBS_HISTORIQUE', 'TBS_REFERENTIEL')
ORDER BY object_name;
-- 3 lignes attendues, une par tablespace


-- ==============================================================
-- PARTIE 3 — SURVEILLANCE DES SESSIONS ACTIVES
-- ==============================================================
-- KPI 4 : détection de saturation du pool de connexions

-- 3.1 Comptage en temps réel
SELECT COUNT(*) nb_sessions_actives
FROM   v$session
WHERE  status   = 'ACTIVE'
  AND  username IS NOT NULL;
-- Seuil WARNING > 50, CRITICAL > 80

-- 3.2 Détail des sessions longues et blocages
SELECT s.sid,
       s.serial#,
       s.username,
       s.status,
       s.last_call_et                           secondes_actives,
       s.blocking_session,
       SUBSTR(s.module, 1, 30)                  module,
       SUBSTR(q.sql_text, 1, 100)               sql_en_cours
FROM   v$session s
LEFT JOIN v$sql q ON s.sql_id = q.sql_id
WHERE  s.status      = 'ACTIVE'
  AND  s.username    IS NOT NULL
  AND  s.last_call_et > 30            -- requêtes actives depuis > 30 secondes
ORDER BY s.last_call_et DESC;

-- 3.3 Configuration alerte DBMS_SERVER_ALERT sur le nombre de sessions
BEGIN
  DBMS_SERVER_ALERT.SET_THRESHOLD(
    metrics_id              => DBMS_SERVER_ALERT.CURRENT_LOGONS_COUNT,
    warning_operator        => DBMS_SERVER_ALERT.OPERATOR_GE,
    warning_value           => '50',
    critical_operator       => DBMS_SERVER_ALERT.OPERATOR_GE,
    critical_value          => '80',
    observation_period      => 1,
    consecutive_occurrences => 2,
    instance_name           => NULL,
    object_type             => DBMS_SERVER_ALERT.OBJECT_TYPE_SERVICE,
    object_name             => NULL
  );
  DBMS_OUTPUT.PUT_LINE('Alerte sessions actives configurée.');
END;
/


-- ==============================================================
-- PARTIE 4 — SURVEILLANCE DES PERFORMANCES DES REQUÊTES
-- ==============================================================
-- KPI 3 : latence INSERT FENETRE_COM
-- KPI 5 : temps d'exécution pkg_nanoOrbit

-- 4.1 Requêtes les plus coûteuses sur FENETRE_COM
SELECT sql_id,
       ROUND(elapsed_time / NULLIF(executions, 0) / 1000, 1)    avg_ms,
       ROUND(cpu_time     / NULLIF(executions, 0) / 1000, 1)    avg_cpu_ms,
       executions,
       buffer_gets,
       SUBSTR(sql_text, 1, 100) sql_extrait
FROM   v$sql
WHERE  UPPER(sql_text) LIKE '%FENETRE_COM%'
  AND  executions > 0
ORDER BY avg_ms DESC
FETCH FIRST 10 ROWS ONLY;
-- Seuil WARNING : avg_ms > 200, CRITICAL : avg_ms > 500

-- 4.2 Performances du package pkg_nanoOrbit
SELECT sql_id,
       ROUND(elapsed_time / NULLIF(executions, 0) / 1000000, 3) avg_sec,
       executions,
       SUBSTR(sql_text, 1, 100) sql_extrait
FROM   v$sql
WHERE  UPPER(sql_text) LIKE '%PKG_NANOORBIT%'
  AND  executions > 0
ORDER BY avg_sec DESC
FETCH FIRST 10 ROWS ONLY;
-- Seuil WARNING : avg_sec > 1, CRITICAL : avg_sec > 3

-- 4.3 Rapport global des top 10 requêtes par temps elapsed
SELECT sql_id,
       ROUND(elapsed_time / 1000000, 2)                          total_elapsed_sec,
       executions,
       ROUND(elapsed_time / NULLIF(executions, 0) / 1000, 1)    avg_ms,
       ROUND(cpu_time     / NULLIF(executions, 0) / 1000, 1)    avg_cpu_ms,
       buffer_gets,
       SUBSTR(sql_text, 1, 80)                                   sql_extrait
FROM   v$sql
WHERE  executions > 0
  AND  parsing_schema_name = 'NANOORBIT_ADMIN'
ORDER BY total_elapsed_sec DESC
FETCH FIRST 10 ROWS ONLY;


-- ==============================================================
-- PARTIE 5 — SURVEILLANCE DES SAUVEGARDES RMAN
-- ==============================================================
-- KPI 7 : détection d'échec de sauvegarde

-- 5.1 Statut des derniers jobs RMAN
SELECT job_id,
       TO_CHAR(start_time, 'DD/MM/YYYY HH24:MI') debut,
       TO_CHAR(end_time,   'DD/MM/YYYY HH24:MI') fin,
       status,
       input_bytes_display   volume_source,
       output_bytes_display  volume_backup,
       time_taken_display    duree,
       input_type
FROM   v$rman_backup_job_details
ORDER BY start_time DESC
FETCH FIRST 20 ROWS ONLY;
-- STATUS attendu : COMPLETED pour tous les jobs récents
-- FAILED ou COMPLETED WITH WARNINGS = alerte immédiate

-- 5.2 Inventaire des dernières sauvegardes complètes
SELECT handle,
       TO_CHAR(completion_time, 'DD/MM/YYYY HH24:MI') sauvegarde_le,
       ROUND(bytes / 1073741824, 2)                   taille_go,
       status,
       backup_type
FROM   v$backup_piece
WHERE  backup_type IN ('D', 'I')   -- D=full, I=incremental
  AND  deleted = 'NO'
ORDER BY completion_time DESC
FETCH FIRST 10 ROWS ONLY;

-- 5.3 Vérification du dernier archivelog sauvegardé
SELECT TO_CHAR(MAX(next_time), 'DD/MM/YYYY HH24:MI:SS') couverture_max,
       ROUND((SYSDATE - MAX(next_time)) * 24 * 60, 1)   ecart_minutes
FROM   v$backup_redolog;
-- ecart_minutes doit être < 15 pour respecter le RPO opérationnel


-- ==============================================================
-- PARTIE 6 — CROISSANCE DE HISTORIQUE_STATUT
-- ==============================================================
-- KPI 6 : suivi volumétrique de la table d'historique

-- 6.1 Taille actuelle
SELECT segment_name,
       tablespace_name,
       ROUND(bytes / 1048576, 3) taille_mb,
       extents,
       SYSDATE                   mesure_le
FROM   dba_segments
WHERE  segment_name    = 'HISTORIQUE_STATUT'
  AND  owner           = 'NANOORBIT_ADMIN';

-- 6.2 Nombre de lignes (proxy de croissance)
-- Connexion NANOORBIT_ADMIN
SELECT COUNT(*) nb_lignes,
       MIN(date_statut) premiere_entree,
       MAX(date_statut) derniere_entree
FROM   nanoorbit_admin.historique_statut;

-- 6.3 Croissance par semaine (à comparer entre deux mesures Statspack)
-- Prendre un snapshot avant : EXECUTE STATSPACK.SNAP;
-- Simuler une charge (INSERT dans HISTORIQUE_STATUT)
-- Prendre un snapshot après : EXECUTE STATSPACK.SNAP;
-- Générer le rapport : @?/rdbms/admin/spreport.sql


-- ==============================================================
-- PARTIE 7 — CONSULTATION DES ALERTES DÉCLENCHÉES
-- ==============================================================

-- 7.1 Historique de toutes les alertes Oracle
SELECT TRUNC(creation_time)          date_alerte,
       object_type,
       object_name,
       metric_value,
       warning_value,
       critical_value,
       reason,
       action_taken
FROM   dba_alert_history
WHERE  creation_time > SYSDATE - 7      -- 7 derniers jours
ORDER BY creation_time DESC;

-- 7.2 Alertes actives en ce moment
SELECT object_type,
       object_name,
       metric_name,
       metric_value,
       reason
FROM   dba_outstanding_alerts
ORDER BY creation_time DESC;
-- Table vide = aucune alerte active en cours


-- ==============================================================
-- PARTIE 8 — STATSPACK : SNAPSHOTS ET RAPPORT
-- ==============================================================
-- Prérequis : Statspack installé (spcreate.sql exécuté en SYS)

-- 8.1 Snapshot avant la période de mesure
-- Connexion SYS ou PERFSTAT
EXECUTE STATSPACK.SNAP;

-- 8.2 Simuler une charge sur NanoOrbit (connexion NANOORBIT_ADMIN)
-- Exemple : requêtes répétées sur FENETRE_COM
/*
BEGIN
  FOR i IN 1..100 LOOP
    FOR rec IN (
      SELECT s.nom_satellite, f.datetime_debut, f.duree_minutes
      FROM   fenetre_com f
      JOIN   satellite s ON f.id_satellite = s.id_satellite
      WHERE  f.statut_fenetre = 'PLANIFIEE'
      ORDER BY f.datetime_debut
    ) LOOP
      NULL;
    END LOOP;
  END LOOP;
END;
/
*/

-- 8.3 Snapshot après la période de mesure
EXECUTE STATSPACK.SNAP;

-- 8.4 Lister les snapshots disponibles
SELECT snap_id,
       TO_CHAR(snap_time, 'DD/MM/YYYY HH24:MI:SS') heure_snapshot
FROM   stats$snapshot
ORDER BY snap_id;

-- 8.5 Générer le rapport Statspack (interactif)
-- @?/rdbms/admin/spreport.sql
-- → Saisir le snap_id de début et de fin quand demandé
-- → Le rapport est sauvegardé dans spreport.txt
-- Sections clés à analyser :
--   - Top 5 Timed Events   : événements d'attente dominants
--   - SQL ordered by Elapsed Time : requêtes les plus coûteuses
--   - Instance Activity Stats : I/O, redo, parse ratio


-- ==============================================================
-- VÉRIFICATION FINALE — RÉCAPITULATIF SUPERVISION
-- ==============================================================

PROMPT ============================================================
PROMPT RÉCAPITULATIF SUPERVISION NANOORBIT
PROMPT ============================================================

PROMPT
PROMPT [1] Instance Oracle
SELECT status, database_status, logins FROM v$instance;

PROMPT
PROMPT [2] Mode archivelog
SELECT log_mode FROM v$database;

PROMPT
PROMPT [3] Occupation tablespaces NanoOrbit
SELECT tablespace_name,
       ROUND((1 - NVL(f.free_mb,0) / t.total_mb) * 100, 1) pct_used,
       CASE WHEN (1 - NVL(f.free_mb,0) / t.total_mb) >= 0.90 THEN 'CRITICAL'
            WHEN (1 - NVL(f.free_mb,0) / t.total_mb) >= 0.80 THEN 'WARNING'
            ELSE 'OK' END statut
FROM (SELECT tablespace_name, SUM(bytes)/1048576 total_mb FROM dba_data_files GROUP BY tablespace_name) t
LEFT JOIN (SELECT tablespace_name, SUM(bytes)/1048576 free_mb FROM dba_free_space GROUP BY tablespace_name) f
  ON t.tablespace_name = f.tablespace_name
WHERE t.tablespace_name IN ('TBS_OPERATION','TBS_REFERENTIEL','TBS_HISTORIQUE')
ORDER BY pct_used DESC;

PROMPT
PROMPT [4] Sessions actives
SELECT COUNT(*) sessions_actives FROM v$session WHERE status='ACTIVE' AND username IS NOT NULL;

PROMPT
PROMPT [5] Dernier job RMAN
SELECT status, TO_CHAR(start_time,'DD/MM HH24:MI') debut, time_taken_display duree
FROM v$rman_backup_job_details ORDER BY start_time DESC FETCH FIRST 1 ROW ONLY;

PROMPT
PROMPT [6] Alertes actives
SELECT COUNT(*) alertes_en_cours FROM dba_outstanding_alerts;

PROMPT
PROMPT [7] Dernier archivage
SELECT TO_CHAR(MAX(completion_time),'DD/MM/YYYY HH24:MI:SS') dernier_archivage,
       ROUND((SYSDATE - MAX(completion_time))*24*60,1) ecart_min
FROM v$archived_log;

PROMPT
PROMPT ============================================================
PROMPT Supervision NanoOrbit — vérification terminée.
PROMPT ============================================================

-- ==============================================================
-- NOTE PÉDAGOGIQUE
-- ==============================================================
-- Critères d'évaluation du livrable L4-B :
--
-- ✔ Les alertes DBMS_SERVER_ALERT sont configurées pour les 3 tablespaces
-- ✔ Au moins 5 KPI du tableau L4-A ont une requête V$ associée
-- ✔ Le test de déclenchement d'une alerte est documenté (capture)
-- ✔ Au moins un snapshot Statspack a été pris (select sur stats$snapshot)
-- ✔ Le rapport spreport.txt a été généré et une section commentée
-- ✔ Les requêtes sont exécutées et les résultats capturés en screenshot
--
-- Point de vigilance :
-- Les requêtes DBA_* nécessitent des privilèges DBA ou SELECT_CATALOG_ROLE.
-- Si l'étudiant se connecte en NANOORBIT_ADMIN, certaines vues nécessitent
-- l'accès via SYS. Préciser : connexion SYS pour la partie DBMS_SERVER_ALERT
-- et les vues DBA_*, connexion NANOORBIT_ADMIN pour USER_SEGMENTS et
-- les requêtes sur les tables métier.
--
-- Corrigé instructeur — Séance 6 FOAD — BDOE633 · EPSI · NTIConseil · 2025-2026
-- ==============================================================
