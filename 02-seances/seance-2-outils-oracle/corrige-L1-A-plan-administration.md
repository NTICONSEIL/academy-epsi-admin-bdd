# Corrigé — Plan d'administration de la base NanoOrbit

> **Livrable L1-A — Corrigé instructeur.**
> Document à usage interne EPSI. Ne pas distribuer aux apprenants avant évaluation.

---

## 1. Identification

| Rubrique | Valeur |
|---|---|
| Base administrée | NanoOrbit — schéma `NANOORBIT_ADMIN` sur `FREEPDB1` |
| SGBD | Oracle Database 23ai |
| Binôme | *(noms des apprenants)* |
| Date de rédaction | *(date de remise)* |
| Version du document | v1 |

---

## 2. Périmètre et classification des données

| Famille | Tables concernées | Caractéristique métier |
|---|---|---|
| **Référentiel** | `ORBITE`, `INSTRUMENT`, `CENTRE_CONTROLE`, `STATION_SOL`, `MISSION` | Données stables, peu modifiées, structurantes pour toutes les opérations. Une mise à jour erronée peut affecter l'ensemble des traitements. |
| **Opérationnel** | `SATELLITE`, `EMBARQUEMENT`, `AFFECTATION_STATION`, `PARTICIPATION`, `FENETRE_COM` | Données vivantes avec écritures fréquentes (notamment `FENETRE_COM` à chaque passage satellite). Critiques pour la continuité de service. |
| **Historique** | `HISTORIQUE_STATUT` | Croissance continue et monotone (seules des insertions, jamais de suppressions). Lecture rare mais conservation longue durée. |

> **Remarque correcteur** : les apprenants doivent avoir associé les tables correctement aux trois familles. Accepter une formulation différente si le raisonnement est cohérent. Pénaliser si `FENETRE_COM` est classée en Référentiel.

---

## 3. Engagements de service à garantir

| Engagement | Référentiel | Opérationnel | Historique |
|---|---|---|---|
| **Disponibilité cible** | 99,9 % — heures ouvrées Paris (08:00–20:00 UTC+1) | **99,5 %** — H24, passages satellites en continu | 99,0 % — H24 mais non bloquant |
| **Indisponibilité tolérée** | ≈ 8 h / an | ≈ 44 h / an (≈ **50 min / semaine**) | ≈ 88 h / an |
| **RPO (perte maximale)** | 24 h | **15 minutes** | 24 h |
| **RTO (temps de reprise)** | 1 heure | **30 minutes** | 4 heures |

> **Point clé à valoriser** : l'apprenant doit avoir compris que les engagements les plus contraignants (RPO 15 min, RTO 30 min) ne s'appliquent qu'à la famille Opérationnel — et en avoir tiré les conséquences techniques (mode archivelog obligatoire).

---

## 4. Éléments à surveiller

| Élément | Ce qui est surveillé | Engagement justificatif |
|---|---|---|
| **Disponibilité de l'instance** | Statut de l'instance Oracle (UP/DOWN), temps de réponse du listener, sessions actives | Disponibilité 99,5 % sur l'Opérationnel — une indisponibilité > 50 min/semaine est hors contrat |
| **Volumétrie et croissance** | Nombre de lignes dans `FENETRE_COM` et `HISTORIQUE_STATUT`, rythme d'insertion hebdomadaire | `HISTORIQUE_STATUT` croît sans jamais être purgée — anticiper la saturation pour garantir le RTO |
| **Espace de stockage** | Taux d'occupation des tablespaces (`DBA_DATA_FILES`, `DBA_FREE_SPACE`), espace libre sur le volume Oracle | Un tablespace plein provoque des erreurs d'écriture et compromet immédiatement le RPO Opérationnel |
| **Performances des requêtes** | Latence des INSERT sur `FENETRE_COM`, temps d'exécution de `pkg_nanoOrbit`, requêtes longues (> 1 s) | Le RTO de 30 min suppose des procédures de restauration rapides — des requêtes lentes dégradent aussi le temps de reprise |
| **Sauvegardes** | Statut des jobs RMAN (succès/échec), ancienneté de la dernière sauvegarde complète, présence des archive logs | RPO 15 min sur l'Opérationnel — un archive log manquant peut rendre impossible une restauration PITR |

---

## 5. Fenêtres de maintenance

| Famille | Indisponibilité tolérée | Fenêtre de maintenance proposée | Justification |
|---|---|---|---|
| **Référentiel** | ≈ 8 h / an | Samedi 22:00 – dimanche 04:00 UTC+1 (hors heures ouvrées Paris), maximum 2 fois par an | Les données référentiel ne sont accédées qu'en heures ouvrées depuis Paris. Une maintenance nocturne de week-end n'affecte ni les opérations ni les passages satellites. |
| **Opérationnel** | ≈ 50 min / semaine | Créneau de 30 min maximum, planifié entre deux passages satellites (ex. 03:00–03:30 UTC), une fois par semaine | Les satellites passent toutes les 90 min. Une fenêtre de 30 min glissée entre deux passages garantit qu'aucune fenêtre de communication n'est sacrifiée. Durée ≤ RTO de 30 min. |
| **Historique** | ≈ 88 h / an | Dimanche 01:00 – 05:00 UTC (nuit de week-end, 4 h maximum) | `HISTORIQUE_STATUT` n'est pas bloquante pour les opérations. Une indisponibilité nocturne de 4 h est sans impact métier et tient dans l'enveloppe annuelle. |

> **Point clé à valoriser** : la fenêtre Opérationnel doit impérativement être ≤ 30 min (RTO) ET tenir compte du cycle orbital de 90 min. Pénaliser toute proposition qui dépasse 30 min ou qui ignore la contrainte des passages satellites.

---

## 6. Indicateurs candidats (premiers KPI)

| Indicateur | Ce qu'il mesure | Seuil d'alerte envisagé |
|---|---|---|
| **Disponibilité instance Oracle** | L'instance est-elle accessible et répond-elle aux connexions ? | Alerte si indisponibilité > 5 min consécutives |
| **Taux d'occupation des tablespaces** | Pourcentage d'espace utilisé par tablespace | Alerte à 80 %, critique à 90 % |
| **Ancienneté de la dernière sauvegarde RMAN réussie** | Délai depuis la dernière sauvegarde complète valide | Alerte si > 7 jours sans sauvegarde complète |
| **Latence INSERT sur `FENETRE_COM`** | Temps moyen d'insertion d'une fenêtre de communication | Alerte si > 200 ms en moyenne sur 5 min |
| **Nombre d'échecs de job RMAN** | Jobs de sauvegarde en erreur | Alerte au 1er échec, critique au 2e consécutif |
| **Croissance hebdomadaire de `HISTORIQUE_STATUT`** | Rythme d'insertion dans la table historique | Alerte si croissance > 10 %/semaine |

> **Remarque correcteur** : 4 indicateurs minimum attendus. Valoriser les apprenants qui ont relié chaque KPI à un engagement précis du contrat. Les seuils exacts ne sont pas évalués à ce stade (séance 6 les précisera).

---

## 7. Outils d'administration retenus

| Outil | Usage prévu dans le module |
|---|---|
| **SQL\*Plus / SQLcl** | Exécution des scripts d'exploration, interrogation du dictionnaire de données (`USER_TABLES`, `DBA_DATA_FILES`, `V$SESSION`…), validation des livrables SQL |
| **Oracle Enterprise Manager Express** (port 5500) | Supervision graphique : sessions actives, occupation tablespaces, performances instance. Accessible à l'URL `https://localhost:5500/em` |
| **RMAN** | Sauvegardes et restaurations (séances 4–5) : sauvegarde complète, incrémentale, archive logs, PITR |

> **Remarque correcteur** : accepter SQL Developer comme outil alternatif à SQL\*Plus. Pénaliser l'absence de RMAN ou d'EM Express car ils sont explicitement dans le périmètre du module.

---

## 8. Première cartographie de la base

*À compléter après exécution de `exploration-dictionnaire.sql` sur l'environnement Oracle.*

| Constat | Observation attendue |
|---|---|
| Nombre de tables | 11 tables (`USER_TABLES`) — 10 tables métier + `HISTORIQUE_STATUT` |
| Volumétrie totale approximative | Très faible (jeu de référence 43 lignes) — quelques Ko par table dans `USER_SEGMENTS` |
| Table la plus volumineuse | `EMBARQUEMENT` et `PARTICIPATION` (7 lignes chacune) |
| Organisation actuelle du stockage | Toutes les tables dans le tablespace par défaut `USERS` — pas encore de ségrégation par famille |
| Index existants | Index sur les clés primaires uniquement (générés automatiquement par Oracle sur les contraintes PK) |

> **Point clé** : le constat "toutes les tables dans USERS" est la justification pédagogique de la séance 3 (réorganisation des tablespaces). L'apprenant doit l'avoir formulé comme un point d'attention.

---

## 9. Points d'attention identifiés

- **Absence de ségrégation du stockage** : toutes les tables cohabitent dans le tablespace `USERS`. Impossible de sauvegarder ou restaurer une famille de données indépendamment. → Correction prévue en séance 3.
- **Mode NOARCHIVELOG probable** : sans activation explicite du mode archivelog, le RPO de 15 min sur l'Opérationnel ne peut pas être respecté. → Correction prévue en séance 5.
- **Aucun index sur les colonnes de recherche** : colonnes `statut` (SATELLITE), `code_station` (FENETRE_COM), `id_mission` (PARTICIPATION) non indexées. Les requêtes opérationnelles feront des full-scans en production. → À planifier.
- **`HISTORIQUE_STATUT` sans stratégie de purge** : la table grossit indéfiniment. Sans politique de rétention, elle saturera le tablespace à terme.

> **Remarque correcteur** : 3 points minimum attendus. Le premier (stockage non segmenté) est incontournable — c'est la transition vers la séance 3. Valoriser les apprenants qui ont identifié le mode NOARCHIVELOG sans qu'on le leur ait dit explicitement.

---

*Corrigé L1-A — Séance 2 — Module BDOE633 — Usage instructeur uniquement*
