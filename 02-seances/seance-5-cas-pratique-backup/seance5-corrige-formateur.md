# Corrigé formateur — Séance 5 · Cas pratique n°1
## Sauvegarde et restauration avec RMAN

**Module** : BDOE633 — Administration et Optimisation des Bases de Données  
**Format** : FOAD · 2 h · Compétence ASRBD1.6  
**Document** : Réservé au formateur — ne pas distribuer aux apprenants

---

## Prérequis techniques

| Élément | Valeur attendue |
|---|---|
| Conteneur Docker | `oracle-nanoorbit` en cours d'exécution |
| Service CDB | `FREE` (port 1521) |
| Service PDB | `FREEPDB1` |
| Utilisateur métier | `NANOORBIT_ADMIN` |
| Connexion SYSDBA | `sys/[mdp]@localhost:1521/FREE as sysdba` |

> **Rappel Git Bash (Windows)** : toujours lancer `export MSYS_NO_PATHCONV=1` avant toute session Docker.

---

## TEMPS 1 — Activer ARCHIVELOG

### Script complet à titre de référence

```sql
-- ============================================================
-- ACTIVATION DU MODE ARCHIVELOG
-- À exécuter en tant que SYSDBA sur le service FREE (CDB root)
-- ============================================================

-- Connexion
-- sqlplus sys/[mdp]@localhost:1521/FREE as sysdba

-- 1. Vérifier l'état initial
SELECT log_mode FROM v$database;
-- Résultat attendu avant activation : NOARCHIVELOG

-- 2. Séquence d'activation
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- 3. Vérifications post-activation
SELECT log_mode FROM v$database;
-- Résultat attendu : ARCHIVELOG

SHOW PARAMETER log_archive_dest_1;
-- Doit pointer vers un répertoire valide (ex. /opt/oracle/oradata/FREE/archivelog)
-- Si vide, configurer :
-- ALTER SYSTEM SET log_archive_dest_1 = 'LOCATION=/opt/oracle/oradata/FREE/archivelog' SCOPE=BOTH;

ARCHIVE LOG LIST;
-- Doit afficher : Database log mode = Archive Mode
--                Automatic archival = Enabled

-- 4. Configurer ARCHIVE_LAG_TARGET (RPO 15 min NanoOrbit)
ALTER SYSTEM SET archive_lag_target = 900 SCOPE=BOTH;
-- 900 secondes = 15 minutes → force un archivage au moins toutes les 15 min
```

### Critères de réussite

- `LOG_MODE = ARCHIVELOG` dans `V$DATABASE`
- `ARCHIVE LOG LIST` affiche « Archive Mode » et « Automatic archival Enabled »
- `ARCHIVE_LAG_TARGET = 900`

### Erreurs fréquentes à anticiper

| Symptôme | Cause | Correction |
|---|---|---|
| `ORA-01109: database not open` | Tentative d'ALTER avant OPEN | Respecter la séquence MOUNT → ARCHIVELOG → OPEN |
| Commande refuse en FREEPDB1 | Connexion sur le PDB au lieu du CDB | Se connecter sur `FREE`, pas `FREEPDB1` |
| Répertoire archivelog inexistant | Paramètre `log_archive_dest_1` non configuré | Créer le dossier et définir le paramètre |

---

## TEMPS 2 — Sauvegarder

### Script RMAN — Sauvegarde complète (L3-A)

```rman
-- ============================================================
-- SAUVEGARDE COMPLÈTE BASE OUVERTE
-- Connexion : rman target sys/[mdp]@localhost:1521/FREE
-- ============================================================

-- 1. Configurer le répertoire de sauvegarde
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/opt/oracle/oradata/FREE/backup/%U';
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/opt/oracle/oradata/FREE/backup/%F';

-- 2. Configurer la politique de rétention (14 jours NanoOrbit)
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;

-- 3. Sauvegarde complète base ouverte (base accessible pendant toute l'opération)
BACKUP DATABASE PLUS ARCHIVELOG;
BACKUP CURRENT CONTROLFILE;

-- 4. Vérifications
LIST BACKUP SUMMARY;
LIST ARCHIVELOG ALL;
VALIDATE DATABASE;

-- Résultats attendus :
-- LIST BACKUP SUMMARY affiche au moins 1 backup set de type DB FULL
-- VALIDATE DATABASE termine sans erreur (0 blocks corrupt)
```

### Script RMAN — Simulation activité + sauvegarde incrémentale

```sql
-- Dans SQL*Plus connecté à FREEPDB1 / NANOORBIT_ADMIN
-- Simuler une journée d'activité
INSERT INTO FENETRE_COM 
  VALUES ('FCM-TEST-01', 'SAT-001', 'GS-TLS-01',
          SYSTIMESTAMP, 480, 'Planifiée', NULL);
COMMIT;

SELECT COUNT(*) FROM fenetre_com;
-- Note : le COUNT avant/après permet de prouver que la restauration a bien fonctionné
```

```rman
-- Dans RMAN
-- Sauvegarde incrémentale de niveau 1 (quotidienne)
BACKUP INCREMENTAL LEVEL 1 DATABASE PLUS ARCHIVELOG;

-- Purger les sauvegardes obsolètes selon la politique de rétention
DELETE NOPROMPT OBSOLETE;

-- Vérification globale
SHOW ALL;
LIST BACKUP SUMMARY;
```

### Résultats attendus pour L3-A

L'apprenant doit produire un fichier contenant :
1. Les commandes de configuration RMAN (CONFIGURE)
2. La commande BACKUP avec son output terminal (liste des fichiers créés, taille)
3. Le résultat de `LIST BACKUP SUMMARY` collé tel quel
4. La taille occupée sur le disque : `du -sh /opt/oracle/oradata/FREE/backup/`

---

## TEMPS 3 — Restaurer

### Scénario 1 — Restauration PITR (DELETE erroné sur FENETRE_COM)

#### Préparation de l'incident

```sql
-- Dans SQL*Plus / NANOORBIT_ADMIN sur FREEPDB1
-- Étape 1 : noter le COUNT de référence
SELECT COUNT(*) AS nb_avant FROM fenetre_com;

-- Étape 2 : noter l'heure précise AVANT l'incident
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS heure_avant FROM dual;
-- Conserver cette valeur → elle servira comme point de restauration

-- Étape 3 : simuler l'incident
DELETE FROM fenetre_com;
COMMIT;

-- Étape 4 : vérifier que les données ont disparu
SELECT COUNT(*) AS nb_apres FROM fenetre_com;
-- Résultat attendu : 0
```

#### Restauration PITR dans RMAN

```rman
-- Remplacer '2025-06-01 14:30:00' par l'heure notée à l'étape 2

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;

-- Positionner le point de restauration temporel
SET UNTIL TIME "TO_DATE('2025-06-01 14:30:00', 'YYYY-MM-DD HH24:MI:SS')";

-- Restaurer et récupérer
RESTORE DATABASE;
RECOVER DATABASE;

-- Ouvrir en RESETLOGS (obligatoire après toute restauration PITR)
ALTER DATABASE OPEN RESETLOGS;
```

#### Vérification post-restauration

```sql
-- Dans SQL*Plus / NANOORBIT_ADMIN
SELECT COUNT(*) AS nb_restore FROM fenetre_com;
-- Doit retrouver le nb_avant

-- Vérification de l'intégrité applicative
-- Appel du package (si disponible)
DECLARE
  v_statut VARCHAR2(200);
BEGIN
  v_statut := pkg_nanoOrbit.statut_constellation();
  DBMS_OUTPUT.PUT_LINE(v_statut);
END;
/

-- Vérification des triggers actifs
SELECT trigger_name, status FROM user_triggers ORDER BY trigger_name;
-- Tous doivent être ENABLED
```

#### Critères de réussite

- `COUNT(*)` après restauration = `COUNT(*)` avant incident
- Tous les triggers en statut `ENABLED`
- `V$DATABASE.OPEN_MODE = READ WRITE`
- Temps mesuré ≤ 30 min (RTO contractuel)

---

### Scénario 2 — Restauration d'un tablespace

```sql
-- Dans SQL*Plus / SYSDBA
-- Étape 1 : identifier les tablespaces disponibles
SELECT tablespace_name, status FROM dba_tablespaces ORDER BY 1;

-- Étape 2 : choisir un tablespace non-SYSTEM à mettre offline
-- Pour NanoOrbit, on peut utiliser USERS (tablespace par défaut Oracle)
-- ou créer un tablespace dédié NANOORBIT_DATA en amont si l'environnement le permet

-- Étape 3 : simuler la corruption (mise offline brutale)
ALTER TABLESPACE users OFFLINE IMMEDIATE;

-- Vérification : le tablespace est OFFLINE
SELECT tablespace_name, status FROM dba_tablespaces WHERE tablespace_name = 'USERS';
```

```rman
-- Restauration du tablespace
RESTORE TABLESPACE users;
RECOVER TABLESPACE users;
```

```sql
-- Remise en ligne
ALTER TABLESPACE users ONLINE;

-- Vérification finale
SELECT tablespace_name, status FROM dba_tablespaces WHERE tablespace_name = 'USERS';
-- Résultat attendu : ONLINE

SELECT COUNT(*) FROM nanoorbit_admin.fenetre_com;
-- Le reste de la base est intact
```

#### Point pédagogique clé

Insister sur le fait que la restauration d'un tablespace n'interrompt pas les opérations sur les autres tablespaces. C'est la différence fondamentale avec une restauration complète.

---

### Scénario 3 — Instance Recovery automatique (SHUTDOWN ABORT)

```sql
-- Dans SQL*Plus / SYSDBA
-- Étape 1 : insérer une ligne non committée pour rendre le scénario visible
INSERT INTO nanoorbit_admin.fenetre_com
  VALUES ('FCM-CRASH-01', 'SAT-002', 'GS-KIR-01',
          SYSTIMESTAMP, 300, 'Planifiée', NULL);
-- NE PAS COMMITTER

-- Étape 2 : crash brutal (simule coupure d'alimentation)
SHUTDOWN ABORT;
-- La transaction non committée est perdue — c'est normal et attendu

-- Étape 3 : redémarrage
STARTUP;
-- Oracle démarre, SMON déclenche automatiquement l'Instance Recovery
-- Pas d'intervention manuelle requise
```

```sql
-- Étape 4 : vérifications post-crash
SELECT open_mode, log_mode FROM v$database;
-- open_mode = READ WRITE  /  log_mode = ARCHIVELOG

-- Vérifier que FCM-CRASH-01 n'est pas présente (rollback automatique)
SELECT COUNT(*) FROM nanoorbit_admin.fenetre_com WHERE id_fenetre = 'FCM-CRASH-01';
-- Résultat attendu : 0 (transaction non committée annulée par SMON)

-- Localiser l'alert log pour observer les traces SMON
SELECT value FROM v$diag_info WHERE name = 'Diag Trace';
```

```bash
# Dans le terminal Docker — lire les dernières lignes de l'alert log
docker exec oracle-nanoorbit bash -c "tail -40 /opt/oracle/diag/rdbms/free/FREE/trace/alert_FREE.log"
# Chercher les lignes :
# "Beginning crash recovery of 1 threads"
# "Recovery of Online Redo Log"
# "Completed crash recovery at"
```

#### Ce que les apprenants doivent relever dans L3-C

- Les 3 lignes clés de l'alert log citées ci-dessus
- Le fait que FCM-CRASH-01 a bien été rollbackée (preuve que SMON fonctionne)
- Le temps entre STARTUP et `open_mode = READ WRITE` (RTO scénario 3 ≈ 1-3 min)

---

## Grille d'évaluation — Livrables L3-A, L3-B, L3-C

| Critère | Points | Ce qu'on évalue |
|---|---|---|
| **L3-A — Scripts RMAN commentés** | | |
| CONFIGURE RMAN (rétention, format) correct | 2 | Politique 14 jours présente |
| BACKUP DATABASE PLUS ARCHIVELOG exécuté | 2 | Output terminal collé |
| LIST BACKUP SUMMARY fourni | 1 | Preuve que la sauvegarde existe |
| **L3-B — Procédures de restauration** | | |
| Scénario 1 (PITR) : séquence complète | 4 | MOUNT → SET UNTIL → RESTORE → RECOVER → RESETLOGS |
| Scénario 2 (tablespace) : séquence complète | 3 | OFFLINE → RESTORE → RECOVER → ONLINE |
| Scénario 3 (crash) : mécanisme SMON expliqué | 3 | Roll forward + rollback compris |
| **L3-C — Compte rendu des tests** | | |
| Temps mesuré pour chaque scénario | 3 | Valeurs réelles, pas inventées |
| Comparaison au RTO contractuel (30 min) | 2 | Conformité ou écart analysé |
| Extrait alert log scénario 3 | 2 | Lignes SMON copiées |
| Vérification d'intégrité (COUNT, triggers) | 2 | Preuve que les données sont cohérentes |
| **Qualité globale** | | |
| Scripts commentés, lisibles, structurés | 2 | Posture d'administrateur |
| **Total** | **26** | Ramené à 20 par le formateur |

---

## Notes de correction

### Sur le RTO

Le RTO de 30 min est contractuel pour les données opérationnelles. En contexte Docker sur un poste local, les temps observés seront souvent :
- Scénario 1 (PITR) : 10-20 min selon le volume
- Scénario 2 (tablespace) : 5-10 min
- Scénario 3 (crash SMON) : 1-3 min

Si un apprenant dépasse 30 min sur le scénario 1, c'est acceptable à ce stade d'apprentissage mais doit être analysé dans L3-C.

### Sur RESETLOGS

Un classique d'erreur : oublier `ALTER DATABASE OPEN RESETLOGS` après une restauration PITR. La base reste en mode MOUNT et l'apprenant ne comprend pas pourquoi elle n'est pas accessible. RESETLOGS réinitialise la séquence des redo logs — c'est obligatoire et irréversible.

### Sur la connexion FREE vs FREEPDB1

Rappel systématique : `ALTER DATABASE ARCHIVELOG` ne fonctionne que depuis le CDB root (service `FREE`). Toutes les commandes d'administration globale (mode archivelog, paramètres système) s'exécutent au niveau CDB.

---

*Corrigé formateur — Séance 5 BDOE633 — À conserver dans le dossier instructor/*
