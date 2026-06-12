# QCM — Notions transversales d'administration de bases de données Oracle
## Version générique — 20 questions — Corrigé instructeur

**Module** : BDOE633 · Administration et Optimisation des Bases de Données  
**Objectif** : valider les notions générales transférables à toute base Oracle de production (indépendamment du cas NanoOrbit)  
**Durée conseillée** : 30 minutes  
**Barème** : 1 point par bonne réponse  
**Total** : 20 points

> **Usage instructeur uniquement.** Les réponses correctes sont indiquées en gras et annotées.

---

## Thème 1 — Posture et cadre de l'administration (Questions 1–2)

---

### Question 1
Quelle affirmation décrit le mieux le rôle d'un administrateur de base de données par rapport à un développeur ?

- A) Il modifie le schéma et le code applicatif pour améliorer les performances
- B) Il garantit la disponibilité, l'intégrité et la récupérabilité d'une base existante, sans en modifier la structure
- C) Il conçoit le modèle de données dès la phase de spécification
- D) Il écrit les procédures stockées métier de l'application

**✅ Réponse correcte : B**

> Le changement de posture central du module : l'administrateur **hérite** d'une base en production. Son rôle est d'assurer continuité de service, sauvegarde, supervision — pas de développer ou modifier le schéma/code métier.

---

### Question 2
Un contrat de services (SLA) entre un prestataire et un client définit notamment des engagements de disponibilité, de RPO et de RTO. À quoi sert principalement ce document pour l'administrateur ?

- A) À fixer le salaire de l'équipe d'exploitation
- B) À justifier et calibrer chaque décision technique (fréquence de sauvegarde, supervision, procédures de reprise)
- C) À remplacer la documentation technique de l'application
- D) À définir les droits d'accès des utilisateurs métier

**✅ Réponse correcte : B**

> Le contrat de services est le document de référence : chaque choix technique (fréquence RMAN, seuils d'alerte, procédures PRA) découle directement d'un engagement contractuel chiffré.

---

## Thème 2 — Architecture et stockage Oracle (Questions 3–6)

---

### Question 3
Dans une architecture Oracle multitenant (12c et versions ultérieures), quelle relation décrit correctement un CDB et une PDB ?

- A) Une PDB peut contenir plusieurs CDB
- B) Le CDB est le conteneur racine ; une ou plusieurs PDB y sont rattachées et hébergent les schémas applicatifs
- C) CDB et PDB désignent la même chose, ce sont des synonymes
- D) Une PDB est un schéma, un CDB est une table

**✅ Réponse correcte : B**

> Le CDB (Container Database) constitue le conteneur racine (`CDB$ROOT`). Les PDB (Pluggable Databases) sont rattachées au CDB et hébergent les schémas applicatifs. C'est l'architecture multitenant introduite en Oracle 12c.

---

### Question 4
Pourquoi est-il recommandé de répartir les tables d'une base sur **plusieurs tablespaces** selon leur profil d'usage (référentiel stable, données opérationnelles, historique) ?

- A) Pour respecter une limite imposée par Oracle sur le nombre de tables par tablespace
- B) Pour permettre des stratégies de sauvegarde, de supervision et de croissance différenciées selon le profil de chaque famille de données
- C) Pour accélérer automatiquement toutes les requêtes SQL
- D) Parce qu'Oracle interdit de mélanger des tables liées par clé étrangère dans un même tablespace

**✅ Réponse correcte : B**

> Séparer les tablespaces par profil d'usage permet d'adapter la fréquence de sauvegarde (RPO différents), de surveiller la croissance indépendamment, et d'isoler les performances d'écriture sans affecter les données stables.

---

### Question 5
Quelle vue du dictionnaire de données permet d'obtenir la liste des tablespaces d'une base et leur statut ?

- A) `ALL_TABLES`
- B) `DBA_SEGMENTS`
- C) `DBA_TABLESPACES`
- D) `V$DATAFILE`

**✅ Réponse correcte : C**

> `DBA_TABLESPACES` est la vue de référence pour lister les tablespaces, leur statut et leurs paramètres. `V$DATAFILE` donne les fichiers physiques associés ; `DBA_SEGMENTS` liste les objets et leur occupation.

---

### Question 6
Une table alimentée en continu par un trigger, qui ne fait que croître sans jamais être purgée, nécessite particulièrement :

- A) Une indexation bitmap systématique
- B) Une surveillance dédiée de sa croissance et une politique de rétention/archivage spécifique
- C) Une suppression automatique hebdomadaire de son contenu
- D) Un passage en lecture seule dès sa création

**✅ Réponse correcte : B**

> Une table en croissance continue (type table d'historique) doit faire l'objet d'un suivi de croissance avec seuils d'alerte, et d'une politique de rétention/archivage pour éviter la saturation du tablespace qui l'héberge.

---

## Thème 3 — Stratégie de sauvegarde (Questions 7–10)

---

### Question 7
Quelle est la différence fondamentale entre **RPO** (Recovery Point Objective) et **RTO** (Recovery Time Objective) ?

- A) Le RPO mesure la durée de restauration, le RTO mesure la perte de données maximale tolérée
- B) Le RPO mesure la perte de données maximale tolérée, le RTO mesure le temps maximal de restauration accepté
- C) RPO et RTO sont deux noms différents pour la même métrique
- D) Le RPO concerne uniquement les sauvegardes complètes, le RTO uniquement les sauvegardes incrémentales

**✅ Réponse correcte : B**

> RPO = combien de données on peut perdre (mesuré en temps depuis la dernière sauvegarde/archivelog valide). RTO = combien de temps on a le droit de mettre pour restaurer le service. Ce sont deux axes complémentaires d'un PRA.

---

### Question 8
Pourquoi le mode **ARCHIVELOG** est-il indispensable pour atteindre un RPO faible (de l'ordre de quelques minutes) ?

- A) Il compresse automatiquement les sauvegardes RMAN
- B) Il conserve une copie de chaque redo log généré, permettant de rejouer les transactions jusqu'à un instant précis (PITR)
- C) Il déclenche automatiquement des sauvegardes incrémentales toutes les heures
- D) Il empêche toute écriture sur la base tant qu'une sauvegarde est en cours

**✅ Réponse correcte : B**

> Sans ARCHIVELOG, les redo logs sont écrasés cycliquement et la restauration est limitée à la dernière sauvegarde complète. Avec ARCHIVELOG, on peut restaurer à un instant T précis (Point-In-Time Recovery), réduisant fortement la perte de données possible.

---

### Question 9
Dans une stratégie de sauvegarde RMAN typique combinant sauvegarde complète hebdomadaire et sauvegarde incrémentale régulière, quel est l'objectif principal de la sauvegarde incrémentale ?

- A) Remplacer définitivement la sauvegarde complète
- B) Sauvegarder uniquement les blocs modifiés depuis la dernière sauvegarde, réduisant le temps et le volume de sauvegarde
- C) Vérifier l'intégrité du controlfile uniquement
- D) Supprimer les anciens archivelogs

**✅ Réponse correcte : B**

> La sauvegarde incrémentale ne capture que les blocs modifiés depuis la dernière sauvegarde de référence, ce qui permet des sauvegardes plus fréquentes (ex. toutes les 4 h) sans le coût d'une sauvegarde complète à chaque fois.

---

### Question 10
Une politique de rétention RMAN configurée en « fenêtre de récupération de 14 jours » (`RECOVERY WINDOW OF 14 DAYS`) signifie que :

- A) Seules 14 sauvegardes complètes maximum sont conservées, quelle que soit leur date
- B) RMAN conserve l'ensemble des sauvegardes et archivelogs nécessaires pour pouvoir restaurer la base à n'importe quel instant des 14 derniers jours
- C) La base est automatiquement arrêtée après 14 jours pour forcer une nouvelle sauvegarde complète
- D) Les sauvegardes de plus de 14 jours sont immédiatement supprimées, même si elles sont encore nécessaires à une restauration récente

**✅ Réponse correcte : B**

> La politique « recovery window » garantit la capacité de restauration sur toute la période définie. RMAN conserve donc tout ce qui est nécessaire (sauvegardes + archivelogs) pour couvrir cette fenêtre, et marque comme obsolète ce qui n'est plus nécessaire au-delà.

---

## Thème 4 — Restauration et reprise d'activité (Questions 11–15)

---

### Question 11
Avant de lancer toute opération de restauration avec RMAN, quelle bonne pratique doit systématiquement être respectée ?

- A) Redémarrer le serveur hôte
- B) Vérifier le catalogue de sauvegardes disponibles (ex. lister les sauvegardes et archivelogs) avant de choisir le point de restauration
- C) Désactiver le mode ARCHIVELOG pour accélérer la restauration
- D) Supprimer les anciennes sauvegardes pour libérer de l'espace

**✅ Réponse correcte : B**

> Il faut toujours vérifier ce qui est réellement disponible dans le catalogue (sauvegardes, archivelogs) avant de lancer une restauration, pour s'assurer que le point de restauration visé est atteignable.

---

### Question 12
Un opérateur supprime par erreur des lignes d'une table et valide (COMMIT) il y a quelques minutes, **dans la limite de la fenêtre UNDO_RETENTION**. Quelle solution est la plus rapide et la moins impactante ?

- A) Une restauration complète RMAN avec arrêt de l'instance
- B) Un Flashback Table, qui ramène la table à un état antérieur sans arrêter la base
- C) Une réinstallation complète du schéma
- D) Une restauration PITR avec `RESETLOGS`

**✅ Réponse correcte : B**

> Le Flashback Table utilise les données d'annulation (UNDO) pour ramener une table à un état antérieur, sans nécessiter d'arrêt de la base. C'est la solution la plus rapide tant que l'erreur est récente (dans `UNDO_RETENTION`).

---

### Question 13
Si l'erreur de la question précédente remonte à une période **dépassant** la fenêtre `UNDO_RETENTION`, quelle est l'alternative appropriée ?

- A) Une restauration Point-In-Time (PITR) via RMAN, avec arrêt de l'instance
- B) Attendre que l'erreur se corrige automatiquement
- C) Modifier directement les données via des `UPDATE` manuels pour deviner les valeurs perdues
- D) Réduire `UNDO_RETENTION` pour que l'erreur rentre dans la fenêtre

**✅ Réponse correcte : A**

> Au-delà de la fenêtre UNDO, le Flashback Table n'est plus possible. Il faut recourir à une restauration RMAN PITR (restauration + recovery jusqu'à un instant précis), ce qui implique un arrêt de l'instance — d'où un RTO plus long.

---

### Question 14
Après une restauration Point-In-Time (PITR), pourquoi est-il obligatoire d'ouvrir la base avec l'option `RESETLOGS` ?

- A) Pour réinitialiser les mots de passe des utilisateurs
- B) Parce que la restauration crée une nouvelle séquence de redo logs (nouvelle incarnation de la base), qui doit être réinitialisée pour garantir la cohérence
- C) Pour vider le cache mémoire (SGA) avant redémarrage
- D) `RESETLOGS` est optionnel, il sert uniquement à accélérer le redémarrage

**✅ Réponse correcte : B**

> Une restauration PITR crée une nouvelle « incarnation » de la base : la séquence des redo logs doit être réinitialisée (`RESETLOGS`) pour que les futurs redo/archivelogs soient cohérents avec ce nouveau point de départ.

---

### Question 15
En cas de crash brutal de l'instance (panne serveur, arrêt non propre), quel mécanisme Oracle effectue automatiquement la récupération au redémarrage, sans intervention de l'administrateur ?

- A) RMAN, via une restauration complète automatique
- B) Le processus SMON, qui applique l'instance recovery à partir des redo logs en ligne
- C) Le processus DBWR, qui réécrit toutes les données depuis la sauvegarde
- D) Aucun mécanisme : une intervention manuelle est toujours nécessaire

**✅ Réponse correcte : B**

> SMON (System Monitor) effectue automatiquement l'instance recovery au redémarrage en appliquant les redo logs en ligne, sans nécessiter de restauration RMAN ni d'intervention manuelle — c'est le scénario de RTO le plus court.

---

## Thème 5 — Supervision et performance (Questions 16–20)

---

### Question 16
Quelle est la différence fondamentale entre une supervision **réactive** et une supervision **proactive** ?

- A) La supervision réactive est automatisée, la proactive est manuelle
- B) La supervision réactive attend qu'un incident survienne pour alerter ; la supervision proactive surveille des indicateurs en amont pour anticiper les problèmes
- C) La supervision réactive concerne le réseau, la proactive concerne uniquement les disques
- D) Il n'y a aucune différence, ce sont deux termes équivalents

**✅ Réponse correcte : B**

> La supervision proactive repose sur des KPI surveillés en continu avec des seuils d'alerte définis à l'avance, permettant d'agir **avant** l'incident — contrairement à une supervision réactive qui constate l'incident après qu'il s'est produit.

---

### Question 17
Parmi les indicateurs suivants, lequel est typiquement surveillé dans une démarche de supervision proactive d'une base de données ?

- A) Le nombre de lignes de code du schéma
- B) Le taux d'occupation des tablespaces, avec des seuils d'alerte et critique
- C) Le nombre de développeurs ayant accès au code source
- D) La date de création de la base

**✅ Réponse correcte : B**

> Le taux d'occupation des tablespaces (avec seuils d'alerte ~80 % et critique ~90 % typiquement) est un indicateur classique de supervision proactive, car il permet d'anticiper une saturation avant qu'elle ne bloque les écritures.

---

### Question 18
Quelle vue dynamique Oracle permet de connaître en temps réel les sessions actives sur l'instance ?

- A) `DBA_USERS`
- B) `V$SESSION`
- C) `DBA_AUDIT_TRAIL`
- D) `V$ARCHIVED_LOG`

**✅ Réponse correcte : B**

> `V$SESSION` donne, en temps réel, le statut (ACTIVE/INACTIVE), l'utilisateur, la machine et le programme de chaque session connectée — c'est la vue de référence pour surveiller la charge de connexions.

---

### Question 19
Les outils AWR, ASH et ADDM (Diagnostic Pack) ne sont **pas disponibles** dans certaines éditions d'Oracle (notamment l'édition Free / Standard sans option). Quelles alternatives reste-t-il pour superviser la base dans ce cas ?

- A) Aucune : sans Diagnostic Pack, la supervision est impossible
- B) Les vues dynamiques `V$`, `DBMS_SERVER_ALERT` et Statspack
- C) Uniquement l'analyse manuelle des fichiers de logs systèmes
- D) Il faut obligatoirement migrer vers une autre base de données

**✅ Réponse correcte : B**

> Sans le Diagnostic Pack (option payante incluant AWR/ASH/ADDM), il reste possible de superviser efficacement une base via les vues dynamiques `V$`, le package `DBMS_SERVER_ALERT` pour les seuils d'alerte, et Statspack pour l'historique de performance — tous disponibles gratuitement.

---

### Question 20
Un administrateur constate qu'une requête critique est de plus en plus lente au fil du temps, alors que le volume de données augmente. Quelle démarche générale est la plus pertinente pour diagnostiquer et corriger le problème ?

- A) Augmenter systématiquement la mémoire allouée à l'instance sans analyse préalable
- B) Analyser le plan d'exécution de la requête (EXPLAIN PLAN) et envisager la création d'un index adapté aux colonnes de filtre/jointure
- C) Réécrire l'application dans un autre langage de programmation
- D) Supprimer les données les plus anciennes de la table concernée

**✅ Réponse correcte : B**

> La démarche d'optimisation standard consiste à analyser le plan d'exécution pour identifier les opérations coûteuses (full table scan, etc.), puis à envisager des index sur les colonnes de jointure ou de filtre fréquemment utilisées — une approche ciblée et mesurable.

---

## Tableau de synthèse — Corrigé

| Q | Thème | Bonne réponse | Notion transversale visée |
|---|-------|---------------|---------------------------|
| 1 | Posture | B | Rôle de l'administrateur vs développeur |
| 2 | Contrat de services | B | SLA comme référentiel de décision |
| 3 | Architecture Oracle | B | Modèle CDB/PDB (multitenant) |
| 4 | Organisation du stockage | B | Tablespaces différenciés par profil d'usage |
| 5 | Dictionnaire de données | C | Vues `DBA_*` |
| 6 | Tables d'historique | B | Surveillance de croissance / rétention |
| 7 | RPO vs RTO | B | Définitions fondamentales du PRA |
| 8 | Mode ARCHIVELOG | B | Lien ARCHIVELOG ↔ RPO / PITR |
| 9 | Sauvegarde incrémentale | B | Optimisation des sauvegardes RMAN |
| 10 | Politique de rétention | B | Fenêtre de récupération RMAN |
| 11 | Bonnes pratiques RMAN | B | Vérification avant restauration |
| 12 | Flashback Table | B | Restauration rapide via UNDO |
| 13 | PITR | A | Restauration au-delà de UNDO_RETENTION |
| 14 | RESETLOGS | B | Nouvelle incarnation après PITR |
| 15 | Instance Recovery | B | Rôle de SMON |
| 16 | Supervision proactive | B | Définition de la supervision proactive |
| 17 | KPI de supervision | B | Indicateurs de supervision proactive |
| 18 | Vues V$ | B | `V$SESSION` |
| 19 | Limites éditions Oracle | B | Alternatives sans Diagnostic Pack |
| 20 | Optimisation | B | Démarche EXPLAIN PLAN / indexation |

---

## Grille de notation suggérée

| Score | Appréciation |
|-------|-------------|
| 18–20 | Excellent — notions transversales maîtrisées |
| 15–17 | Très bien — quelques lacunes mineures |
| 12–14 | Bien — bases solides, points à retravailler |
| 10–11 | Passable — révision recommandée |
| < 10 | Insuffisant — revoir les fondamentaux sauvegarde/restauration/supervision |

---

*Corrigé instructeur — Version générique — BDOE633 — NTIConseil / EPSI — 2025-2026*
