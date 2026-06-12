-- ============================================================
-- BDOE633 — TP DE VALIDATION — SCRIPT DE MISE EN ÉTAT DÉGRADÉ
-- Usage INSTRUCTEUR uniquement — À exécuter AVANT la séance
-- Connexion : SYS AS SYSDBA sur FREE (CDB) puis FREEPDB1
-- ============================================================
-- Ce script crée trois problèmes que les étudiants devront
-- diagnostiquer et résoudre pendant le TP :
--
--   INCIDENT 1 (Bloc A) : TBS_OPERATION proche de la saturation
--   INCIDENT 2 (Bloc B) : sauvegarde RMAN absente / obsolète
--   INCIDENT 3 (Bloc C) : suppression accidentelle de fenêtres
--                          de communication (à réaliser EN DIRECT)
--   INCIDENT 4 (Bloc D) : aucune alerte V$ configurée
--
-- Durée d'exécution estimée : 3-5 minutes
-- ============================================================

-- -------------------------------------------------------
-- PRÉAMBULE — connexion PDB
-- -------------------------------------------------------
-- Depuis SQL*Plus ou RMAN, connectez-vous d'abord en CDB :
--   sqlplus sys/NanoOrbit_Sys2026@localhost:1521/FREE as sysdba
-- Puis basculez sur le PDB :
ALTER SESSION SET CONTAINER = FREEPDB1;

-- -------------------------------------------------------
-- INCIDENT 1 — Saturation simulée de TBS_OPERATION
--
-- On réduit la taille maximale autorisée du fichier de données
-- de TBS_OPERATION pour que le taux d'occupation apparent
-- dépasse 90 %, sans toucher aux données.
--
-- Après réorganisation (séance 3), TBS_OPERATION contient
-- environ 1,5 MB de données + index.
-- On fixe MAXSIZE à 2 MB pour simuler un tablespace quasi-plein.
-- -------------------------------------------------------

-- Identifier le fichier de données de TBS_OPERATION
-- (à titre informatif — la commande ALTER suit)
SELECT file_name, bytes/1024/1024 AS size_mb,
       maxbytes/1024/1024 AS maxsize_mb
FROM   dba_data_files
WHERE  tablespace_name = 'TBS_OPERATION';

-- Bloquer l'autoextend et fixer un plafond bas
-- Remplacez le chemin si votre environnement diffère
ALTER DATABASE DATAFILE
  '/opt/oracle/oradata/FREE/FREEPDB1/tbs_operation01.dbf'
  AUTOEXTEND OFF;

ALTER DATABASE DATAFILE
  '/opt/oracle/oradata/FREE/FREEPDB1/tbs_operation01.dbf'
  RESIZE 2M;

-- Vérification : le taux d'occupation doit être > 85 %
SELECT tablespace_name,
       ROUND((1 - free.bytes / total.bytes) * 100, 1) AS pct_used
FROM (
  SELECT tablespace_name, SUM(bytes) AS bytes
  FROM   dba_free_space
  GROUP BY tablespace_name
) free
JOIN (
  SELECT tablespace_name, SUM(bytes) AS bytes
  FROM   dba_data_files
  GROUP BY tablespace_name
) total USING (tablespace_name)
WHERE  tablespace_name = 'TBS_OPERATION';

-- Résultat attendu : PCT_USED > 85
-- Si < 85, réduire encore : RESIZE 1700K

-- -------------------------------------------------------
-- INCIDENT 2 — Absence de sauvegarde récente (RMAN)
--
-- Aucune action SQL nécessaire : si la base n'a pas été
-- sauvegardée depuis > 7 jours, RMAN signalera déjà
-- "no backup of datafile found".
--
-- Si une sauvegarde récente existe, on peut la "vieillir"
-- en modifiant la retention policy temporairement.
-- L'étudiant devra lancer une nouvelle sauvegarde complète
-- et vérifier avec LIST BACKUP SUMMARY.
--
-- Instruction pour l'instructeur :
--   rman target sys/NanoOrbit_Sys2026@localhost:1521/FREE
--   RMAN> DELETE NOPROMPT BACKUP;   -- supprime tous les backups
--   RMAN> EXIT;
--
-- Cette commande est INTENTIONNELLEMENT commentée ci-dessous
-- pour éviter toute exécution accidentelle. À lancer manuellement.
-- -------------------------------------------------------
-- /* DÉCOMMENTER SI NÉCESSAIRE :
-- CONNECT TARGET sys/NanoOrbit_Sys2026@localhost:1521/FREE
-- DELETE NOPROMPT BACKUP;
-- */

-- -------------------------------------------------------
-- INCIDENT 3 — Suppression accidentelle de fenêtres
--
-- NE PAS exécuter maintenant. À exécuter EN DIRECT
-- pendant le TP, environ 10 minutes après le début,
-- en simulant une "fausse manipulation opérateur".
--
-- Timing recommandé : après que les étudiants ont noté
-- l'état initial (Bloc A terminé), avant qu'ils lancent
-- la sauvegarde RMAN (Bloc B).
--
-- L'étudiant notera SYSDATE avant l'incident et devra
-- restaurer via Flashback Table (si dans UNDO_RETENTION)
-- ou PITR RMAN (si hors fenêtre).
-- -------------------------------------------------------

-- COMMANDES À EXÉCUTER EN DIRECT (instructeur) :
-- Connexion : NANOORBIT_ADMIN/NanoOrbit_2026@localhost:1521/FREEPDB1
--
-- SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS heure_incident FROM DUAL;
-- DELETE FROM FENETRE_COM WHERE statut = 'Planifiée';
-- COMMIT;
-- -- Annoncez à voix haute : "Le système vient de recevoir une alerte :
-- -- des fenêtres de communication ont été supprimées par erreur."

-- -------------------------------------------------------
-- INCIDENT 4 — Absence de supervision V$
--
-- Aucune alerte DBMS_SERVER_ALERT n'est configurée.
-- Aucune vue V$SESSION n'est interrogée régulièrement.
-- L'étudiant devra configurer les requêtes de supervision
-- demandées dans le Bloc D.
--
-- Optionnel : créer une session fantôme bloquée pour
-- enrichir V$SESSION (nécessite deux connexions parallèles).
-- -------------------------------------------------------

-- -------------------------------------------------------
-- VÉRIFICATION FINALE DE L'ÉTAT DÉGRADÉ
-- -------------------------------------------------------

-- A) Taux d'occupation TBS_OPERATION (doit être > 85 %)
SELECT 'TBS_OPERATION' AS tablespace,
       ROUND((1 - f.bytes / d.bytes) * 100, 1) AS pct_used,
       CASE WHEN ROUND((1 - f.bytes / d.bytes) * 100, 1) > 85
            THEN '✓ INCIDENT 1 ACTIF'
            ELSE '✗ Taux insuffisant — réduire encore'
       END AS statut_incident
FROM (SELECT SUM(bytes) bytes FROM dba_free_space
      WHERE tablespace_name = 'TBS_OPERATION') f,
     (SELECT SUM(bytes) bytes FROM dba_data_files
      WHERE tablespace_name = 'TBS_OPERATION') d;

-- B) Fenêtres de communication présentes (doit être > 0 avant incident 3)
SELECT COUNT(*) AS nb_fenetres,
       COUNT(CASE WHEN statut='Planifiée' THEN 1 END) AS planifiees,
       COUNT(CASE WHEN statut='Réalisée'  THEN 1 END) AS realisees
FROM   nanoorbit_admin.fenetre_com;

-- C) État ARCHIVELOG (doit être ARCHIVELOG pour RMAN)
SELECT log_mode FROM v$database;

-- D) Dernier backup RMAN (afficher la date)
SELECT MAX(completion_time) AS dernier_backup
FROM   v$backup_set;

-- -------------------------------------------------------
-- MEMO INSTRUCTEUR
-- -------------------------------------------------------
-- Avant le TP :
--   1. Exécuter ce script en SYS sur FREEPDB1
--   2. Supprimer les backups RMAN si une sauvegarde récente
--      existe (commande RMAN commentée ci-dessus)
--   3. Vérifier les 4 points de contrôle en fin de script
--
-- Pendant le TP (environ t+10 min) :
--   4. Exécuter l'INCIDENT 3 (DELETE FENETRE_COM planifiées)
--      depuis une fenêtre séparée, en annonçant l'incident
--
-- Après le TP (remise en état) :
--   5. Réactiver AUTOEXTEND sur TBS_OPERATION :
--      ALTER DATABASE DATAFILE '...tbs_operation01.dbf'
--        AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;
-- ============================================================
