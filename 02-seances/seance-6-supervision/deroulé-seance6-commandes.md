# Déroulé opérationnel — Séance 6 · Supervision proactive

> **Usage instructeur.** Ce document donne les commandes à passer dans l'ordre exact pour accompagner les étudiants pendant la séance FOAD ou en classe virtuelle.
>
> Environnement : Docker `nanoorbit-oracle` · Oracle 23ai Free · PDB `FREEPDB1`

---

## Avant de démarrer — Vérifier que le conteneur tourne

```bash
# Sur la machine hôte (Git Bash Windows)
docker ps | grep nanoorbit-oracle
# Si absent :
docker start nanoorbit-oracle
```

---

## ÉTAPE 1 — Connexion SYS (CDB) pour les opérations système

```bash
MSYS_NO_PATHCONV=1 docker exec -it nanoorbit-oracle \
  sqlplus sys/NanoOrbit_Sys2026@localhost:1521/FREE as sysdba
```

**Dans SQL*Plus :**

```sql
-- Basculer sur la PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Vérifier l'état de l'instance
SELECT instance_name, status, database_status, logins
FROM   v$instance;
-- Attendu : STATUS=OPEN, DATABASE_STATUS=ACTIVE

-- Vérifier le mode archivelog (prérequis RPO 15 min)
SELECT log_mode FROM v$database;
-- Attendu : ARCHIVELOG

-- Vérifier le dernier archivage
SELECT TO_CHAR(MAX(completion_time), 'DD/MM/YYYY HH24:MI:SS') dernier_archivage,
       ROUND((SYSDATE - MAX(completion_time)) * 24 * 60, 1)   ecart_min
FROM   v$archived_log;
-- ecart_min doit être < 15 si la base est active
```

---

## ÉTAPE 2 — Occupation des tablespaces NanoOrbit

```sql
-- Toujours en SYS sur FREEPDB1
SELECT t.tablespace_name,
       ROUND(t.total_mb, 1)                                    total_mb,
       ROUND(t.total_mb - NVL(f.free_mb, 0), 1)               used_mb,
       ROUND((1 - NVL(f.free_mb, 0) / t.total_mb) * 100, 1)  pct_used,
       CASE
         WHEN (1 - NVL(f.free_mb, 0) / t.total_mb) >= 0.90 THEN '*** CRITICAL ***'
         WHEN (1 - NVL(f.free_mb, 0) / t.total_mb) >= 0.80 THEN '!  WARNING  !'
         ELSE 'OK'
       END AS statut
FROM (
    SELECT tablespace_name, SUM(bytes)/1048576 total_mb
    FROM   dba_data_files GROUP BY tablespace_name
) t
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes)/1048576 free_mb
    FROM   dba_free_space GROUP BY tablespace_name
) f ON t.tablespace_name = f.tablespace_name
WHERE  t.tablespace_name IN ('TBS_OPERATION','TBS_REFERENTIEL','TBS_HISTORIQUE')
ORDER BY pct_used DESC;
```

---

## ÉTAPE 3 — Configurer les alertes DBMS_SERVER_ALERT

```sql
-- SYS sur FREEPDB1 — exécuter le bloc en une fois
SET SERVEROUTPUT ON

BEGIN
  -- TBS_OPERATION (opérationnel — critique)
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

  -- TBS_HISTORIQUE (croissance continue)
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

  -- TBS_REFERENTIEL (SLA 99,9 %)
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

  -- Alerte sessions actives
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

  DBMS_OUTPUT.PUT_LINE('Alertes configurées.');
END;
/

-- Vérifier que les seuils sont enregistrés
SELECT object_name, metrics_name, warning_value, critical_value
FROM   dba_thresholds
WHERE  object_name IN ('TBS_OPERATION','TBS_HISTORIQUE','TBS_REFERENTIEL')
   OR  metrics_name LIKE '%LOGON%'
ORDER BY object_name;
-- Attendu : 3 lignes tablespaces + 1 ligne sessions
```

---

## ÉTAPE 4 — Surveillance des sessions actives (V$SESSION)

```sql
-- Comptage en temps réel
SELECT COUNT(*) nb_sessions_actives
FROM   v$session
WHERE  status = 'ACTIVE' AND username IS NOT NULL;

-- Détail sessions longues et blocages
SELECT s.sid, s.serial#, s.username, s.status,
       s.last_call_et        secondes_actives,
       s.blocking_session,
       SUBSTR(s.module,1,30) module,
       SUBSTR(q.sql_text,1,100) sql_en_cours
FROM   v$session s
LEFT JOIN v$sql q ON s.sql_id = q.sql_id
WHERE  s.status = 'ACTIVE'
  AND  s.username IS NOT NULL
  AND  s.last_call_et > 30
ORDER BY s.last_call_et DESC;
```

---

## ÉTAPE 5 — Performances des requêtes (V$SQL)

```sql
-- Latence INSERT sur FENETRE_COM (KPI 3 — seuil WARNING > 200 ms)
SELECT sql_id,
       ROUND(elapsed_time / NULLIF(executions,0) / 1000, 1) avg_ms,
       executions,
       SUBSTR(sql_text, 1, 80) sql_extrait
FROM   v$sql
WHERE  UPPER(sql_text) LIKE '%FENETRE_COM%'
  AND  executions > 0
ORDER BY avg_ms DESC
FETCH FIRST 10 ROWS ONLY;

-- Performances pkg_nanoOrbit (KPI 5 — seuil WARNING > 1 s)
SELECT sql_id,
       ROUND(elapsed_time / NULLIF(executions,0) / 1000000, 3) avg_sec,
       executions,
       SUBSTR(sql_text, 1, 80) sql_extrait
FROM   v$sql
WHERE  UPPER(sql_text) LIKE '%PKG_NANOORBIT%'
  AND  executions > 0
ORDER BY avg_sec DESC
FETCH FIRST 10 ROWS ONLY;

-- Top 10 requêtes NANOORBIT_ADMIN par temps total
SELECT ROUND(elapsed_time/1000000, 2) total_sec,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1000, 1) avg_ms,
       SUBSTR(sql_text, 1, 80) sql_extrait
FROM   v$sql
WHERE  parsing_schema_name = 'NANOORBIT_ADMIN'
  AND  executions > 0
ORDER BY total_sec DESC
FETCH FIRST 10 ROWS ONLY;
```

---

## ÉTAPE 6 — Vérification des sauvegardes RMAN

```sql
-- Statut des derniers jobs
SELECT job_id,
       TO_CHAR(start_time,'DD/MM HH24:MI') debut,
       status,
       input_bytes_display  volume,
       time_taken_display   duree,
       input_type
FROM   v$rman_backup_job_details
ORDER BY start_time DESC
FETCH FIRST 10 ROWS ONLY;
-- STATUS attendu : COMPLETED

-- Couverture archivelog (vérifier le RPO 15 min)
SELECT TO_CHAR(MAX(next_time), 'DD/MM/YYYY HH24:MI:SS') couverture_max,
       ROUND((SYSDATE - MAX(next_time)) * 24 * 60, 1)   ecart_min
FROM   v$backup_redolog;
-- ecart_min doit être < 15
```

---

## ÉTAPE 7 — Volumétrie de HISTORIQUE_STATUT

```sql
-- Taille dans TBS_HISTORIQUE
SELECT segment_name,
       tablespace_name,
       ROUND(bytes/1048576, 3) taille_mb,
       extents
FROM   dba_segments
WHERE  segment_name = 'HISTORIQUE_STATUT'
  AND  owner = 'NANOORBIT_ADMIN';

-- Nombre de lignes (connexion NANOORBIT_ADMIN ou via SYS)
SELECT COUNT(*) nb_lignes,
       MIN(date_statut) premiere_entree,
       MAX(date_statut) derniere_entree
FROM   nanoorbit_admin.historique_statut;
```

---

## ÉTAPE 8 — Consulter les alertes déclenchées

```sql
-- Alertes des 7 derniers jours
SELECT TRUNC(creation_time) date_alerte,
       object_name,
       metric_value,
       warning_value,
       critical_value,
       reason
FROM   dba_alert_history
WHERE  creation_time > SYSDATE - 7
ORDER BY creation_time DESC;

-- Alertes actives en ce moment
SELECT object_name, metric_name, metric_value, reason
FROM   dba_outstanding_alerts
ORDER BY creation_time DESC;
-- Table vide = aucune alerte active
```

---

## ÉTAPE 9 — Statspack (installation + snapshots)

> Statspack doit être installé une seule fois. Vérifier s'il est déjà là avant d'installer.

```sql
-- Vérifier si PERFSTAT existe déjà
SELECT username FROM dba_users WHERE username = 'PERFSTAT';
-- Si aucune ligne : installer Statspack (étape 9a)
-- Si PERFSTAT existe : passer directement à l'étape 9b
```

### 9a — Installation (si absente)

```sql
-- En SYS sur FREEPDB1
@?/rdbms/admin/spcreate.sql
-- Répondre aux 3 invites :
--   mot de passe PERFSTAT : perfstat (ou au choix)
--   tablespace par défaut : SYSAUX
--   tablespace temporaire : TEMP
```

### 9b — Prise de snapshots et rapport

```sql
-- Snapshot AVANT la charge
EXECUTE STATSPACK.SNAP;

-- Simuler une charge (connexion NANOORBIT_ADMIN)
-- Ouvrir un second terminal :
```

```bash
MSYS_NO_PATHCONV=1 docker exec -it nanoorbit-oracle \
  sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@localhost:1521/FREEPDB1
```

```sql
-- Dans la session NANOORBIT_ADMIN — générer de la charge
BEGIN
  FOR i IN 1..200 LOOP
    FOR rec IN (
      SELECT s.nom_satellite, f.datetime_debut, f.duree_minutes
      FROM   fenetre_com f
      JOIN   satellite s ON f.id_satellite = s.id_satellite
      WHERE  f.statut_fenetre = 'PLANIFIEE'
      ORDER BY f.datetime_debut
    ) LOOP NULL; END LOOP;
  END LOOP;
END;
/
```

```sql
-- Revenir en SYS — Snapshot APRÈS la charge
EXECUTE STATSPACK.SNAP;

-- Lister les snapshots disponibles
SELECT snap_id,
       TO_CHAR(snap_time, 'DD/MM/YYYY HH24:MI:SS') heure_snapshot
FROM   stats$snapshot
ORDER BY snap_id;

-- Générer le rapport (interactif — saisir begin_snap et end_snap)
@?/rdbms/admin/spreport.sql
-- Le rapport est enregistré dans spreport.txt
-- Sections clés à lire :
--   Top 5 Timed Events        → événements d'attente dominants
--   SQL ordered by Elapsed    → requêtes les plus coûteuses
--   Instance Activity Stats   → parse, redo, I/O
```

---

## ÉTAPE 10 — Récapitulatif supervision (passe finale)

```sql
-- Toujours en SYS sur FREEPDB1
-- Une passe complète pour vérifier l'état global

PROMPT === Instance ===
SELECT status, database_status, logins FROM v$instance;

PROMPT === Archivelog ===
SELECT log_mode FROM v$database;

PROMPT === Tablespaces NanoOrbit ===
SELECT tablespace_name,
       ROUND((1 - NVL(f.free_mb,0)/t.total_mb)*100,1) pct_used,
       CASE WHEN (1-NVL(f.free_mb,0)/t.total_mb)>=0.90 THEN 'CRITICAL'
            WHEN (1-NVL(f.free_mb,0)/t.total_mb)>=0.80 THEN 'WARNING'
            ELSE 'OK' END statut
FROM (SELECT tablespace_name, SUM(bytes)/1048576 total_mb FROM dba_data_files GROUP BY tablespace_name) t
LEFT JOIN (SELECT tablespace_name, SUM(bytes)/1048576 free_mb FROM dba_free_space GROUP BY tablespace_name) f
  ON t.tablespace_name = f.tablespace_name
WHERE t.tablespace_name IN ('TBS_OPERATION','TBS_REFERENTIEL','TBS_HISTORIQUE')
ORDER BY pct_used DESC;

PROMPT === Sessions actives ===
SELECT COUNT(*) sessions_actives
FROM v$session WHERE status='ACTIVE' AND username IS NOT NULL;

PROMPT === Dernier job RMAN ===
SELECT status, TO_CHAR(start_time,'DD/MM HH24:MI') debut, time_taken_display duree
FROM v$rman_backup_job_details ORDER BY start_time DESC FETCH FIRST 1 ROW ONLY;

PROMPT === Alertes actives ===
SELECT COUNT(*) alertes_en_cours FROM dba_outstanding_alerts;

PROMPT === Dernier archivage ===
SELECT TO_CHAR(MAX(completion_time),'DD/MM/YYYY HH24:MI:SS') dernier_archivage,
       ROUND((SYSDATE - MAX(completion_time))*24*60,1) ecart_min
FROM v$archived_log;
```

---

## Résumé des connexions

| Besoin | Commande |
|--------|----------|
| SYS CDB (puis `ALTER SESSION SET CONTAINER=FREEPDB1`) | `sqlplus sys/NanoOrbit_Sys2026@localhost:1521/FREE as sysdba` |
| SYS directement sur FREEPDB1 | `sqlplus sys/NanoOrbit_Sys2026@localhost:1521/FREEPDB1 as sysdba` |
| NANOORBIT_ADMIN | `sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@localhost:1521/FREEPDB1` |

> Sur Git Bash Windows, toujours préfixer les commandes `docker exec` avec `MSYS_NO_PATHCONV=1`.

---

*Déroulé instructeur — Séance 6 FOAD — BDOE633 · EPSI · NTIConseil · 2025-2026*
