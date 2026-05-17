# EPSI — Administration et Optimisation des Bases de Données

Module **BDOE633** · Bachelor SIN — Spécialisation SysOps · 3ème année · 2025-2026

Module d'administration de bases de données Oracle construit autour d'un **fil rouge progressif** : la constellation de nano-satellites **NanoOrbit**. De séance en séance, les apprenants endossent le rôle d'administrateur d'une base de production multi-sites et la font évoluer par étapes — du choix du SGBD jusqu'à l'audit complet de supervision.

---

## 🎯 Objectifs du module

À l'issue du module, l'apprenant est capable de :

- **Administrer** une base de données Oracle avec méthode selon la configuration de mise en production *(ASRBD1.6)*
- **Mesurer et analyser** les performances pour optimiser le stockage en vue de faciliter les accès *(ASRBD1.7)*
- **Améliorer** les performances des bases de données en optimisant l'emplacement des stockages *(ASRBD1.8)*

Ces trois compétences relèvent du **bloc BC01 — Administrer le Système d'Information** de la fiche RNCP 35594 (Administrateur Systèmes, Réseaux et Bases de Données).

L'évaluation est une **mise en situation professionnelle reconstituée** intégrée à la MSPR TPRE623.

## 📐 Format

| Modalité | Volume |
|---|---|
| Face-à-face présentiel (FFP) | 2 h |
| Classe virtuelle | 4 h |
| FOAD — autoformation | 8 h |
| **Total** | **14 h** |

## 🛰️ Le fil rouge NanoOrbit

NanoOrbit est une startup fictive qui exploite une constellation de CubeSats pour la surveillance climatique. Son système d'information présente l'ensemble des défis d'administration recherchés : données non rejouables, disponibilité 24/7, volumétrie hétérogène, architecture multi-sites (Paris, Singapour, Houston).

**Le fil rouge n'est pas un simple décor : c'est un scénario qui avance.** La base NanoOrbit traverse six états successifs, un par étape du module. Chaque étape produit des livrables réutilisés par la suivante. À la fin, l'apprenant a constitué un **dossier d'exploitation complet** — qui est précisément le support de l'évaluation formative.

| Étape | Séance(s) | Situation NanoOrbit | Livrable produit |
|---|---|---|---|
| 0 | S1 | NanoOrbit doit choisir son SGBD | Benchmark + recommandation |
| 1 | S2-S3 | La base Oracle est livrée à l'équipe d'admin | Plan d'administration + cartographie du stockage |
| 2 | S4 | NanoOrbit exige des garanties de continuité | Stratégie de sauvegarde/restauration + PRA |
| 3 | S5 | Incident : perte de données simulée | Mise en œuvre RMAN + tests de restauration |
| 4 | S6 | La base grossit, des lenteurs apparaissent | Dispositif de supervision + KPI |
| 5 | S7 | Audit complet demandé par la direction | Rapport d'administrateur + plan d'actions |

> 📖 Le scénario complet, avec l'état de la base en entrée et en sortie de chaque étape, est décrit dans **[`00-cadrage/fil-rouge.md`](00-cadrage/fil-rouge.md)**.

Le schéma Oracle de NanoOrbit (10 tables, triggers métier, package PL/SQL) est **fourni clé en main**. Les apprenants l'administrent, ils ne le construisent pas.

> ℹ️ Le schéma NanoOrbit est issu d'un projet de modélisation et programmation BDD du module ALTN83 (cycle ingénieur). Il est réutilisé ici en posture d'administration.

## 🗂️ Structure du dépôt

```
epsi-admin-bdd/
├── README.md                          Ce fichier
├── LICENSE
├── 00-cadrage/                        Documents de référence du module
│   ├── objectifs-et-contenu.md        Table des matières pédagogique (syllabus)
│   ├── contrat-de-services.md         Engagements NanoOrbit — référence des décisions techniques
│   ├── fil-rouge.md                   Scénario progressif en 6 étapes
│   └── competences-rncp.md            Mapping ASRBD1.6/1.7/1.8 → séances → livrables
├── 01-environnement/                  Environnement Oracle reproductible
│   └── README.md
├── 02-seances/                        Plans d'animation et supports apprenants
│   ├── seance-1-cadrage/
│   ├── seance-2-outils-oracle/
│   ├── seance-3-stockage/
│   ├── seance-4-strategie-backup/
│   ├── seance-5-cas-pratique-backup/
│   ├── seance-6-supervision/
│   └── seance-7-evaluation/
├── 03-cas-pratiques/                  Énoncés des cas pratiques fil rouge
│   ├── cp1-sauvegarde-restauration/
│   └── cp2-supervision/
├── 04-evaluation/                     Mise en situation et grille d'évaluation
└── 05-ressources/                     Bibliographie, glossaire, cheatsheets
```

## 📅 Progression sur 7 séances

| # | Modalité | Titre | Partie syllabus | Compétence |
|---|---|---|---|---|
| 1 | FFP (2 h) | Cadrage et fil rouge NanoOrbit | Partie I | Cadre |
| 2 | Classe virtuelle (2 h) | Plan d'administration et outils Oracle | Partie 2 | ASRBD1.6 |
| 3 | FOAD (2 h) | Organisation et optimisation du stockage | Partie 2 | ASRBD1.8 |
| 4 | Classe virtuelle (2 h) | Stratégie de sauvegarde et PRA | Partie 3 | ASRBD1.6 |
| 5 | FOAD (2 h) | Cas pratique n°1 — sauvegarde/restauration | Partie 4 | ASRBD1.6 |
| 6 | FOAD (2 h) | Supervision proactive et monitoring | Partie 5 | ASRBD1.7 |
| 7 | FOAD (2 h) | Cas pratique n°2 et évaluation formative | Partie 6 | Synthèse |

## 🚀 Démarrage

### Pour l'intervenant

1. Cloner le dépôt et se placer sur la branche `academy`
2. Lire **`00-cadrage/fil-rouge.md`** — c'est la clé de lecture de tout le module
3. Préparer l'environnement Oracle via `01-environnement/`
4. Animer la première séance avec `02-seances/seance-1-cadrage/`

### Pour l'apprenant

1. Cloner le dépôt
2. Lire le contrat de services et le fil rouge dans `00-cadrage/`
3. Suivre les séances dans l'ordre — chaque séance reprend l'état laissé par la précédente

## 🛠️ Environnement technique

- **SGBD** : Oracle Database 23ai Free
- **Schéma** : `NANOORBIT_ADMIN` sur `FREEPDB1`
- **Outillage** : Oracle Enterprise Manager, SQL*Plus, SQLcl, RMAN
- **Conteneurisation** : Docker (voir `01-environnement/`)

## 📚 Bibliographie

- *Oracle 19c Administration* — Olivier Heurtel, Éditions ENI
- *TP sur Oracle 12c — Administrez une base de données* — Claire Noirault, Éditions ENI
- Plateformes complémentaires : 360 Learning, LinkedIn Learning, Bibliothèque ENI

## 📝 Licence

Supports pédagogiques sous **Creative Commons BY-SA 4.0**. Scripts et code sous **MIT**. Voir [`LICENSE`](LICENSE).

## 🤝 Contribution

Module maintenu par NTIConseil dans le cadre de la prestation pédagogique EPSI. Retours et propositions via les Issues GitHub.

---

*Dernière mise à jour : mai 2026 — Branche `academy`*
