# QCM — BDOE633 · Administration et Optimisation des Bases de Données
## Validation du module — 20 questions — Corrigé instructeur

**Module** : BDOE633 · Bachelor SIN SysOps · Bac+3  
**Durée conseillée** : 30 minutes  
**Barème** : 1 point par bonne réponse — 0 point pour une mauvaise réponse — pas de point négatif  
**Total** : 20 points

> **Usage instructeur uniquement.** Les réponses correctes sont indiquées en gras et annotées.

---

## Thème 1 — Contrat de services & posture administrateur (Questions 1–3)

---

### Question 1
Le contrat de services NanoOrbit impose une disponibilité de 99,5 %. En pratique, cela correspond à une indisponibilité maximale tolérée d'environ :

- A) 50 minutes par semaine
- B) 4 heures par mois
- C) 1 heure par jour
- D) 15 minutes par heure

**✅ Réponse correcte : A**

> 0,5 % × 168 h/semaine ≈ 0,84 h ≈ **50 minutes**. C'est la valeur explicitement citée dans les slides de cadrage. Les autres propositions sont soit trop restrictives (D), soit trop permissives (B, C).

---

### Question 2
Dans le module BDOE633, quelle est la « règle d'or » posée dès la séance 1 ?

- A) Toujours tester la restauration avant de valider une sauvegarde
- B) Ne jamais modifier le schéma ni le code PL/SQL — administrer uniquement
- C) Documenter chaque opération dans le journal d'exploitation
- D) Privilegier la performance sur la disponibilité

**✅ Réponse correcte : B**

> La règle d'or énoncée en séance 1 : *« Pendant ce module, vous ne toucherez plus jamais au schéma ni au code PL/SQL. »* La posture est celle d'un administrateur qui hérite d'une base en production, pas d'un développeur.

---

### Question 3
Le RPO (Recovery Point Objective) défini dans le contrat NanoOrbit pour les données opérationnelles est de :

- A) 30 minutes
- B) 4 heures
- C) 15 minutes
- D) 1 heure

**✅ Réponse correcte : C**

> RPO = perte de données maximale tolérée. Le contrat NanoOrbit fixe **RPO = 15 min** pour les tables opérationnelles (`FENETRE_COM`, `SATELLITE`…). Le RTO est lui fixé à 30 min (confusion classique à surveiller).

---

## Thème 2 — Architecture Oracle & dictionnaire de données (Questions 4–6)

---

### Question 4
Dans l'architecture Oracle de NanoOrbit, quel est le nom de la Pluggable Database (PDB) hébergeant le schéma `NANOORBIT_ADMIN` ?

- A) `FREE`
- B) `FREEPDB1`
- C) `NANOORBIT`
- D) `CDB$ROOT`

**✅ Réponse correcte : B**

> Le schéma `NANOORBIT_ADMIN` est créé dans la PDB **`FREEPDB1`**. `FREE` est le nom du CDB (Container Database). `CDB$ROOT` est le conteneur racine. Cette distinction CDB/PDB est fondamentale en Oracle 12c+.

---

### Question 5
Pour connaître la liste des tablespaces d'une base Oracle et leur statut, quelle vue du dictionnaire de données utilise-t-on ?

- A) `DBA_SEGMENTS`
- B) `V$DATAFILE`
- C) `DBA_TABLESPACES`
- D) `ALL_TABLES`

**✅ Réponse correcte : C**

> `DBA_TABLESPACES` fournit le nom, le statut et les paramètres de chaque tablespace. `V$DATAFILE` liste les fichiers physiques. `DBA_SEGMENTS` liste les objets et leur occupation. `ALL_TABLES` ne concerne que les tables accessibles par l'utilisateur.

---

### Question 6
Le schéma NanoOrbit comporte 3 tablespaces métier distincts. Quelle table a été créée **directement dans `TBS_HISTORIQUE`** lors de la séance 3, et non dans la configuration initiale ?

- A) `FENETRE_COM`
- B) `SATELLITE`
- C) `HISTORIQUE_STATUT`
- D) `PARTICIPATION`

**✅ Réponse correcte : C**

> `HISTORIQUE_STATUT` n'était pas dans le schéma initial livré. Elle a été créée lors de l'exercice de réorganisation de séance 3, directement dans `TBS_HISTORIQUE` — ce qui illustre le principe de créer un objet dans le bon tablespace dès sa naissance.

---

## Thème 3 — Organisation du stockage (Questions 7–8)

---

### Question 7
Pourquoi isole-t-on `FENETRE_COM` dans le tablespace `TBS_OPERATION` plutôt que dans `TBS_REFERENTIEL` ?

- A) Car `FENETRE_COM` est une table de référence rarement modifiée
- B) Car `FENETRE_COM` reçoit des insertions intensives (toutes les ~90 min par satellite) et requiert une stratégie de sauvegarde renforcée
- C) Car la taille de `FENETRE_COM` est prévisible et quasi-stable
- D) Car `TBS_REFERENTIEL` ne peut contenir que des tables sans clé étrangère

**✅ Réponse correcte : B**

> `FENETRE_COM` est alimentée à chaque passage satellite (~90 min d'intervalle orbital). Son profil d'écriture intense justifie un tablespace dédié avec sauvegarde incrémentale toutes les 4 h pour respecter le RPO 15 min. `TBS_REFERENTIEL` est réservé aux données stables (orbites, stations, centres).

---

### Question 8
Quel est l'objectif principal de surveiller la croissance de `HISTORIQUE_STATUT` indépendamment des autres tables ?

- A) Détecter des insertions frauduleuses de statuts satellites
- B) Éviter qu'une saturation de l'historique bloque les écritures opérationnelles sur d'autres tablespaces
- C) Calculer le taux de disponibilité mensuel
- D) Optimiser les requêtes du package `pkg_nanoOrbit`

**✅ Réponse correcte : B**

> `HISTORIQUE_STATUT` ne fait que croître (trigger T5, aucune suppression). Si elle sature son tablespace, Oracle ne peut plus écrire — et comme elle partage `TBS_HISTORIQUE`, l'isoler permet d'alerter à +10 %/semaine sans que cela impacte `TBS_OPERATION`.

---

## Thème 4 — Mode ARCHIVELOG & sauvegarde RMAN (Questions 9–12)

---

### Question 9
Pourquoi le mode ARCHIVELOG est-il **obligatoire** pour respecter le RPO de 15 minutes ?

- A) Il compresse les sauvegardes pour accélérer leur transfert
- B) Il permet d'appliquer les redo logs archivés et ainsi restaurer la base à n'importe quel instant passé
- C) Il active automatiquement les sauvegardes incrémentales toutes les 4 heures
- D) Il réduit la taille des fichiers de données en archivant les blocs froids

**✅ Réponse correcte : B**

> Sans ARCHIVELOG, Oracle écrase les redo logs circulairement — toute restauration est limitée à la dernière sauvegarde complète. Avec ARCHIVELOG, on peut rejouer les transactions jusqu'à un instant précis (PITR), ce qui permet de ne perdre au maximum que 15 min de données.

---

### Question 10
Quelle commande RMAN réalise une sauvegarde complète de la base **en incluant les archivelogs** avant et après la sauvegarde ?

- A) `BACKUP DATABASE ARCHIVELOG ALL;`
- B) `BACKUP FULL DATABASE WITH ARCHIVELOGS;`
- C) `BACKUP DATABASE PLUS ARCHIVELOG;`
- D) `BACKUP DATABASE INCLUDING ARCHIVELOGS;`

**✅ Réponse correcte : C**

> La syntaxe exacte est `BACKUP DATABASE PLUS ARCHIVELOG;`. Le mot-clé `PLUS` est spécifique à RMAN et inclut les archivelogs disponibles avant et après la sauvegarde, garantissant la cohérence du point de récupération.

---

### Question 11
La politique de rétention RMAN configurée pour NanoOrbit est :

- A) 7 jours (fenêtre de récupération)
- B) 14 jours (fenêtre de récupération)
- C) 30 jours (nombre de copies)
- D) 4 sauvegardes complètes conservées

**✅ Réponse correcte : B**

> La commande utilisée en séance 5 est `CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;`. Cela signifie qu'Oracle conserve toutes les sauvegardes nécessaires pour restaurer la base à n'importe quel instant dans les 14 derniers jours.

---

### Question 12
Avant toute restauration RMAN, quelle commande doit impérativement être exécutée pour vérifier l'état du catalogue ?

- A) `VALIDATE DATABASE;`
- B) `CHECK BACKUP;`
- C) `LIST BACKUP SUMMARY;`
- D) `CROSSCHECK DATABASE;`

**✅ Réponse correcte : C**

> La règle du module : *« Toujours LIST avant toute restauration. »* `LIST BACKUP SUMMARY;` affiche les sauvegardes disponibles et leurs dates. Cela évite de tenter une restauration vers un point qui n'existe pas dans le catalogue.

---

## Thème 5 — Plan de Reprise d'Activité & restauration (Questions 13–16)

---

### Question 13
Un opérateur exécute accidentellement `DELETE FROM FENETRE_COM; COMMIT;`. La suppression remonte à 22 minutes. Quel mécanisme de restauration est le plus adapté ?

- A) Flashback Table (si dans la fenêtre UNDO_RETENTION)
- B) RMAN PITR avec `RECOVER DATABASE UNTIL TIME`
- C) Réimportation depuis une sauvegarde logique (expdp/impdp)
- D) Reconstruction manuelle depuis `HISTORIQUE_STATUT`

**✅ Réponse correcte : B**

> 22 minutes dépasse généralement `UNDO_RETENTION` (défaut 900 s = 15 min). Flashback Table n'est plus possible. Il faut donc un PITR RMAN : shutdown, startup mount, `RECOVER DATABASE UNTIL TIME`, puis `ALTER DATABASE OPEN RESETLOGS`. Le RTO estimé est ~25 min — dans la limite contractuelle de 30 min.

---

### Question 14
Après une restauration PITR (Point-In-Time Recovery) avec RMAN, quelle commande est **obligatoire** pour rouvrir la base ?

- A) `ALTER DATABASE OPEN;`
- B) `ALTER DATABASE OPEN READ WRITE;`
- C) `ALTER DATABASE OPEN RESETLOGS;`
- D) `STARTUP OPEN;`

**✅ Réponse correcte : C**

> `RESETLOGS` est obligatoire après un PITR car il réinitialise la séquence des redo logs. Utiliser `OPEN` sans `RESETLOGS` provoque une erreur Oracle. Cette commande crée un nouveau « incarnation » de la base dans le catalogue RMAN.

---

### Question 15
En cas de crash d'instance (SHUTDOWN ABORT ou panne OS), quel mécanisme Oracle assure automatiquement la récupération au redémarrage ?

- A) RMAN (Recovery Manager)
- B) LGWR (Log Writer)
- C) SMON (System Monitor)
- D) DBWR (Database Writer)

**✅ Réponse correcte : C**

> **SMON** (System Monitor) exécute l'Instance Recovery automatiquement au démarrage suivant un crash : il applique les redo logs non encore écrits dans les datafiles. Le RTO pour ce scénario est ~5 min — bien en deçà des 30 min contractuels.

---

### Question 16
La séquence correcte pour activer le mode ARCHIVELOG sur Oracle est :

- A) `STARTUP` → `ALTER DATABASE ARCHIVELOG` → `SHUTDOWN`
- B) `SHUTDOWN IMMEDIATE` → `STARTUP MOUNT` → `ALTER DATABASE ARCHIVELOG` → `ALTER DATABASE OPEN`
- C) `ALTER SYSTEM SET LOG_MODE=ARCHIVELOG` → `RESTART`
- D) `ALTER DATABASE OPEN` → `ALTER DATABASE ARCHIVELOG` → `SHUTDOWN IMMEDIATE`

**✅ Réponse correcte : B**

> La base doit être en mode **MOUNT** (fermée aux utilisateurs mais controlfile ouvert) pour que `ALTER DATABASE ARCHIVELOG` soit accepté. La séquence complète : `SHUTDOWN IMMEDIATE` → `STARTUP MOUNT` → `ALTER DATABASE ARCHIVELOG` → `ALTER DATABASE OPEN`. Cette opération est réalisée une seule fois, en tant que SYSDBA.

---

## Thème 6 — Supervision proactive (Questions 17–20)

---

### Question 17
Dans le contexte d'Oracle 23ai Free (édition utilisée pour NanoOrbit), quel outil de supervision **n'est PAS disponible** ?

- A) Vues dynamiques `V$` (ex. `V$SESSION`, `V$TABLESPACE`)
- B) `DBMS_SERVER_ALERT`
- C) AWR (Automatic Workload Repository)
- D) Statspack

**✅ Réponse correcte : C**

> AWR/ASH/ADDM font partie du **Diagnostic Pack** Oracle, une option payante non incluse dans l'édition Free. Les vues `V$`, `DBMS_SERVER_ALERT` et Statspack sont disponibles gratuitement et constituent les outils de supervision utilisés en séance 6.

---

### Question 18
Dans le contrat NanoOrbit, à partir de quel seuil d'occupation d'un tablespace une alerte doit-elle se déclencher ?

- A) 70 %
- B) 75 %
- C) 80 %
- D) 90 %

**✅ Réponse correcte : C**

> Le contrat stipule : alerte à **80 %** d'occupation, seuil critique à **90 %**. En dessous de 80 %, aucune alerte n'est requise. Ce seuil s'applique à tous les tablespaces (famille `TBS_OPERATION`, `TBS_REFERENTIEL`, `TBS_HISTORIQUE`).

---

### Question 19
Quelle vue Oracle permet de connaître en temps réel le nombre de sessions actives sur la base ?

- A) `DBA_USERS`
- B) `V$SESSION`
- C) `DBA_AUDIT_TRAIL`
- D) `V$ARCHIVED_LOG`

**✅ Réponse correcte : B**

> `V$SESSION` est la vue dynamique de référence pour les sessions Oracle actives. Elle donne le statut (ACTIVE/INACTIVE), l'utilisateur, la machine, le programme et le SID. Le contrat NanoOrbit fixe une alerte à >50 sessions actives et un seuil critique à >80.

---

### Question 20
Quelle est la différence fondamentale entre la supervision **réactive** et la supervision **proactive** d'une base de données ?

- A) La supervision réactive utilise des scripts shell, la supervision proactive utilise des outils graphiques
- B) La supervision réactive attend qu'un incident se produise pour alerter ; la supervision proactive surveille des indicateurs en amont pour anticiper les problèmes
- C) La supervision réactive est manuelle, la supervision proactive est automatisée par cron
- D) La supervision réactive surveille les erreurs applicatives, la supervision proactive surveille uniquement les tablespaces

**✅ Réponse correcte : B**

> C'est la distinction centrale de la séance 6 et du titre de la compétence ASRBD. La supervision proactive repose sur des **KPI** (occupation tablespace, latence d'écriture, sessions actives…) avec des **seuils d'alerte configurés à l'avance**, permettant d'intervenir *avant* l'incident. L'objectif est de ne pas *subir* les incidents, mais de les *anticiper*.

---

## Tableau de synthèse — Corrigé

| Q | Thème | Bonne réponse | Compétence visée |
|---|-------|---------------|-----------------|
| 1 | Contrat de services | A | Lecture et interprétation du SLA |
| 2 | Posture administrateur | B | Posture DBA vs développeur |
| 3 | RPO/RTO | C | Définir les objectifs de reprise |
| 4 | Architecture Oracle CDB/PDB | B | Identifier l'environnement Oracle |
| 5 | Dictionnaire de données | C | Exploiter les vues DBA_ |
| 6 | Tablespaces NanoOrbit | C | Connaître le schéma NanoOrbit |
| 7 | Organisation du stockage | B | Justifier la répartition tablespaces |
| 8 | Supervision tablespace historique | B | Anticiper la saturation |
| 9 | Mode ARCHIVELOG | B | Comprendre ARCHIVELOG et RPO |
| 10 | Commande RMAN sauvegarde | C | Maîtriser les commandes RMAN |
| 11 | Politique de rétention RMAN | B | Configurer la rétention RMAN |
| 12 | Vérification catalogue RMAN | C | Protocole avant restauration |
| 13 | Choix mécanisme de restauration | B | Arbre de décision Flashback vs PITR |
| 14 | Commande post-PITR | C | RESETLOGS après PITR |
| 15 | Instance Recovery automatique | C | Rôle de SMON |
| 16 | Activation ARCHIVELOG | B | Séquence d'activation ARCHIVELOG |
| 17 | Outils supervision Oracle Free | C | Limites Oracle Free vs payant |
| 18 | Seuil alerte tablespace | C | Lire et appliquer le contrat |
| 19 | Vue sessions actives | B | Exploiter les vues V$ |
| 20 | Supervision proactive vs réactive | B | Posture supervision proactive |

---

## Grille de notation suggérée

| Score | Appréciation |
|-------|-------------|
| 18–20 | Excellent — maîtrise complète du module |
| 15–17 | Très bien — quelques lacunes mineures |
| 12–14 | Bien — bases solides, points à retravailler |
| 10–11 | Passable — révision recommandée sur les thèmes <12 |
| < 10 | Insuffisant — revoir les séances 4, 5 et 6 en priorité |

---

*Corrigé instructeur — BDOE633 — NTIConseil / EPSI — 2025-2026*
