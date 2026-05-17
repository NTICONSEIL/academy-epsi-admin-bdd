# Objectifs et contenu pédagogique — Module BDOE633

> Ce document reprend la structure officielle du module telle que définie dans le syllabus EPSI.
> Il sert de table des matières pédagogique et de référence pour le découpage en séances.

**Module** : BDOE633 — Administration et Optimisation des données
**Diplôme** : Bachelor SIN — Spécialisation SysOps, 3ème année
**Bloc de compétences** : BC01 — Administrer le Système d'Information (RNCP 35594)
**Volume** : 14 h

---

## 🎓 Compétences visées

| Réf. | Compétence |
|---|---|
| ASRBD1.6 | Administrer les bases de données avec méthode selon la configuration requise pour leur mise en production |
| ASRBD1.7 | Mesurer et analyser les performances pour optimiser le stockage en vue de faciliter les accès |
| ASRBD1.8 | Améliorer les performances des bases de données en optimisant l'emplacement des stockages |

### Compétences à acquérir

- Assurer la cohérence, la confidentialité, l'intégrité des données
- Garantir la disponibilité des données dans le cadre du plan de reprise d'activité de la structure, par la mise en place d'une stratégie de sauvegarde/restauration adaptée à la configuration et à la disponibilité de la base
- Auditer et monitorer le fonctionnement de la base à l'aide des outils de supervision

---

## 🗺️ Structure du module

Le module se déroule en 6 parties. Après une présentation/rappel des principaux SGBD, il aborde les points clés de l'administration d'un SGBD, illustrés à travers 2 mises en situation.

---

## Partie I — Survol

### Section 1 : Survol

**Introduction**

- Panorama des principaux SGBD les plus utilisés actuellement : MySQL, PostgreSQL, Oracle, SQL Server, DB2, MariaDB, MongoDB
- **TD** : Benchmark (fonctionnalités, périmètre d'action, prix…) à réaliser par les apprenants
- Présentation générale de l'administration des bases de données sur les SGBD PostgreSQL, DB2, MariaDB (SGBD non utilisés dans les parties suivantes de cette séquence)

---

## Partie 2 — Administration d'une base de données : garantir la disponibilité optimale des données de l'entreprise

### Section 1 : Administration d'une base de données

**1.1 — Le plan d'administration de bases de données**

- Quels indicateurs / éléments prendre en compte pour définir un plan d'administration ?
- Importance du contrat de services pour établir son plan d'administration

**1.2 — Présentation générale des outils Oracle qui simplifient l'administration des bases de données**

- Oracle Manager (SQL*DBA)
- Network Manager
- Oracle Enterprise Manager
- SQL Studio for Oracle

---

## Partie 3 — Stratégie de sauvegarde/restauration de données

### Section 1 : Stratégie de sauvegarde/restauration de données

**2.1 — La sauvegarde et la restauration**

Éléments à prendre en compte pour définir une stratégie de sauvegarde/restauration de données. Définir une procédure de sauvegarde et de restauration :

- Type de sauvegarde
- Données à sauvegarder
- Fréquence des sauvegardes
- Durée de conservation des données
- Emplacement de stockage des données

**2.2 — Le plan de reprise d'activité**

- Définition et objectifs d'un plan de reprise d'activité
- Concevoir un plan de reprise d'activité

---

## Partie 4 — Cas pratique n°1 : sauvegarde et restauration

### Section 1 : Cas pratique

À partir de l'environnement organisationnel et technique et des besoins exprimés dans le cahier des charges, à l'aide du SGBD Oracle :

1. Définir une stratégie de sauvegarde/restauration de données
2. Concevoir une procédure de sauvegarde et de restauration précisant : le type de sauvegarde, les données à sauvegarder, la fréquence des sauvegardes, la durée de conservation, l'emplacement de stockage
3. Présenter et expliquer les tests de capacité à récupérer et réutiliser les données
4. Mise en œuvre Oracle :
   - Modèles de récupération : stratégie de sauvegarde, journal de transactions
   - Sauvegarde des données : sauvegarde complète base arrêtée, sauvegarde base ouverte
   - Restauration des données : scénarios de restauration, point de récupération temporel, restauration des bases systèmes et fichiers individuels
   - Restauration complète avec ou sans archivage
   - Restauration de tablespace

---

## Partie 5 — L'audit et le monitoring des bases de données : la supervision

### Section 1 : La supervision

**3.1 — La supervision proactive**

Les indicateurs-clés de performance de bases de données :

- Disponibilité
- Utilisation des données
- Espace libre
- Temps de réponse d'une requête
- Temps d'exécution d'une requête

L'analyse en temps réel :

- Avantages
- Inconvénients
- Outils

Comment anticiper les problèmes qui peuvent survenir ?

**3.2 — La surveillance via les SGBD MySQL, Oracle et SQL Server**

Travaux dirigés afin de mettre en œuvre la surveillance à l'aide d'alertes et de notifications :

- Configuration de la messagerie
- Surveillance des erreurs
- Configuration des opérateurs, alertes et notifications

---

## Partie 6 — Cas pratique n°2 : supervision

### Section 1 : Cas pratique

À partir de l'environnement du cas pratique n°1 et à l'aide du SGBD Oracle :

1. Définir les indicateurs-clés de performance tout en respectant le contrat de services présenté dans ce cas pratique
2. Mettre en œuvre le paramétrage de la supervision à l'aide des indicateurs-clés définis à la question 1, en utilisant le SGBD Oracle
3. Expliquer le traitement des remontées d'alertes de l'outil de supervision
4. Définir le plan d'actions pour anticiper les problèmes pouvant survenir

---

## 🔗 Correspondance parties / séances

Le découpage du syllabus est mis en œuvre sur 7 séances dans ce module. Le tableau ci-dessous établit la correspondance.

| Partie du syllabus | Séance(s) | Modalité | Compétence dominante |
|---|---|---|---|
| Partie I — Survol | Séance 1 | FFP | Cadre du module |
| Partie 2 — Administration / disponibilité | Séances 2 et 3 | Classe virtuelle + FOAD | ASRBD1.6 / ASRBD1.8 |
| Partie 3 — Stratégie sauvegarde/restauration | Séance 4 | Classe virtuelle | ASRBD1.6 |
| Partie 4 — Cas pratique n°1 | Séance 5 | FOAD | ASRBD1.6 |
| Partie 5 — Supervision | Séance 6 | FOAD | ASRBD1.7 |
| Partie 6 — Cas pratique n°2 | Séance 7 | FOAD | Synthèse + évaluation formative |

---

## 📖 Bibliographie et sitographie

**Lectures recommandées**

- *Oracle 19c Administration* — Olivier Heurtel, Éditions ENI
- *TP sur Oracle 12c — Administrez une base de données* — Claire Noirault, Éditions ENI

**Plateformes conseillées**

- 360 Learning
- LinkedIn Learning
- Bibliothèque ENI

---

## ℹ️ Notes de transcription

Ce document reprend fidèlement la structure du syllabus officiel BDOE633. Quelques précisions de mise en forme :

- Le syllabus présente une numérotation interne hétérogène (« 2.1 » apparaît deux fois en Partie 3, la Partie 5 reprend la numérotation « 3.x »). Cette numérotation a été normalisée ici pour la lisibilité (Partie 3 : 2.1 puis 2.2) sans altérer le contenu.
- La Partie 4 (cas pratique n°1, sauvegarde/restauration) est détaillée à partir du cahier des charges du syllabus.
- Le contenu fait foi tel que défini dans le syllabus EPSI ; ce document n'a qu'une valeur de table des matières pédagogique.

---

*Document de cadrage — Module BDOE633 — Branche `academy`*
