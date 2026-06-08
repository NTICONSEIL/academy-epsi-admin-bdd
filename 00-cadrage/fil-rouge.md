# Fil rouge NanoOrbit — Scénario progressif du module

> **Document maître du module BDOE633.**
> Le fil rouge NanoOrbit n'est pas un décor : c'est un scénario qui avance. La base de données traverse six états successifs, un par étape. Chaque étape reprend l'état laissé par la précédente et produit des livrables réutilisés par la suivante.

---

## 🎬 Principe

Les apprenants forment l'**équipe d'administration de la base de données NanoOrbit**. Ils ne conçoivent pas le schéma — il leur est livré. Ils l'exploitent, le sécurisent, le supervisent, sur la durée du module.

Le scénario progresse selon le cycle de vie réel d'une base de production :

```
Choix du SGBD → Prise en main → Continuité → Incident → Supervision → Audit
   Étape 0        Étape 1        Étape 2      Étape 3     Étape 4      Étape 5
```

**Règle de continuité** : les apprenants travaillent sur **une seule et même instance Oracle** tout au long du module. L'état de la base évolue ; il n'est jamais remis à zéro. Une procédure de sauvegarde de leur travail entre les séances FOAD est fournie dans `01-environnement/`.

**Le dossier d'exploitation** : chaque étape verse ses livrables dans un dossier d'exploitation NanoOrbit que l'apprenant constitue progressivement. Ce dossier est le support de l'évaluation formative en séance 7.

---

## Étape 0 — NanoOrbit choisit son SGBD

| | |
|---|---|
| **Séance** | 1 — Cadrage (FFP) |
| **Partie syllabus** | Partie I — Survol |
| **Compétence** | Cadre du module |

### Situation métier

NanoOrbit est une jeune startup. Avant de bâtir son système d'information, elle doit choisir un SGBD. L'équipe d'administration est missionnée pour réaliser un benchmark et formuler une recommandation.

### État de la base en entrée

Aucune base. NanoOrbit part d'une page blanche.

### Travail réalisé

- Panorama des principaux SGBD du marché
- Benchmark contextualisé : quel SGBD pour les besoins de NanoOrbit ?
- Lecture du contrat de services qui fixe les exigences

### Livrables versés au dossier d'exploitation

- **L0-A** — Benchmark SGBD comparatif (4 critères, 6 SGBD)
- **L0-B** — Recommandation argumentée

### État de la base en sortie

Le choix d'Oracle 23ai est acté et justifié. L'équipe connaît les exigences du contrat de services. La base peut être livrée.

---

## Étape 1 — La base Oracle est livrée à l'équipe d'administration

| | |
|---|---|
| **Séances** | 2 — Plan d'administration et outils (CV) · 3 — Stockage (FOAD) |
| **Partie syllabus** | Partie 2 — Administration / disponibilité |
| **Compétences** | ASRBD1.6, ASRBD1.8 |

### Situation métier

Le schéma NanoOrbit (10 tables, triggers, package) est livré en production. L'équipe d'administration prend possession de la base : elle doit la connaître, l'outiller et organiser son stockage.

### État de la base en entrée

Base Oracle livrée, schéma `NANOORBIT_ADMIN` peuplé, stockage par défaut (un seul tablespace, aucune optimisation).

### Travail réalisé

- Élaboration du **plan d'administration** : indicateurs à suivre, en s'appuyant sur le contrat de services
- Prise en main de l'outillage Oracle (Enterprise Manager, SQL*Plus, SQLcl)
- Cartographie du stockage existant
- **Réorganisation des tablespaces** par famille de données (référentiel / opérationnel / historique)
- Identification des colonnes candidates à l'indexation

### Livrables versés au dossier d'exploitation

- **L1-A** — Plan d'administration NanoOrbit
- **L1-B** — Cartographie du stockage (état initial + cible)
- **L1-C** — Script de réorganisation des tablespaces

### État de la base en sortie

La base est outillée, documentée, et son stockage est organisé par famille de données. L'équipe maîtrise l'environnement. La base est prête à être sécurisée.

---

## Étape 2 — NanoOrbit exige des garanties de continuité

| | |
|---|---|
| **Séance** | 4 — Stratégie de sauvegarde et PRA (CV) |
| **Partie syllabus** | Partie 3 — Stratégie de sauvegarde/restauration |
| **Compétence** | ASRBD1.6 |

### Situation métier

La direction de NanoOrbit s'inquiète : que se passe-t-il si la base tombe pendant un passage satellite ? Elle exige une stratégie de sauvegarde/restauration et un plan de reprise d'activité conformes au contrat de services.

### État de la base en entrée

Base outillée et stockage organisé (sortie étape 1). Aucune stratégie de sauvegarde formalisée.

### Travail réalisé

- Définition de la stratégie de sauvegarde/restauration : types, fréquences, rétention, emplacement
- Conception du plan de reprise d'activité (PRA)
- Choix des modèles de récupération Oracle, activation du mode archivelog

### Livrables versés au dossier d'exploitation

- **L2-A** — Stratégie de sauvegarde/restauration NanoOrbit
- **L2-B** — Plan de reprise d'activité

### État de la base en sortie

La stratégie est définie et validée sur le papier. Elle reste à mettre en œuvre techniquement.

---

## Étape 3 — Incident : perte de données simulée

| | |
|---|---|
| **Séance** | 5 — Cas pratique n°1 (FOAD) |
| **Partie syllabus** | Partie 4 — Cas pratique n°1 |
| **Compétence** | ASRBD1.6 |

### Situation métier

Un incident est simulé : perte d'un tablespace, ou insertion erronée dans `FENETRE_COM`. L'équipe doit mettre en œuvre concrètement la stratégie définie à l'étape 2 et prouver qu'elle sait restaurer.

### État de la base en entrée

Base avec stratégie définie (sortie étape 2) mais sauvegardes non encore opérationnelles.

### Travail réalisé — Cas pratique n°1

- Mise en œuvre RMAN : sauvegarde complète base arrêtée, sauvegarde base ouverte
- Scénarios de restauration : restauration complète, restauration de tablespace, point de récupération temporel
- Tests de capacité à récupérer et réutiliser les données

### Livrables versés au dossier d'exploitation

- **L3-A** — Scripts RMAN de sauvegarde
- **L3-B** — Procédures de restauration documentées
- **L3-C** — Compte rendu des tests de restauration

### État de la base en sortie

La base est sauvegardée et l'équipe a prouvé sa capacité de restauration. L'environnement de ce cas pratique sert de base au cas pratique n°2.

---

## Étape 4 — La base grossit, des lenteurs apparaissent

| | |
|---|---|
| **Séance** | 6 — Supervision proactive (FOAD) |
| **Partie syllabus** | Partie 5 — Supervision |
| **Compétence** | ASRBD1.7 |

### Situation métier

NanoOrbit grandit, la base aussi. Des lenteurs apparaissent sur certaines requêtes. La direction veut être prévenue **avant** que les incidents ne surviennent : il faut une supervision proactive.

### État de la base en entrée

Base sauvegardée et restaurable (sortie étape 3), mais sans dispositif de supervision.

### Travail réalisé

- Définition des indicateurs-clés de performance, alignés sur le contrat de services
- Mise en place de l'analyse temps réel
- Configuration de la surveillance : messagerie, surveillance des erreurs, alertes et notifications
- Réflexion sur l'anticipation des problèmes

### Livrables versés au dossier d'exploitation

- **L4-A** — Tableau des KPI supervisés et seuils d'alerte
- **L4-B** — Configuration de la supervision (scripts, alertes)

### État de la base en sortie

La base est supervisée. L'équipe est prévenue automatiquement en cas de dépassement de seuil. Tous les éléments sont réunis pour un audit complet.

---

## Étape 5 — Audit complet demandé par la direction

| | |
|---|---|
| **Séance** | 7 — Cas pratique n°2 et évaluation formative (FOAD) |
| **Partie syllabus** | Partie 6 — Cas pratique n°2 |
| **Compétence** | Synthèse ASRBD1.6/1.7/1.8 |

### Situation métier

La direction de NanoOrbit demande un audit complet de l'administration de la base : où en est-on, qu'est-ce qui doit être amélioré, comment anticiper les problèmes ?

### État de la base en entrée

Base outillée, stockage organisé, sauvegardée, supervisée — l'aboutissement des étapes 1 à 4.

### Travail réalisé — Cas pratique n°2 + évaluation formative

- Définition des indicateurs-clés en respectant le contrat de services
- Paramétrage de la supervision Oracle
- Traitement des remontées d'alertes
- Plan d'actions pour anticiper les problèmes
- **Évaluation formative** : mise en situation de synthèse

### Livrables versés au dossier d'exploitation

- **L5-A** — Rapport d'audit de la base NanoOrbit
- **L5-B** — Plan d'actions correctives et préventives
- **Dossier d'exploitation complet** — assemblage des livrables L0 à L5

### État de la base en sortie

NanoOrbit dispose d'une base administrée selon les règles de l'art : disponible, sauvegardée, supervisée, documentée. L'apprenant a constitué un dossier d'exploitation complet, support de l'évaluation formative et matière pour la MSPR TPRE623.

---

## 🧵 Vue d'ensemble — La progression en un coup d'œil

| Étape | La base NanoOrbit… | …devient | Livrables |
|---|---|---|---|
| 0 | n'existe pas | un choix de SGBD justifié | L0-A, L0-B |
| 1 | est livrée brute | outillée et stockage organisé | L1-A, L1-B, L1-C |
| 2 | n'est pas protégée | dotée d'une stratégie de continuité | L2-A, L2-B |
| 3 | a une stratégie sur le papier | effectivement sauvegardée et restaurable | L3-A, L3-B, L3-C |
| 4 | fonctionne à l'aveugle | supervisée proactivement | L4-A, L4-B |
| 5 | est administrée au quotidien | auditée et améliorée | L5-A, L5-B |

---

*Document maître — Module BDOE633 — Branche `academy`*
