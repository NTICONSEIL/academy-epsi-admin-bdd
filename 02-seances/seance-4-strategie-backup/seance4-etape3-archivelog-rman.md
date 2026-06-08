# Séance 4 — Étape 3 : ARCHIVELOG et RMAN

> **Module BDOE633 · Séance 4 · Temps 3 (20 min)**
> Comprendre pourquoi ARCHIVELOG est obligatoire et découvrir les commandes RMAN
> qui seront exécutées en séance 5.

---

## Partie 1 — Le mode ARCHIVELOG

### Comment Oracle gère les transactions

Quand une transaction modifie des données dans Oracle, la modification est d'abord écrite dans les **redo logs** — des fichiers circulaires qui enregistrent toutes les opérations en temps réel. Ces fichiers sont réutilisés en cycle continu.

```
Redo log 1  →  Redo log 2  →  Redo log 3  →  retour au Redo log 1
   (plein)        (plein)        (actif)          (écrasé !)
```

Le problème : quand Oracle réutilise un redo log, il **écrase** les transactions précédentes. En cas de sinistre, ces transactions sont perdues définitivement.

### NOARCHIVELOG vs ARCHIVELOG

| | Mode NOARCHIVELOG ✗ | Mode ARCHIVELOG ✓ |
|---|---|---|
| **Comportement** | Les redo logs sont écrasés dès qu'ils sont pleins | Chaque redo log est **archivé** avant d'être réutilisé |
| **Sauvegarde possible** | Base fermée uniquement | Base **ouverte** — sans interruption de service |
| **Restauration** | Uniquement à la date de la dernière sauvegarde complète | À **n'importe quel point dans le temps** (PITR) |
| **RPO atteignable** | RPO = durée depuis la dernière sauvegarde complète (jours ou heures) | RPO = intervalle entre deux archivages **(15 min)** |
| **NanoOrbit** | ❌ Incompatible avec le contrat | ✅ Obligatoire |

### Ce que produit le mode ARCHIVELOG

```
Redo log 1 (plein)
    ↓ Oracle archive automatiquement
    → /opt/oracle/archive/1_123_NanoOrbit.arc  ← archive log conservé
    ↓ Redo log 1 réutilisé (vide)

Redo log 2 (plein)
    ↓
    → /opt/oracle/archive/1_124_NanoOrbit.arc
    ...
```

Chaque archive log conserve l'historique complet de toutes les transactions. En combinant la dernière sauvegarde complète + tous les archive logs produits depuis, Oracle peut **rejouer** toutes les transactions jusqu'à n'importe quel instant.

### La séquence d'activation (à exécuter en séance 5)

L'activation nécessite un redémarrage contrôlé de la base. Elle se fait en **4 étapes** et se connecte sur le service `FREE` (CDB racine), pas sur `FREEPDB1`.

```sql
-- Étape 1 : connexion en tant que SYSDBA sur le CDB (service FREE)
sqlplus sys/NanoOrbit_Sys2026@localhost:1521/FREE as sysdba

-- Étape 2 : arrêt propre de la base
SHUTDOWN IMMEDIATE;
-- Oracle termine les transactions en cours, ferme proprement

-- Étape 3 : démarrage en mode MOUNT (base non ouverte, juste montée)
STARTUP MOUNT;
-- Oracle lit le controlfile mais n'ouvre pas encore la base

-- Étape 4 : activation du mode ARCHIVELOG puis ouverture
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
-- La base est maintenant ouverte et en mode ARCHIVELOG
```

> ⚠️ **Piège fréquent** : se connecter sur `FREEPDB1` au lieu de `FREE`.
> `FREEPDB1` est le PDB (base pluggable) — il ne contrôle pas le mode archivelog.
> `FREE` est le CDB racine — seul niveau où `ALTER DATABASE ARCHIVELOG` fonctionne.

### Vérification après activation

```sql
-- Vérifier le mode de la base
SELECT name, log_mode, open_mode FROM v$database;
-- Résultat attendu : LOG_MODE = ARCHIVELOG

-- Vérifier la destination d'archivage
SHOW PARAMETER log_archive_dest_1;
-- Doit pointer vers un répertoire valide sur le disque
```

---

## Partie 2 — RMAN (Recovery Manager)

### Qu'est-ce que RMAN ?

RMAN est l'outil Oracle dédié à la sauvegarde et à la restauration. Il ne travaille pas fichier par fichier comme une copie système — il travaille **bloc par bloc** au niveau Oracle, ce qui lui permet de :
- Détecter et ignorer les blocs vides (sauvegardes plus compactes).
- Vérifier l'intégrité des blocs sauvegardés.
- Gérer automatiquement un **catalogue** de toutes les sauvegardes.
- Restaurer à un **point précis dans le temps** (PITR).

### Architecture RMAN

```
┌──────────────┐     commandes      ┌──────────────────────┐
│   RMAN CLI   │ ────────────────→  │   Instance Oracle    │
│  (client)    │                    │   (target database)  │
└──────────────┘                    └──────────┬───────────┘
                                               │
                                    ┌──────────▼───────────┐
                                    │  Catalogue RMAN      │
                                    │  (métadonnées des    │
                                    │   sauvegardes)       │
                                    └──────────────────────┘
                                               │
                                    ┌──────────▼───────────┐
                                    │  Backup sets         │
                                    │  (fichiers .bkp)     │
                                    └──────────────────────┘
```

### Connexion à RMAN

```bash
# Depuis le terminal (Git Bash ou dans le conteneur Docker)
rman target sys/NanoOrbit_Sys2026@localhost:1521/FREE

# Résultat attendu :
# Recovery Manager: Release 23.0.0.0.0
# connected to target database: FREE (DBID=...)
# RMAN>
```

> RMAN se connecte toujours sur le service `FREE` (CDB), pas `FREEPDB1`.

### Les commandes clés (aperçu séance 5)

#### Sauvegarde complète base ouverte

```sql
-- Sauvegarde complète : toutes les données + archive logs avant et après
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;

-- Sauvegarde séparée du controlfile
RMAN> BACKUP CURRENT CONTROLFILE;
```

L'option `PLUS ARCHIVELOG` inclut automatiquement :
- Les archive logs produits **avant** la sauvegarde (pour couvrir les transactions récentes).
- Les archive logs produits **pendant** la sauvegarde (pour garantir la cohérence).

#### Sauvegarde incrémentale de niveau 1

```sql
-- Ne sauvegarde que les blocs modifiés depuis la dernière sauvegarde
RMAN> BACKUP INCREMENTAL LEVEL 1 DATABASE PLUS ARCHIVELOG;
```

#### Vérification du catalogue

```sql
-- Lister toutes les sauvegardes
RMAN> LIST BACKUP SUMMARY;

-- Lister tous les archive logs disponibles
RMAN> LIST ARCHIVELOG ALL;

-- Vérifier l'intégrité de la base (sans restaurer)
RMAN> VALIDATE DATABASE;
```

> ⚠️ **Règle d'or** : toujours exécuter `LIST BACKUP SUMMARY` et `LIST ARCHIVELOG ALL` **avant** toute restauration. Restaurer sans vérifier les sauvegardes disponibles mène souvent à des erreurs évitables.

---

## Partie 3 — Le lien ARCHIVELOG → RPO → RMAN

Ces trois éléments forment une chaîne indissociable pour NanoOrbit :

```
RPO 15 min (contrat)
    ↓ impose
Mode ARCHIVELOG (Oracle)
    ↓ produit
Archive logs toutes les 15 min
    ↓ sauvegardés par
RMAN (Recovery Manager)
    ↓ permet
Restauration PITR à n'importe quel instant
    ↓ garantit
RTO 30 min (contrat)
```

Sans ARCHIVELOG, la chaîne est brisée dès le deuxième maillon — le RPO de 15 min est impossible à atteindre.

---

## Ce qui sera fait en séance 5

| Action | Commande | Durée estimée |
|---|---|---|
| Activer ARCHIVELOG | `SHUTDOWN` → `STARTUP MOUNT` → `ALTER DATABASE ARCHIVELOG` → `OPEN` | 5 min |
| Vérifier l'activation | `SELECT log_mode FROM v$database` | 1 min |
| Sauvegarde complète | `BACKUP DATABASE PLUS ARCHIVELOG` | 10-15 min |
| Sauvegarde incrémentale | `BACKUP INCREMENTAL LEVEL 1 DATABASE` | 5 min |
| Vérification catalogue | `LIST BACKUP SUMMARY` + `VALIDATE DATABASE` | 5 min |
| 3 scénarios PRA | PITR + tablespace + crash instance | 45 min |

---

## À retenir

> **ARCHIVELOG + RMAN = duo indissociable.**
>
> - Sans ARCHIVELOG : pas de PITR, pas de RPO 15 min, pas de sauvegarde base ouverte.
> - Sans RMAN : pas de gestion du catalogue, pas de vérification d'intégrité, restauration manuelle risquée.
> - Ensemble : toute la stratégie définie en L2-A devient techniquement réalisable.

---

*Séance 4 · Temps 3 · Module BDOE633*
