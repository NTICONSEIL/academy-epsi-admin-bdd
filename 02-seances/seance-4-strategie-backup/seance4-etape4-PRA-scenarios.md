# Séance 4 — Étape 4 : Les 3 scénarios du Plan de Reprise d'Activité

> **Module BDOE633 · Séance 4 · Temps 4 (25 min)**
> Produit le livrable **L2-B** — Plan de Reprise d'Activité NanoOrbit.

---

## Qu'est-ce qu'un PRA ?

Un **Plan de Reprise d'Activité** (PRA) est un document qui répond à une question simple :

> **"Si tel incident survient, que fait-on exactement, dans quel ordre, et en combien de temps ?"**

Un PRA sans test n'est qu'un vœu pieux. C'est pourquoi chaque procédure définie ici sera **exécutée et chronométrée** en séance 5 — et le temps réel comparé au RTO contractuel.

### Les engagements à respecter pour chaque scénario

| Engagement | Valeur NanoOrbit | Famille concernée |
|---|---|---|
| **RPO** — perte de données maximale | 15 minutes | Opérationnel |
| **RTO** — délai de remise en service | 30 minutes | Opérationnel |
| **Disponibilité** | 99,5 % | Toutes |

---

## Scénario 1 — DELETE erroné sur FENETRE_COM (PITR)

### Contexte

Un opérateur exécute par erreur `DELETE FROM FENETRE_COM` suivi d'un `COMMIT`. Toutes les fenêtres de communication planifiées sont supprimées — les prochains passages satellites ne peuvent plus être traités. L'erreur est détectée 10 minutes après.

### Pourquoi ce scénario est récupérable

En mode ARCHIVELOG, Oracle conserve l'historique de toutes les transactions dans les archive logs. Il est possible de **rembobiner la base à un point précis dans le temps** — juste avant le DELETE — en rejouant les transactions depuis la dernière sauvegarde jusqu'à cet instant. C'est la **restauration PITR** (*Point In Time Recovery*).

```
Dimanche 02:00        Lundi 14:29          Lundi 14:30        Lundi 14:40
Sauvegarde complète   ← état souhaité →    DELETE + COMMIT    Incident détecté
       ↓                     ↑
       └── archive logs ──────┘
           (rejoués jusqu'à 14:29)
```

### Procédure de restauration PITR

**Prérequis** : être connecté en `SYSDBA` sur le service `FREE`.

**Étape 1 — Identifier l'heure de l'incident**

```sql
-- Dans SQL*Plus, interroger l'historique des logs
SELECT first_time, next_time, sequence#
FROM v$log_history
ORDER BY first_time DESC;

-- Ou consulter l'heure système au moment de la détection
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM DUAL;
```

**Étape 2 — Vérifier que le RPO est tenable**

```
Heure de l'incident − heure du dernier archive log disponible ≤ 15 min ?
```

Si oui → la restauration PITR est possible dans les limites contractuelles.

**Étape 3 — Restauration PITR dans RMAN**

```sql
-- Connexion RMAN
rman target sys/NanoOrbit_Sys2026@localhost:1521/FREE

-- Arrêt propre
RMAN> SHUTDOWN IMMEDIATE;

-- Montage de la base (sans l'ouvrir)
RMAN> STARTUP MOUNT;

-- Définir le point de restauration (1 minute avant l'incident)
RMAN> SET UNTIL TIME "TO_DATE('2025-06-01 14:29:00','YYYY-MM-DD HH24:MI:SS')";

-- Restaurer les datafiles depuis la sauvegarde
RMAN> RESTORE DATABASE;

-- Rejouer les archive logs jusqu'au point défini
RMAN> RECOVER DATABASE;

-- Ouvrir la base en RESETLOGS (obligatoire après toute PITR)
RMAN> ALTER DATABASE OPEN RESETLOGS;
```

> ⚠️ **`RESETLOGS` est obligatoire** après une restauration PITR. Il réinitialise la séquence des redo logs — toute sauvegarde précédente devient inutilisable. **Une nouvelle sauvegarde complète doit être faite immédiatement après.**

**Étape 4 — Contrôle post-restauration**

```sql
-- Vérifier que les fenêtres sont revenues
SELECT COUNT(*) FROM nanoorbit_admin.fenetre_com;
-- Doit retourner 5 (le nombre avant l'incident)

-- Vérifier l'état global de la constellation
SELECT pkg_nanoOrbit.statut_constellation() FROM DUAL;

-- Vérifier que les triggers sont actifs
SELECT trigger_name, status FROM user_triggers
WHERE owner = 'NANOORBIT_ADMIN';
```

**RTO estimé : ~25 min** ✅ conforme au contrat (30 min).

---

## Scénario 2 — Crash d'instance / panne serveur (SMON)

### Contexte

Le serveur Docker hébergeant Oracle subit une coupure de courant brutale ou un crash OS. La base Oracle s'arrête sans checkpoint — certaines transactions en cours n'ont pas été écrites sur le disque.

### Procédure de décision

Ce scénario suit un **arbre de décision** avant d'agir :

```
                    ┌─────────────────────────┐
                    │  Instance redémarre      │
                    │  seule ?                 │
                    └────────────┬────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
           OUI ↓                                  NON ↓
    ┌──────────────────┐              ┌─────────────────────────┐
    │ Instance Recovery │              │ Fichiers de données      │
    │ automatique       │              │ endommagés ?             │
    │ (SMON se charge   │              └──────────┬──────────────┘
    │  de tout)         │                         │
    └──────────────────┘              ┌───────────┴────────────┐
                                   OUI ↓                    NON ↓
                            ┌──────────────┐        ┌──────────────────┐
                            │ RMAN RESTORE │        │ Rejouer les       │
                            │ complète     │        │ archive logs      │
                            └──────────────┘        │ uniquement        │
                                                    └──────────────────┘
```

### Cas 1 — Instance Recovery automatique par SMON (cas le plus fréquent)

Quand Oracle redémarre après un crash brutal, le processus **SMON** (*System Monitor*) déclenche automatiquement une **Instance Recovery** :

1. **Roll forward** : SMON relit les redo logs depuis le dernier checkpoint et rejoue toutes les transactions committées non encore écrites sur disque.
2. **Rollback** : SMON annule toutes les transactions qui n'avaient pas été committées au moment du crash.
3. **Résultat** : la base est cohérente, aucune intervention manuelle n'est nécessaire.

```sql
-- Simulation en séance 5 : crash brutal
SHUTDOWN ABORT;  -- simule une coupure de courant (pas de checkpoint)

-- Redémarrage : SMON fait son travail automatiquement
STARTUP;

-- Observer les traces de l'Instance Recovery dans l'alert log
SELECT value FROM v$diag_info WHERE name = 'Diag Trace';
-- Puis depuis le terminal Docker :
-- tail -50 /opt/oracle/diag/rdbms/free/FREE/trace/alert_FREE.log
```

Les lignes clés à observer dans l'alert log :

```
Beginning crash recovery of 1 threads
Started redo scan
Completed redo scan
...
Thread recovery: start rolling forward thread 1
Thread recovery: finish rolling forward thread 1
...
Completed crash recovery at
```

**RTO estimé : ~5 min** ✅ très largement conforme au contrat (30 min).

### Cas 2 — Fichiers de données endommagés (RMAN nécessaire)

Si le crash a corrompu des datafiles, SMON ne peut pas récupérer seul. Il faut intervenir manuellement avec RMAN :

```sql
-- Connexion RMAN
rman target sys/NanoOrbit_Sys2026@localhost:1521/FREE

RMAN> SHUTDOWN IMMEDIATE;
RMAN> STARTUP MOUNT;
RMAN> RESTORE DATABASE;
RMAN> RECOVER DATABASE;
RMAN> ALTER DATABASE OPEN;
```

**RTO estimé : ~30-40 min** ⚠️ limite du contrat — à surveiller lors des tests séance 5.

---

## Scénario 3 — Perte d'un tablespace (RESTORE TABLESPACE)

### Contexte

Le fichier physique `tbs_operation.dbf` est corrompu ou supprimé accidentellement. Le tablespace `TBS_OPERATION` est inaccessible — les tables `SATELLITE`, `FENETRE_COM`, `PARTICIPATION`... ne répondent plus.

### Avantage clé de l'organisation en tablespaces

Grâce à la réorganisation effectuée en séance 3, **les autres tablespaces restent disponibles** :
- `TBS_REFERENTIEL` → accessible ✅
- `TBS_HISTORIQUE` → accessible ✅
- `TBS_OPERATION` → inaccessible ❌ (en cours de restauration)

Sans cette ségrégation, un incident sur `USERS` aurait bloqué **toute la base**.

### Procédure de restauration de tablespace

**Étape 1 — Mettre le tablespace offline**

```sql
-- Depuis SQL*Plus en SYSDBA
ALTER TABLESPACE TBS_OPERATION OFFLINE IMMEDIATE;
-- IMMEDIATE : force le offline même si des transactions sont en cours
-- La base reste ouverte — seul TBS_OPERATION est offline
```

**Étape 2 — Restaurer le datafile depuis RMAN**

```sql
-- Connexion RMAN (base OUVERTE — pas besoin de l'arrêter)
rman target sys/NanoOrbit_Sys2026@localhost:1521/FREE

-- Restaurer uniquement le tablespace concerné
RMAN> RESTORE TABLESPACE TBS_OPERATION;
-- RMAN récupère le datafile depuis la dernière sauvegarde complète
```

**Étape 3 — Récupérer les transactions (rejouer les archive logs)**

```sql
RMAN> RECOVER TABLESPACE TBS_OPERATION;
-- RMAN rejoue les archive logs depuis la sauvegarde jusqu'au présent
-- → les données perdues entre la sauvegarde et l'incident sont récupérées
```

**Étape 4 — Remettre le tablespace online**

```sql
-- Depuis SQL*Plus en SYSDBA
ALTER TABLESPACE TBS_OPERATION ONLINE;
```

**Étape 5 — Contrôle d'intégrité**

```sql
-- Vérifier le statut des tablespaces
SELECT tablespace_name, status FROM dba_tablespaces
WHERE tablespace_name IN ('TBS_REFERENTIEL','TBS_OPERATION','TBS_HISTORIQUE');
-- TBS_OPERATION doit être ONLINE

-- Vérifier les données
SELECT COUNT(*) FROM nanoorbit_admin.fenetre_com;
SELECT COUNT(*) FROM nanoorbit_admin.satellite;
```

**RTO estimé : ~20 min** ✅ conforme au contrat (30 min).

---

## Synthèse — Conformité contrat des 3 scénarios (Livrable L2-B)

| Scénario | Cause | Mécanisme Oracle | RTO estimé | RPO | Conforme ? |
|---|---|---|---|---|---|
| DELETE/INSERT erroné | Erreur opérateur | RMAN PITR (`RECOVER UNTIL TIME` + `RESETLOGS`) | ~25 min | ✅ 15 min | ✅ Oui |
| Crash instance / OS | Panne serveur | Instance Recovery automatique (SMON) | ~5 min | ✅ 15 min | ✅ Oui |
| Perte tablespace | Corruption `.dbf` | RMAN `RESTORE` + `RECOVER TABLESPACE` | ~20 min | ✅ 15 min | ✅ Oui |

> **Contrat NanoOrbit — RTO 30 min · RPO 15 min · Disponibilité 99,5 %**
> Les 3 scénarios sont conformes **en théorie**. La séance 5 les valide **en pratique** avec mesure du temps réel.

---

## Points d'attention pour les tests séance 5

| Point | Détail |
|---|---|
| **Après PITR** | Faire immédiatement une nouvelle sauvegarde complète — le `RESETLOGS` invalide les anciennes |
| **Vérifier les triggers** | Après toute restauration, confirmer que les 5 triggers sont actifs (`user_triggers`) |
| **Mesurer le temps** | Chronométrer depuis la première commande RMAN jusqu'au `SELECT COUNT(*)` de validation |
| **Alert log** | Pour le scénario 2, copier les 3 lignes clés de l'Instance Recovery dans le compte-rendu L3-C |

---

*Séance 4 · Temps 4 · Module BDOE633 — Livrable L2-B*
