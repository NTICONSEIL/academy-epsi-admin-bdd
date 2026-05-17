# Séance 2 — Plan d'administration et outils Oracle

**Format** : Classe virtuelle · **Durée** : 2 h · **Partie syllabus** : Partie 2 — Administration / disponibilité

---

## 🧵 Étape du fil rouge

> **Étape 1 (1/2) — La base Oracle est livrée à l'équipe d'administration.**
> Le schéma NanoOrbit est en production. L'équipe prend possession de la base : elle doit la connaître, l'outiller, et poser son plan d'administration.

| | |
|---|---|
| État de la base **en entrée** | Base Oracle livrée, schéma `NANOORBIT_ADMIN` peuplé, stockage par défaut |
| État de la base **en sortie** | Base outillée et documentée, plan d'administration posé |
| Livrable produit | L1-A (plan d'administration) |

---

## 🎯 Objectifs pédagogiques

À l'issue de la séance, l'apprenant est capable de :

- **Définir** un plan d'administration de base de données et identifier les indicateurs/éléments à y intégrer
- **Expliquer** le rôle du contrat de services dans l'établissement du plan d'administration
- **Prendre en main** les principaux outils Oracle d'administration
- **Explorer** la base NanoOrbit avec les outils appropriés

## ⏱️ Découpage temporel

| Temps | Bloc | Modalité | Durée |
|---|---|---|---|
| 0:00 → 0:20 | Restitution des benchmarks SGBD (livrable L0) | Présentations binômes | 20 min |
| 0:20 → 0:45 | Le plan d'administration de bases de données | Exposé | 25 min |
| 0:45 → 1:20 | Les outils Oracle d'administration | Exposé + démo | 35 min |
| 1:20 → 1:50 | Atelier : ébauche du plan d'administration NanoOrbit | Atelier guidé | 30 min |
| 1:50 → 2:00 | Synthèse et briefing FOAD séance 3 | Exposé | 10 min |

---

## 📋 Détail des blocs

### Bloc 1 — Restitution des benchmarks (20 min)

Les binômes présentent leur benchmark SGBD (15 min de présentations, échanges). L'intervenant conclut en validant le **choix d'Oracle** pour NanoOrbit et en synthétisant les arguments. Transition : *« Oracle est choisi, la base est livrée — il faut maintenant l'administrer. »*

### Bloc 2 — Le plan d'administration (25 min)

**1.1 du syllabus.** Qu'est-ce qu'un plan d'administration ? Quels indicateurs et éléments prendre en compte :

- Disponibilité attendue, plages de service
- Volumétrie et croissance prévisionnelle
- Fréquence et fenêtres de maintenance
- Stratégie de sauvegarde (préfigure la Partie 3)
- Indicateurs de supervision (préfigure la Partie 5)

**Importance du contrat de services** : le plan d'administration n'est pas générique, il découle des engagements pris. Faire le lien explicite avec `00-cadrage/contrat-de-services.md` : chaque ligne du contrat (RPO, RTO, disponibilité) se traduit en élément du plan.

### Bloc 3 — Les outils Oracle d'administration (35 min)

**1.2 du syllabus.** Présentation des outils qui simplifient l'administration :

| Outil | Usage |
|---|---|
| Oracle Manager (SQL*DBA) | Administration en ligne de commande historique |
| Network Manager | Configuration réseau, listeners, services |
| Oracle Enterprise Manager | Console graphique de supervision et d'administration |
| SQL Studio for Oracle | Environnement de développement et requêtage |

**Démo en direct** sur l'environnement NanoOrbit : connexion via SQL*Plus / SQLcl, navigation dans Oracle Enterprise Manager, exploration des vues du dictionnaire de données (`user_tables`, `user_segments`, `dba_data_files`, `v$session`).

### Bloc 4 — Atelier : ébauche du plan d'administration NanoOrbit (30 min)

Les binômes commencent à rédiger le **plan d'administration NanoOrbit** (livrable L1-A). À partir du contrat de services, ils identifient :

- Les éléments à surveiller pour chaque famille de données
- Les fenêtres de maintenance compatibles avec une disponibilité 24/7
- Les premiers indicateurs candidats

Le plan sera finalisé en autonomie. L'atelier sert à lancer et cadrer.

### Bloc 5 — Synthèse et briefing FOAD (10 min)

Synthèse : le plan d'administration découle du contrat de services. Briefing de la séance 3 (FOAD) : organisation et optimisation du stockage. Annonce du travail FOAD et de la procédure de sauvegarde du travail entre séances.

---

## 🎒 Supports à préparer

| Support | Format | Emplacement |
|---|---|---|
| Slides outils Oracle | PPTX/PDF | `slides/` |
| Environnement Oracle opérationnel | Instance Docker | `../../01-environnement/` |
| Trame du plan d'administration | Document à compléter | `ressources/trame-plan-administration.md` |
| Scripts d'exploration du dictionnaire | `.sql` | `ressources/exploration-dictionnaire.sql` |

## ⚠️ Points de vigilance

**Vérifier que tous les binômes ont rendu le benchmark** avant la séance, sinon la restitution s'effondre.

**Ne pas transformer la présentation des outils en catalogue exhaustif** : l'objectif est que les apprenants sachent à quoi sert chaque outil et puissent en choisir un, pas qu'ils en maîtrisent toutes les fonctions.

**S'assurer que la procédure de sauvegarde du travail FOAD est claire** avant de lancer la séance 3 — c'est ce qui permet au fil rouge d'avancer.

## 📎 Livrable du fil rouge

| Réf. | Livrable | Quand |
|---|---|---|
| L1-A | Plan d'administration NanoOrbit | Lancé en S2, finalisé en FOAD avant S3 |

## 📚 Ressources

- [Fil rouge NanoOrbit](../../00-cadrage/fil-rouge.md)
- [Contrat de services](../../00-cadrage/contrat-de-services.md)
- [Séance 3 — Stockage](../seance-3-stockage/README.md)

---

*Séance 2 — Module BDOE633 — Branche `academy`*
