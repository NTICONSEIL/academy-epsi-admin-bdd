# Séance 5 — Vérification des prérequis RMAN

> **Module BDOE633 · Séance 5 · Avant de commencer**
> Ce document retrace toutes les vérifications à effectuer avant de lancer
> la première sauvegarde RMAN. À conserver dans le dossier d'exploitation.

---

## Checklist des prérequis

| # | Prérequis | Commande de vérification | Résultat attendu |
|---|---|---|---|
| 1 | RMAN accessible | `rman target sys/...@FREE nocatalog` | `RMAN>` prompt |
| 2 | Base en mode ARCHIVELOG | `SELECT log_mode FROM v$database` | `ARCHIVELOG` |
| 3 | Base ouverte en lecture/écriture | `SELECT open_mode FROM v$database` | `READ WRITE` |
| 4 | Destination archive logs définie | `SELECT destination FROM v$archive_dest WHERE status='VALID'` | Chemin valide |
| 5 | Répertoire de sauvegarde RMAN | `CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '...'` | `new RMAN configuration parameters are stored` |
| 6 | Politique de rétention | `CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS` | `new RMAN configuration parameters are stored` |

---

## Étape 1 — Connexion à RMAN

RMAN (*Recovery Manager*) est l'outil Oracle de sauvegarde et restauration. Il se connecte
**obligatoirement sur le service `FREE`** (CDB racine), pas sur `FREEPDB1` (PDB).

```bash
# Depuis Git Bash — ne pas oublier la variable d'environnement
export MSYS_NO_PATHCONV=1
docker exec -it nanoorbit-oracle rman target sys/NanoOrbit_Sys2026@localhost:1521/FREE nocatalog
```

**Résultat obtenu :**
```
Recovery Manager: Release 23.26.2.0.0 - Production on Sun Jun 7 17:06:15 2026
connected to target database: FREE (DBID=1495006740)
using target database control file instead of recovery catalog
RMAN>
```

> Les avertissements `PL/SQL package SYS.DBMS_BACKUP_RESTORE version ... is not current version`
> sont **cosmétiques** — décalage mineur entre la version du client RMAN et la base. Sans impact.

> `using target database control file instead of recovery catalog` — normal : on utilise
> le controlfile comme catalogue (pas de catalogue RMAN séparé, ce qui est standard pour
> un environnement de formation).

---

## Étape 2 — Vérification du mode ARCHIVELOG

Le mode ARCHIVELOG est le **prérequis fondamental** pour toute la séance 5.
Sans lui, ni le RPO 15 min ni les restaurations PITR ne sont possibles.

```sql
RMAN> SELECT name, log_mode, open_mode FROM v$database;
```

**Résultat obtenu :**
```
NAME      LOG_MODE     OPEN_MODE
--------- ------------ --------------------
FREE      ARCHIVELOG   READ WRITE
```

✅ **ARCHIVELOG activé** — la base archive ses redo logs avant de les réutiliser.
✅ **READ WRITE** — la base est ouverte normalement, les utilisateurs peuvent travailler.

> Si le résultat avait été `NOARCHIVELOG`, il aurait fallu exécuter la séquence :
> `SHUTDOWN IMMEDIATE` → `STARTUP MOUNT` → `ALTER DATABASE ARCHIVELOG` → `ALTER DATABASE OPEN`
> (connexion en SYSDBA sur `FREE` requise).

---

## Étape 3 — Vérification de la destination des archive logs

Les archive logs doivent être écrits dans un répertoire accessible. Deux paramètres
contrôlent cela : `log_archive_dest_1` (destination explicite) et `db_recovery_file_dest`
(Fast Recovery Area). Si les deux sont vides, Oracle utilise une destination par défaut.

```sql
-- Destination explicite
RMAN> SELECT value FROM v$parameter WHERE name = 'log_archive_dest_1';

-- Fast Recovery Area
RMAN> SELECT value FROM v$parameter WHERE name = 'db_recovery_file_dest';

-- Format des fichiers d'archive
RMAN> SELECT value FROM v$parameter WHERE name = 'log_archive_format';

-- Destination réellement utilisée
RMAN> SELECT dest_id, status, destination FROM v$archive_dest WHERE status = 'VALID';
```

**Résultats obtenus :**

| Paramètre | Valeur |
|---|---|
| `log_archive_dest_1` | *(vide)* |
| `db_recovery_file_dest` | *(vide — FRA non configurée)* |
| `log_archive_format` | `%t_%s_%r.dbf` |
| Destination effective | `/opt/oracle/product/26ai/dbhomeFree/dbs/arch` |

> **FRA non configurée** : la Fast Recovery Area n'est pas activée dans cet environnement Docker.
> Ce n'est pas bloquant — Oracle utilise automatiquement `/opt/oracle/product/26ai/dbhomeFree/dbs/arch`
> comme destination d'archivage. Les sauvegardes RMAN seront dirigées vers un répertoire dédié
> configuré à l'étape suivante.

---

## Étape 4 — Création du répertoire de sauvegarde

RMAN a besoin d'un répertoire dédié pour stocker ses fichiers de sauvegarde (backup sets).
On le crée dans le conteneur Docker avant de le déclarer à RMAN.

```bash
# Depuis Git Bash (MSYS_NO_PATHCONV=1 déjà set)
docker exec -it nanoorbit-oracle mkdir -p /opt/oracle/backup/nanoorbit
```

Vérification :
```bash
docker exec -it nanoorbit-oracle ls -la /opt/oracle/backup/
```

---

## Étape 5 — Configuration RMAN

Deux paramètres RMAN à configurer avant le premier backup.

### 5.1 Canal de sauvegarde (destination des fichiers)

```sql
RMAN> CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/opt/oracle/backup/nanoorbit/%U';
```

Le `%U` est un substitut automatique qui génère un nom de fichier unique pour chaque
pièce de sauvegarde (ex. `0at1p2q3_1_1`). Cela évite les collisions entre sauvegardes.

**Résultat attendu :**
```
new RMAN configuration parameters are stored successfully
```

### 5.2 Politique de rétention (14 jours)

```sql
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;
```

Cette configuration indique à RMAN de conserver assez de sauvegardes pour permettre
une restauration à n'importe quel point dans les **14 derniers jours** — conformément
au contrat de services NanoOrbit (minimum 2 × fréquence complète hebdomadaire).

**Résultat attendu :**
```
new RMAN configuration parameters are stored successfully
```

### 5.3 Vérification de la configuration RMAN

```sql
RMAN> SHOW ALL;
```

Les lignes importantes à vérifier :
```
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/opt/oracle/backup/nanoorbit/%U';
```

---

## Bilan final des prérequis

| Prérequis | Statut | Détail |
|---|---|---|
| RMAN accessible | ✅ | Version 23.26.2, DBID=1495006740 |
| Mode ARCHIVELOG | ✅ | Déjà activé — aucune action requise |
| Base READ WRITE | ✅ | Instance ouverte normalement |
| Destination archive logs | ✅ | `/opt/oracle/product/26ai/dbhomeFree/dbs/arch` |
| Répertoire backup RMAN | ✅ | `/opt/oracle/backup/nanoorbit/` créé |
| Canal RMAN configuré | ✅ | Format `%U` dans le répertoire backup |
| Politique de rétention | ✅ | 14 jours (RECOVERY WINDOW) |
| Fast Recovery Area | ⚠️ | Non configurée — sans impact pour la séance |

**Tous les prérequis sont satisfaits. La séance 5 peut commencer.**

---

## Prochaine étape

→ **Temps 2 — Sauvegarde complète base ouverte**

```sql
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;
RMAN> BACKUP CURRENT CONTROLFILE;
```

---

*Séance 5 · Prérequis · Module BDOE633*
