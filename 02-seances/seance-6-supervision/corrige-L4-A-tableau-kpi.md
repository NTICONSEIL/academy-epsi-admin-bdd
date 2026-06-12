# Corrigé — Tableau des KPI définis · NanoOrbit

> **Livrable L4-A — Corrigé instructeur.**
> Document à usage interne EPSI. Ne pas distribuer aux apprenants avant évaluation.
>
> Compétences : **ASRBD1.7** (mesurer et analyser les performances) · **ASRBD1.8** (optimiser l'emplacement des stockages)
> Séance 6 — FOAD · 2 heures

---

## 1. Identification

| Rubrique | Valeur |
|---|---|
| Base administrée | NanoOrbit — schéma `NANOORBIT_ADMIN` sur `FREEPDB1` |
| SGBD | Oracle Database 23ai Free |
| Binôme | `[ noms ]` |
| Date de rédaction | `[ date ]` |
| Version du document | v1 |

---

## 2. Rappel des engagements du contrat structurant la supervision

Chaque KPI retenu doit répondre à au moins un engagement chiffré du contrat. Ce tableau de correspondance est le fil conducteur du livrable.

| Engagement du contrat | Valeur | Famille concernée | Traduction en supervision |
|---|---|---|---|
| Disponibilité opérationnelle | 99,5 % (≈ 50 min/semaine tolérées) | Opérationnel | Surveiller l'état de l'instance en continu |
| Disponibilité référentiel | 99,9 % (heures ouvrées Paris) | Référentiel | Surveiller les tablespaces référentiel |
| RPO opérationnel | 15 minutes | Opérationnel | Vérifier la fréquence d'archivage des redo logs |
| RTO opérationnel | 30 minutes | Opérationnel | Détecter les dégradations avant rupture de service |
| Volumétrie hétérogène | Croissance continue `HISTORIQUE_STATUT` | Historique | Alerter sur l'espace libre de `TBS_HISTORIQUE` |
| Sauvegarde RMAN | Hebdo complète + incrémentale /4h | Toutes | Détecter tout échec de job RMAN |

---

## 3. Tableau des KPI — définition complète

### KPI 1 — Disponibilité de l'instance Oracle

| Attribut | Valeur |
|---|---|
| **Nom du KPI** | `INSTANCE_AVAILABILITY` |
| **Ce qu'il mesure** | Accessibilité de l'instance Oracle (état OPEN) |
| **Clause du contrat** | Disponibilité opérationnelle 99,5 % H24 |
| **Source de données** | `V$INSTANCE` — colonne `STATUS` |
| **Méthode de contrôle** | Connexion périodique + `SELECT STATUS FROM V$INSTANCE` |
| **Seuil WARNING** | Toute valeur différente de `OPEN` pendant > 2 minutes |
| **Seuil CRITICAL** | Instance inaccessible pendant > 5 minutes |
| **Fréquence de vérification** | Toutes les 5 minutes |
| **Action en cas d'alerte** | Vérifier alert log, relancer si crash ; escalader si non résolu sous 10 min |

**Requête de vérification :**

```sql
-- Connexion SYS sur service FREE (CDB)
SELECT instance_name,
       status,
       TO_CHAR(startup_time, 'DD/MM/YYYY HH24:MI') startup,
       logins
FROM   v$instance;
-- Résultat attendu : STATUS = OPEN, LOGINS = ALLOWED
```

---

### KPI 2 — Taux d'occupation des tablespaces

| Attribut | Valeur |
|---|---|
| **Nom du KPI** | `TABLESPACE_PCT_USED` |
| **Ce qu'il mesure** | Pourcentage d'espace utilisé par tablespace (`TBS_OPERATION`, `TBS_REFERENTIEL`, `TBS_HISTORIQUE`) |
| **Clause du contrat** | Disponibilité toutes familles — prévenir toute rupture de service par saturation |
| **Source de données** | `DBA_DATA_FILES` + `DBA_FREE_SPACE` |
| **Méthode de contrôle** | `DBMS_SERVER_ALERT.SET_THRESHOLD` sur `TABLESPACE_PCT_FULL` |
| **Seuil WARNING** | ≥ 80 % sur n'importe quel tablespace NanoOrbit |
| **Seuil CRITICAL** | ≥ 90 % |
| **Fréquence de vérification** | Toutes les heures (métrique automatique Oracle) |
| **Action en cas d'alerte** | WARNING : planifier une extension dans la semaine. CRITICAL : étendre immédiatement ou purger `HISTORIQUE_STATUT` si concerné. |

**Requête de vérification :**

```sql
-- Connexion SYS ou DBA sur FREEPDB1
SELECT t.tablespace_name,
       ROUND(t.total_mb, 1)                          total_mb,
       ROUND(t.total_mb - NVL(f.free_mb, 0), 1)     used_mb,
       ROUND((1 - NVL(f.free_mb, 0) / t.total_mb) * 100, 1) pct_used
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
```

---

### KPI 3 — Latence des insertions sur `FENETRE_COM`

| Attribut | Valeur |
|---|---|
| **Nom du KPI** | `FENETRE_COM_INSERT_LATENCY` |
| **Ce qu'il mesure** | Temps moyen d'exécution des requêtes INSERT sur `FENETRE_COM` |
| **Clause du contrat** | RPO 15 min + RTO 30 min sur l'opérationnel — une dégradation des écritures compromet les deux |
| **Source de données** | `V$SQL` — filtre sur `SQL_TEXT LIKE '%FENETRE_COM%'` et `COMMAND_TYPE = 2` (INSERT) |
| **Méthode de contrôle** | Requête périodique sur `V$SQL` |
| **Seuil WARNING** | Temps moyen > 200 ms (`ELAPSED_TIME / EXECUTIONS > 200 000` µs) |
| **Seuil CRITICAL** | Temps moyen > 500 ms |
| **Fréquence de vérification** | Toutes les 15 minutes (aligné sur le RPO) |
| **Action en cas d'alerte** | Vérifier les verrous (`V$LOCK`), les sessions bloquantes (`V$SESSION.BLOCKING_SESSION`), la fragmentation du tablespace `TBS_OPERATION`. |

**Requête de vérification :**

```sql
-- Connexion NANOORBIT_ADMIN ou SYS sur FREEPDB1
SELECT sql_id,
       ROUND(elapsed_time / NULLIF(executions, 0) / 1000, 1) avg_ms,
       executions,
       SUBSTR(sql_text, 1, 80) sql_extrait
FROM   v$sql
WHERE  UPPER(sql_text) LIKE '%FENETRE_COM%'
  AND  command_type = 2   -- INSERT
  AND  executions > 0
ORDER BY avg_ms DESC
FETCH FIRST 10 ROWS ONLY;
-- Seuil WARNING dépassé si avg_ms > 200
```

---

### KPI 4 — Sessions actives Oracle

| Attribut | Valeur |
|---|---|
| **Nom du KPI** | `ACTIVE_SESSIONS_COUNT` |
| **Ce qu'il mesure** | Nombre de sessions en état `ACTIVE` sur l'instance |
| **Clause du contrat** | Disponibilité opérationnelle 99,5 % — une explosion du nombre de sessions indique une saturation du pool de connexions ou un verrou généralisé |
| **Source de données** | `V$SESSION` |
| **Méthode de contrôle** | `DBMS_SERVER_ALERT.SET_THRESHOLD` sur `CURRENT_LOGONS_COUNT` ou requête directe |
| **Seuil WARNING** | > 50 sessions actives simultanées |
| **Seuil CRITICAL** | > 80 sessions actives simultanées |
| **Fréquence de vérification** | Toutes les 5 minutes |
| **Action en cas d'alerte** | Identifier les sessions bloquantes (`BLOCKING_SESSION`), les requêtes longues (`LAST_CALL_ET`), envisager un `ALTER SYSTEM KILL SESSION` si nécessaire. |

**Requête de vérification :**

```sql
-- Nombre de sessions actives en temps réel
SELECT COUNT(*) nb_sessions_actives
FROM   v$session
WHERE  status = 'ACTIVE'
  AND  username IS NOT NULL;

-- Détail des sessions longues (> 60 secondes actives)
SELECT sid, serial#, username,
       last_call_et      secondes_actives,
       blocking_session,
       SUBSTR(module, 1, 30) module
FROM   v$session
WHERE  status      = 'ACTIVE'
  AND  username    IS NOT NULL
  AND  last_call_et > 60
ORDER BY last_call_et DESC;
```

---

### KPI 5 — Temps d'exécution du package `pkg_nanoOrbit`

| Attribut | Valeur |
|---|---|
| **Nom du KPI** | `PKG_NANOORBIT_EXEC_TIME` |
| **Ce qu'il mesure** | Temps moyen d'exécution des procédures du package `PKG_NANOORBIT` |
| **Clause du contrat** | RTO opérationnel 30 min — le package orchestre les opérations critiques (gestion des fenêtres de communication, historique) |
| **Source de données** | `V$SQL` filtre sur `OBJECT_NAME = 'PKG_NANOORBIT'` ou `SQL_TEXT LIKE '%pkg_nanoOrbit%'` |
| **Méthode de contrôle** | Requête périodique sur `V$SQL` |
| **Seuil WARNING** | Temps moyen > 1 seconde (`ELAPSED_TIME / EXECUTIONS > 1 000 000` µs) |
| **Seuil CRITICAL** | Temps moyen > 3 secondes |
| **Fréquence de vérification** | Toutes les 15 minutes |
| **Action en cas d'alerte** | Analyser le plan d'exécution (`DBMS_XPLAN.DISPLAY_CURSOR`), vérifier l'état des index sur `FENETRE_COM` et `HISTORIQUE_STATUT`. |

**Requête de vérification :**

```sql
SELECT sql_id,
       ROUND(elapsed_time / NULLIF(executions, 0) / 1000000, 3) avg_sec,
       executions,
       SUBSTR(sql_text, 1, 80) sql_extrait
FROM   v$sql
WHERE  UPPER(sql_text) LIKE '%PKG_NANOORBIT%'
  AND  executions > 0
ORDER BY avg_sec DESC
FETCH FIRST 10 ROWS ONLY;
-- Seuil WARNING dépassé si avg_sec > 1
```

---

### KPI 6 — Croissance de `HISTORIQUE_STATUT`

| Attribut | Valeur |
|---|---|
| **Nom du KPI** | `HISTORIQUE_STATUT_GROWTH` |
| **Ce qu'il mesure** | Taux de croissance hebdomadaire de la table `HISTORIQUE_STATUT` dans `TBS_HISTORIQUE` |
| **Clause du contrat** | Volumétrie historique en croissance continue — anticipation de la saturation de `TBS_HISTORIQUE` |
| **Source de données** | `USER_SEGMENTS` (taille actuelle) comparée à une mesure précédente |
| **Méthode de contrôle** | Snapshot hebdomadaire via Statspack + requête `USER_SEGMENTS` |
| **Seuil WARNING** | Croissance > 10 % par semaine |
| **Seuil CRITICAL** | Croissance > 25 % par semaine |
| **Fréquence de vérification** | Hebdomadaire (peut être quotidienne si charge forte) |
| **Action en cas d'alerte** | WARNING : planifier l'extension de `TBS_HISTORIQUE`. CRITICAL : vérifier si une purge des données historiques anciennes est prévue au contrat (conservation 7 ans). |

**Requête de vérification :**

```sql
-- Taille actuelle de HISTORIQUE_STATUT
SELECT segment_name,
       tablespace_name,
       ROUND(bytes / 1048576, 2)  taille_mb,
       SYSDATE                    mesure_le
FROM   user_segments
WHERE  segment_name = 'HISTORIQUE_STATUT';
-- À comparer avec la mesure précédente pour calculer la croissance
```

---

### KPI 7 — Succès des sauvegardes RMAN

| Attribut | Valeur |
|---|---|
| **Nom du KPI** | `RMAN_BACKUP_STATUS` |
| **Ce qu'il mesure** | Statut du dernier job RMAN exécuté (complète hebdo + incrémentale /4h) |
| **Clause du contrat** | RPO 15 min opérationnel + RPO 24 h référentiel/historique — tout échec RMAN compromet la capacité de restauration |
| **Source de données** | `V$RMAN_BACKUP_JOB_DETAILS` |
| **Méthode de contrôle** | Requête après chaque fenêtre de sauvegarde planifiée |
| **Seuil WARNING** | 1 job RMAN en statut `FAILED` ou `COMPLETED WITH WARNINGS` |
| **Seuil CRITICAL** | 2 jobs consécutifs en échec sur le même type de sauvegarde |
| **Fréquence de vérification** | Après chaque exécution planifiée (hourly check) |
| **Action en cas d'alerte** | Consulter `V$RMAN_BACKUP_JOB_DETAILS.INPUT_BYTES_DISPLAY`, vérifier l'espace disque `/opt/oracle/backup/nanoorbit/`, relancer manuellement si besoin. |

**Requête de vérification :**

```sql
-- Connexion SYS sur FREEPDB1
SELECT job_id,
       TO_CHAR(start_time, 'DD/MM HH24:MI') debut,
       TO_CHAR(end_time,   'DD/MM HH24:MI') fin,
       status,
       input_bytes_display  volume_lu,
       output_bytes_display volume_sauvegarde,
       time_taken_display   duree
FROM   v$rman_backup_job_details
ORDER BY start_time DESC
FETCH FIRST 10 ROWS ONLY;
-- Résultat attendu : STATUS = 'COMPLETED' pour tous les jobs récents
```

---

## 4. Synthèse — Tableau de bord récapitulatif

| # | KPI | Clause contrat | Source | WARNING | CRITICAL | Fréquence |
|---|-----|---------------|--------|---------|----------|-----------|
| 1 | Disponibilité instance | Dispo 99,5 % | `V$INSTANCE` | ≠ OPEN / 2 min | Inaccessible / 5 min | 5 min |
| 2 | Taux d'occupation tablespace | Volumétrie toutes familles | `DBA_FREE_SPACE` | ≥ 80 % | ≥ 90 % | 1 h |
| 3 | Latence INSERT `FENETRE_COM` | RPO 15 min + RTO 30 min | `V$SQL` | > 200 ms | > 500 ms | 15 min |
| 4 | Sessions actives | Dispo opérationnel | `V$SESSION` | > 50 | > 80 | 5 min |
| 5 | Temps exécution `pkg_nanoOrbit` | RTO opérationnel 30 min | `V$SQL` | > 1 s | > 3 s | 15 min |
| 6 | Croissance `HISTORIQUE_STATUT` | Volumétrie historique | `USER_SEGMENTS` | > 10 %/sem | > 25 %/sem | Hebdo |
| 7 | Succès sauvegardes RMAN | RPO toutes familles | `V$RMAN_BACKUP_JOB_DETAILS` | 1 échec | 2 consécutifs | Après chaque job |

---

## 5. Note pédagogique — critères d'évaluation

Un livrable L4-A de qualité présente :

- **Minimum 5 KPI** — les 7 ci-dessus constituent la réponse complète ; accepter 5 avec justifications solides.
- **Lien contrat systématique** — chaque KPI doit citer la clause justificative. Un KPI sans lien au contrat est hors périmètre.
- **Seuils différenciés** — WARNING et CRITICAL distincts et cohérents (CRITICAL toujours plus sévère que WARNING).
- **Requête SQL associée** — la requête doit être exécutable sur l'instance NanoOrbit sans modification.
- **Couverture des trois familles** — au moins un KPI pour chacune des familles référentiel, opérationnel, historique.

> **Point de vigilance** : les étudiants peuvent proposer des KPI différents de ceux-ci. Valider dès lors que le lien contrat est explicite et la requête correcte.

---

*Corrigé instructeur — Séance 6 FOAD — BDOE633 · EPSI · NTIConseil · 2025-2026*
