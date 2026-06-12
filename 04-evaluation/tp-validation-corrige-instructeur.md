# CORRIGÉ INSTRUCTEUR — TP DE VALIDATION BDOE633
## Administration et Optimisation des Bases de Données

> **Usage interne EPSI — Ne pas distribuer aux étudiants**  
> Module BDOE633 · Bachelor SIN SysOps · 2025-2026

---

## RAPPEL DES CONDITIONS D'ÉVALUATION

- Individuel, 1h30, base Oracle 23ai NanoOrbit en état dégradé
- Connexion étudiant : `NANOORBIT_ADMIN/NanoOrbit_2026@localhost:1521/FREEPDB1`
- Connexion instructeur (pour Blocs A/D) : `SYS/NanoOrbit_Sys2026@localhost:1521/FREE AS SYSDBA` puis `ALTER SESSION SET CONTAINER = FREEPDB1`
- L'incident 3 (DELETE FENETRE_COM) est déclenché par l'instructeur à t+10 min environ

---

## BLOC A — Diagnostic du stockage (20 min / 4 pts)

---

### A1 — Taux d'occupation des tablespaces NanoOrbit *(1 pt)*

**Réponse attendue :**

```sql
SELECT d.tablespace_name,
       ROUND(d.bytes / 1024 / 1024, 2)       AS total_mb,
       ROUND(NVL(f.bytes, 0) / 1024 / 1024, 2) AS libre_mb,
       ROUND((1 - NVL(f.bytes, 0) / d.bytes) * 100, 1) AS pct_utilise
FROM (
  SELECT tablespace_name, SUM(bytes) AS bytes
  FROM   dba_data_files
  GROUP BY tablespace_name
) d
LEFT JOIN (
  SELECT tablespace_name, SUM(bytes) AS bytes
  FROM   dba_free_space
  GROUP BY tablespace_name
) f USING (tablespace_name)
WHERE  d.tablespace_name IN ('TBS_OPERATION','TBS_REFERENTIEL','TBS_HISTORIQUE')
ORDER BY pct_utilise DESC;
```

**Sortie type attendue :**

```
TABLESPACE_NAME    TOTAL_MB  LIBRE_MB  PCT_UTILISE
------------------ --------  --------  -----------
TBS_OPERATION          2,00      0,19        90,5
TBS_REFERENTIEL        5,00      4,44        11,2
TBS_HISTORIQUE         5,00      4,56         8,8
```

> **Note de correction** : les valeurs exactes varient selon l'état de la base de chaque étudiant. Ce qui compte : TBS_OPERATION affiche un taux > 85 %, les deux autres sont normaux. Accepter toute requête utilisant `DBA_DATA_FILES` + `DBA_FREE_SPACE` avec calcul de ratio.

**Point à valoriser** : l'utilisation de `NVL(f.bytes, 0)` pour gérer le cas où un tablespace est 100 % plein (aucune ligne dans `DBA_FREE_SPACE`).

---

### A2 — Top 3 des tables dans TBS_OPERATION *(0,5 pt)*

**Réponse attendue :**

```sql
SELECT segment_name, segment_type,
       ROUND(bytes / 1024 / 1024, 3) AS taille_mb
FROM   dba_segments
WHERE  tablespace_name = 'TBS_OPERATION'
  AND  segment_type    = 'TABLE'
ORDER BY bytes DESC
FETCH FIRST 3 ROWS ONLY;
```

**Vue utilisée** : `DBA_SEGMENTS` (ou `USER_SEGMENTS` si connecté en NANOORBIT_ADMIN — acceptable).

**Sortie type :**

```
SEGMENT_NAME          SEGMENT_TYPE  TAILLE_MB
--------------------- ------------ ----------
FENETRE_COM           TABLE             0,063
SATELLITE             TABLE             0,063
PARTICIPATION         TABLE             0,063
```

> Les tailles sont identiques à ce stade (base peu peuplée). Ce qui est évalué : la maîtrise de `DBA_SEGMENTS` / `USER_SEGMENTS` et du filtre `TABLESPACE_NAME`.

---

### A3 — Commande d'ajout d'espace *(1 pt)*

**Réponse attendue :**

```sql
ALTER TABLESPACE TBS_OPERATION
  ADD DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/tbs_operation02.dbf'
  SIZE 10M
  AUTOEXTEND ON NEXT 5M MAXSIZE 200M;
```

**Critères de notation** :
- ✓ `ALTER TABLESPACE … ADD DATAFILE` (pas `ALTER DATABASE DATAFILE`) — syntaxe correcte pour ajouter un fichier
- ✓ Chemin cohérent avec l'environnement NanoOrbit
- ✓ `SIZE 10M` présent
- ✓ `AUTOEXTEND ON NEXT 5M MAXSIZE 200M` présent

> Déduire 0,25 pt si l'étudiant écrit `ALTER DATABASE DATAFILE … RESIZE` (agrandit un fichier existant — techniquement possible mais ce n'est pas ce qui est demandé). Accepter les variantes `SIZE 10240K` etc.

---

### A4 — Vérification post-correction *(0,5 pt)*

L'étudiant doit relancer la requête de A1 et montrer que `TBS_OPERATION` est redescendu sous 50 %.

**Sortie attendue après l'ajout :**

```
TABLESPACE_NAME    TOTAL_MB  LIBRE_MB  PCT_UTILISE
------------------ --------  --------  -----------
TBS_OPERATION         12,00     10,19         15,1
```

> Tolérance : tout taux < 50 % est correct. Pénaliser si l'étudiant ne fournit pas la sortie de vérification.

---

### A5 — Justification contractuelle *(1 pt)*

**Réponse attendue (paraphrase acceptée) :**

> `TBS_OPERATION` contient les tables opérationnelles (`FENETRE_COM`, `SATELLITE`…) soumises au RPO de 15 minutes. Si ce tablespace sature, les insertions de fenêtres de communication échouent — les données satellites ne sont plus enregistrées. Cela fait basculer la disponibilité en dessous du seuil contractuel de 99,5 %.

**Mots-clés attendus** : RPO 15 min / fenêtres de communication / disponibilité 99,5 % / insertions bloquées.

---

## BLOC B — Sauvegarde RMAN (25 min / 5 pts)

---

### B1 — Vérification ARCHIVELOG *(0,5 pt)*

**Requête attendue :**

```sql
SELECT log_mode FROM v$database;
```

**Résultat attendu :**

```
LOG_MODE
------------
ARCHIVELOG
```

> Si un étudiant obtient `NOARCHIVELOG` : la base est dans un état anormal (l'instructeur doit vérifier le setup). Dans ce cas, l'étudiant doit activer ARCHIVELOG avant de continuer (séance 5) :
> ```sql
> SHUTDOWN IMMEDIATE;
> STARTUP MOUNT;
> ALTER DATABASE ARCHIVELOG;
> ALTER DATABASE OPEN;
> ```

---

### B2 — Sauvegarde complète RMAN *(2 pts)*

**Commandes attendues dans RMAN :**

```
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;
RMAN> BACKUP CURRENT CONTROLFILE;
```

**Sortie type (extraits significatifs) :**

```
Starting backup at 11-JUN-26
using channel ORA_DISK_1
channel ORA_DISK_1: starting full datafile backup set
...
Finished backup at 11-JUN-26

Starting backup at 11-JUN-26
current log archived
...
Finished backup at 11-JUN-26
```

**Critères de notation** :
- ✓ 1 pt : `BACKUP DATABASE PLUS ARCHIVELOG` correct et exécuté
- ✓ 0,5 pt : `BACKUP CURRENT CONTROLFILE` présent
- ✓ 0,5 pt : sortie RMAN collée montrant `Finished backup`

> Déduire 0,5 pt si l'étudiant fait `BACKUP DATABASE` sans `PLUS ARCHIVELOG` — la sauvegarde est incomplète (archivelogs non inclus, RPO non garanti).

---

### B3 — LIST BACKUP SUMMARY *(1 pt)*

**Commande :**

```
RMAN> LIST BACKUP SUMMARY;
```

**Sortie type :**

```
List of Backups
===============
Key     TY LV S Device Type Completion Time #Pieces #Copies Compressed Tag
------- -- -- - ----------- --------------- ------- ------- ---------- ---
1       B  F  A DISK        11-JUN-26             1       1 NO         TAG20260611T031722
2       B  A  A DISK        11-JUN-26             1       1 NO         TAG20260611T031812
3       B  F  A DISK        11-JUN-26             1       1 NO         TAG20260611T031820
```

**Réponse attendue** : 3 pièces (base + archivelogs + controlfile). Espace total variable selon la taille de la base (typiquement 30-60 MB pour NanoOrbit).

> Accepter toute sortie cohérente avec une sauvegarde complète réussie.

---

### B4 — VALIDATE DATABASE *(1 pt)*

**Commande :**

```
RMAN> VALIDATE DATABASE;
```

**Sortie attendue :**

```
Starting validate at 11-JUN-26
...
validated datafile 1 ...
...
List of Datafiles
=================
File Status Marked Corrupt Empty Blocks Blocks Examined High SCN
---- ------ -------------- ----------- --------------- --------
...
Finished validate at 11-JUN-26
```

**Ce que vérifie cette commande** (réponse attendue de l'étudiant) :

> `VALIDATE DATABASE` lit tous les blocs de données de la base et détecte les corruptions physiques (blocs corrompus, checksums invalides) sans restaurer quoi que ce soit. Cela confirme l'intégrité des fichiers de données avant et après une sauvegarde.

---

### B5 — RPO réel vs contractuel *(0,5 pt)*

**Raisonnement attendu :**

> La sauvegarde vient d'être réalisée. Le RPO réel est **0 minute** (toutes les données jusqu'à maintenant sont sauvegardées). En revanche, si aucune nouvelle sauvegarde n'est lancée, le RPO se dégradera progressivement. Pour garantir un RPO de 15 min en permanence, il faudrait des sauvegardes incrémentielles toutes les 15 minutes ou s'appuyer sur la journalisation ARCHIVELOG continu.

> **Point de nuance à valoriser** : un étudiant qui distingue "RPO instantané" (0 juste après la sauvegarde) et "RPO dégradé dans le temps" (croissant si pas de sauvegarde incrémentielle) mérite le point entier.

---

## BLOC C — Restauration (25 min / 6 pts)

---

### C1 — Constat de l'incident *(0,5 pt)*

**Requête attendue :**

```sql
SELECT statut, COUNT(*) AS nb
FROM   fenetre_com
GROUP BY statut;
```

**Résultat après incident :**

```
STATUT      NB
----------- --
Réalisée     3
```

*(Les 2 lignes `Planifiée` ont été supprimées par l'instructeur.)*

**État initial de référence** (jeu de données NanoOrbit) :

```
STATUT      NB
----------- --
Réalisée     3
Planifiée    2
```

L'étudiant doit constater la perte des 2 fenêtres planifiées.

---

### C2 — Tentative Flashback Table *(2 pts)*

**Commandes attendues :**

```sql
-- Activer le mouvement de lignes (prérequis Flashback Table)
ALTER TABLE fenetre_com ENABLE ROW MOVEMENT;

-- Flashback à l'horodatage fourni par l'instructeur
FLASHBACK TABLE fenetre_com TO TIMESTAMP
  TO_TIMESTAMP('2026-06-11 03:27:00', 'YYYY-MM-DD HH24:MI:SS');
```

**Vérification :**

```sql
SELECT statut, COUNT(*) FROM fenetre_com GROUP BY statut;
```

**Résultat si succès :**

```
STATUT      COUNT(*)
----------- --------
Réalisée           3
Planifiée          2
```

**Explication attendue (pourquoi ça fonctionne ou échoue) :**

> Flashback Table fonctionne si le DELETE a eu lieu **dans la fenêtre UNDO** (paramètre `UNDO_RETENTION`, défaut 900 secondes / 15 minutes). Si l'incident a été simulé il y a moins de 15 minutes, les blocs UNDO sont encore disponibles → Flashback réussit en ~10 secondes sans arrêt de la base.  
> Si le délai dépasse `UNDO_RETENTION`, Oracle a pu recycler les blocs UNDO → erreur `ORA-01555: snapshot too old` → il faut passer au PITR RMAN.

**Critères de notation** :
- ✓ 0,5 pt : `ALTER TABLE … ENABLE ROW MOVEMENT` présent
- ✓ 1 pt : commande `FLASHBACK TABLE … TO TIMESTAMP` correcte
- ✓ 0,5 pt : explication du mécanisme UNDO_RETENTION et de la condition de succès/échec

---

### C3 — PITR RMAN (si Flashback échoue) *(2 pts)*

**Commandes RMAN attendues :**

```
RMAN> SHUTDOWN IMMEDIATE;
RMAN> STARTUP MOUNT;
RMAN> SET UNTIL TIME "TO_DATE('2026-06-11 03:27:00','YYYY-MM-DD HH24:MI:SS')";
RMAN> RESTORE DATABASE;
RMAN> RECOVER DATABASE;
RMAN> ALTER DATABASE OPEN RESETLOGS;
```

> **Note** : si Flashback Table a réussi en C2, l'étudiant décrit la procédure PITR sans l'exécuter. Accepter une réponse théorique complète pour les 2 points.

**Critères de notation** :
- ✓ 0,5 pt : `STARTUP MOUNT` avant la restauration
- ✓ 0,5 pt : `SET UNTIL TIME` avec horodatage correct
- ✓ 0,5 pt : séquence `RESTORE` puis `RECOVER` dans le bon ordre
- ✓ 0,5 pt : `ALTER DATABASE OPEN RESETLOGS` en fin

> Pénaliser si l'étudiant omet `RESETLOGS` (la base ne peut pas ouvrir après PITR sans cette option) ou inverse `RESTORE` et `RECOVER`.

---

### C4 — Vérification post-restauration *(0,5 pt)*

**Requête et sortie attendue :**

```sql
SELECT statut, COUNT(*) FROM fenetre_com GROUP BY statut;
-- Résultat :
-- Réalisée     3
-- Planifiée    2
```

L'étudiant doit montrer que les 2 fenêtres planifiées sont revenues.

---

### C5 — Mesure du RTO *(1 pt)*

**Raisonnement attendu :**

- **Via Flashback Table** : RTO mesuré ~1-2 minutes. Bien en dessous du RTO contractuel de 30 min. ✓
- **Via PITR RMAN** : RTO mesuré ~15-25 minutes selon la taille de la base. Encore dans le contrat, mais proche de la limite. ⚠️

**Verdict attendu de l'étudiant :**

> Flashback Table est la méthode préférable pour ce type d'incident car elle ne nécessite pas d'arrêt de la base (disponibilité maintenue) et le RTO est de l'ordre de la minute. Le PITR RMAN reste dans le contrat mais impose un arrêt de la base, ce qui fait baisser la disponibilité calculée. Pour une base en production 24/7 à 99,5 %, Flashback doit être la première tentative.

> **Point de valorisation** : un étudiant qui mentionne le lien entre arrêt de la base (PITR) et impact sur le calcul du 99,5 % de disponibilité mérite le point entier.

---

## BLOC D — Supervision avec les vues V$ (20 min / 5 pts)

---

### D1 — Sessions actives V$SESSION *(1 pt)*

**Connexion requise : SYS (les vues V$ ne sont pas accessibles en NANOORBIT_ADMIN)**

```sql
-- Connexion : sys/NanoOrbit_Sys2026@localhost:1521/FREEPDB1 as sysdba
SELECT username,
       machine,
       program,
       status,
       TO_CHAR(logon_time, 'HH24:MI:SS') AS heure_connexion
FROM   v$session
WHERE  type = 'USER'
ORDER BY logon_time;
```

**Sortie type :**

```
USERNAME          MACHINE        PROGRAM          STATUS  HEURE_CONNEXION
----------------- -------------- ---------------- ------- ---------------
NANOORBIT_ADMIN   DESKTOP-XXX    sqlplus.exe      ACTIVE  03:15:42
SYS               DESKTOP-XXX    sqlplus.exe      ACTIVE  03:17:01
```

> Accepter `WHERE username IS NOT NULL` à la place de `WHERE type = 'USER'` — résultat équivalent en pratique.  
> Accepter l'absence de filtre si l'étudiant justifie qu'il veut voir toutes les sessions.

---

### D2 — Tableau de bord stockage *(1 pt)*

**Requête attendue :**

```sql
SELECT d.tablespace_name,
       ROUND(d.bytes / 1048576, 1)                          AS total_mb,
       ROUND(NVL(f.bytes, 0) / 1048576, 1)                  AS libre_mb,
       ROUND((1 - NVL(f.bytes,0) / d.bytes) * 100, 1)       AS pct_utilise
FROM (SELECT tablespace_name, SUM(bytes) bytes
      FROM   dba_data_files GROUP BY tablespace_name) d
LEFT JOIN
     (SELECT tablespace_name, SUM(bytes) bytes
      FROM   dba_free_space GROUP BY tablespace_name) f
  USING (tablespace_name)
ORDER BY pct_utilise DESC;
```

> Identique à A1 mais sans filtre sur les tablespaces NanoOrbit — l'étudiant affiche tous les tablespaces. Accepter le filtre sur les 3 tablespaces NanoOrbit s'il est justifié.

---

### D3 — Derniers archivelogs *(1 pt)*

**Requête attendue :**

```sql
SELECT name,
       TO_CHAR(completion_time, 'YYYY-MM-DD HH24:MI:SS') AS date_completion,
       ROUND(blocks * block_size / 1048576, 2)           AS taille_mb,
       status
FROM   v$archived_log
WHERE  standby_dest = 'NO'
ORDER BY completion_time DESC
FETCH FIRST 5 ROWS ONLY;
```

**Utilité pour un DBA (réponse attendue) :**

> Le rythme de génération des archivelogs reflète l'activité de la base. Un archivelog toutes les 15 minutes correspond à un RPO de 15 min garanti par la journalisation. Une absence d'archivelog depuis plus de 30 minutes peut signaler une base inactive (normal la nuit) ou un problème de journalisation. La taille des archivelogs permet d'anticiper l'espace nécessaire sur le disque.

---

### D4 — Tableau de KPI complété *(1 pt)*

**Valeurs attendues (indicatives — varient selon l'état de la base) :**

| KPI | Valeur mesurée | Seuil contrat | Statut |
|-----|---------------|--------------|--------|
| Taux d'occupation TBS_OPERATION | ~15 % (après A4) | < 85 % | ✅ OK |
| Taux d'occupation TBS_HISTORIQUE | ~9 % | < 70 % | ✅ OK |
| Nombre de sessions actives | 2-3 | < 20 | ✅ OK |
| Dernier archivelog < 30 min | Oui (si sauvegarde faite) | Oui | ✅ OK |

> L'étudiant doit remplir les valeurs réelles mesurées sur sa base. Ce qui est évalué : la capacité à lier une mesure technique à un seuil contractuel et à formuler un statut.

---

### D5 — Proposition de surveillance régulière *(1 pt)*

**Réponse attendue (paraphrase acceptée) :**

> Sur Oracle 23ai Free, sans OEM Cloud Control ni AWR, la surveillance régulière peut s'organiser ainsi :
> 1. **Script shell planifié** (cron ou Task Scheduler) exécutant les requêtes V$ toutes les 15 minutes et loguant les résultats dans un fichier ou une table d'audit.
> 2. **`DBMS_SERVER_ALERT`** pour configurer des seuils sur les tablespaces — Oracle génère automatiquement une alerte dans `DBA_OUTSTANDING_ALERTS` quand un tablespace dépasse un seuil.
> 3. **Statspack** pour capturer des snapshots de performance à intervalle régulier et détecter les dérives.

**Mots-clés valorisés** : `DBMS_SERVER_ALERT`, script planifié, `DBA_OUTSTANDING_ALERTS`, Statspack, seuil, automatisation.

> Pénaliser les réponses qui mentionnent AWR, ASH, ADDM ou OEM Cloud Control — ces outils ne sont pas disponibles sur Oracle 23ai Free (Diagnostic Pack).

---

## BARÈME DÉTAILLÉ

| Question | Points | Critère principal |
|----------|--------|-------------------|
| A1 | 1,0 | Requête DBA_DATA_FILES + DBA_FREE_SPACE, ratio calculé |
| A2 | 0,5 | DBA_SEGMENTS utilisé, tri DESC |
| A3 | 1,0 | Syntaxe ALTER TABLESPACE ADD DATAFILE complète |
| A4 | 0,5 | Sortie vérification fournie, taux < 50 % |
| A5 | 1,0 | Référence au RPO 15 min et aux insertions opérationnelles |
| **Bloc A** | **4,0** | |
| B1 | 0,5 | V$DATABASE, résultat ARCHIVELOG |
| B2 | 2,0 | BACKUP DATABASE PLUS ARCHIVELOG + CONTROLFILE + sortie |
| B3 | 1,0 | LIST BACKUP SUMMARY collé, nombre de pièces commenté |
| B4 | 1,0 | VALIDATE DATABASE + explication correcte |
| B5 | 0,5 | Raisonnement RPO immédiat vs dégradé dans le temps |
| **Bloc B** | **5,0** | |
| C1 | 0,5 | Constat chiffré de la perte (2 lignes manquantes) |
| C2 | 2,0 | ENABLE ROW MOVEMENT + FLASHBACK TABLE + explication UNDO |
| C3 | 2,0 | Séquence PITR RMAN complète et ordonnée |
| C4 | 0,5 | Vérification COUNT(*) fournie |
| C5 | 1,0 | Mesure RTO, comparaison contrat, préférence Flashback justifiée |
| **Bloc C** | **6,0** | |
| D1 | 1,0 | V$SESSION, colonnes pertinentes, filtre USER |
| D2 | 1,0 | Tableau de bord stockage tous tablespaces, tri DESC |
| D3 | 1,0 | V$ARCHIVED_LOG, 5 lignes, explication RPO |
| D4 | 1,0 | 4 KPI remplis avec valeurs réelles et statuts |
| D5 | 1,0 | Proposition réaliste sur Oracle 23ai Free (pas AWR/OEM) |
| **Bloc D** | **5,0** | |
| **TOTAL** | **20,0** | |

---

## POINTS D'ATTENTION POUR LA CORRECTION

**Erreurs fréquentes à ne pas surpénaliser :**
- Connexion en NANOORBIT_ADMIN pour les vues V$ (inaccessibles) → guider, ne pas pénaliser si l'étudiant identifie le problème et bascule en SYS
- `ALTER DATABASE DATAFILE RESIZE` en A3 au lieu de `ADD DATAFILE` → techniquement valide, accepter avec commentaire
- Flashback Table sans `ENABLE ROW MOVEMENT` → erreur ORA-08189, l'étudiant doit la corriger seul

**Erreurs à pénaliser :**
- Mention d'AWR, ASH ou OEM en D5 (outils non disponibles — montre une confusion entre éditions Oracle)
- PITR RMAN sans `RESETLOGS` (la base ne peut pas ouvrir)
- Aucune justification contractuelle dans A5 ou C5 (compétence ASRBD non démontrée)

**Indicateur de niveau avancé :**
- Étudiant qui en D5 mentionne `DBMS_SCHEDULER` pour automatiser les requêtes V$ → valoriser
- Étudiant qui en C5 calcule l'impact sur le 99,5 % de disponibilité → valoriser

---

*Corrigé instructeur — TP Validation — Module BDOE633 — Usage interne EPSI uniquement*
