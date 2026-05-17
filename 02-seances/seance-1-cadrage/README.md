# Séance 1 — Cadrage et fil rouge NanoOrbit

**Format** : Face-à-face présentiel (FFP) · **Durée** : 2 h · **Partie syllabus** : Partie I — Survol

---

## 🧵 Étape du fil rouge

> **Étape 0 — NanoOrbit choisit son SGBD.**
> La startup part d'une page blanche. L'équipe d'administration est missionnée pour réaliser un benchmark et formuler une recommandation de SGBD.

| | |
|---|---|
| État de la base **en entrée** | Aucune base — page blanche |
| État de la base **en sortie** | Choix d'Oracle 23ai acté et justifié ; exigences du contrat de services connues |
| Livrables produits | L0-A (benchmark), L0-B (recommandation) |

---

## 🎯 Objectifs pédagogiques

À l'issue de la séance, l'apprenant est capable de :

- **Situer** le module BDOE633 dans son parcours (lien MSPR TPRE623, compétences ASRBD1.6/1.7/1.8)
- **Distinguer** la posture de développeur BDD de celle d'administrateur
- **Décrire** le système d'information NanoOrbit et le fil rouge du module
- **Lire et interpréter** un contrat de services comme document structurant les décisions d'administration
- **Lancer** le TD Benchmark SGBD en autonomie

## ⏱️ Découpage temporel

| Temps | Bloc | Modalité | Durée |
|---|---|---|---|
| 0:00 → 0:15 | Accueil et cadrage du module | Exposé | 15 min |
| 0:15 → 0:35 | Du développeur à l'administrateur : changement de posture | Exposé + échange | 20 min |
| 0:35 → 1:05 | Le fil rouge NanoOrbit et sa progression | Exposé + démo Oracle | 30 min |
| 1:05 → 1:15 | **Pause** | — | 10 min |
| 1:15 → 1:40 | Le contrat de services NanoOrbit : décryptage | Atelier guidé | 25 min |
| 1:40 → 1:55 | Lancement du TD Benchmark SGBD | Briefing | 15 min |
| 1:55 → 2:00 | Synthèse et annonce séance 2 | Exposé | 5 min |

---

## 📋 Détail des blocs

### Bloc 1 — Accueil et cadrage (15 min)

Présentation du module dans le bloc BC01, articulation avec la **MSPR TPRE623**, format pédagogique (2 h FFP + 4 h CV + 8 h FOAD), modalité d'évaluation formative. Annonce des trois compétences en termes opérationnels :

> *« À la fin du module, vous saurez garantir la disponibilité d'une base Oracle de production, mettre en œuvre une stratégie de sauvegarde/restauration, et superviser proactivement les performances. »*

**Point clé** : annoncer que l'évaluation formative s'appuiera sur le **dossier d'exploitation NanoOrbit** construit tout au long du module.

### Bloc 2 — Changement de posture (20 min)

Exposé interactif sur la différence entre développeur BDD et administrateur. Tableau à construire avec les apprenants :

| Le développeur BDD | L'administrateur |
|---|---|
| Conçoit le MCD/MLD | Reçoit la base en production |
| Écrit le DDL et les triggers | Organise le stockage (tablespaces, index) |
| Écrit les requêtes et procédures | Mesure leur performance, les optimise |
| Livre une application | Garantit RPO/RTO, sauvegarde, supervise |
| Pense « fonctionnel » | Pense « disponibilité, intégrité, performance » |

**Point clé** : pour ce module, on ne touche plus au schéma ni au code PL/SQL. On hérite d'un existant à administrer.

### Bloc 3 — Le fil rouge NanoOrbit et sa progression (30 min)

Présentation du contexte métier : constellation de CubeSats, surveillance climatique, trois centres de contrôle (Paris, Singapour, Houston), stations au sol, fenêtres de communication.

**Insister sur les caractéristiques qui font de NanoOrbit un cas d'école** :

- **Données non rejouables** : une fenêtre de communication ratée ne se rattrape pas
- **Disponibilité 24/7** : les satellites passent en continu
- **Volumétrie hétérogène** : référentiel stable vs opérationnel en croissance
- **Multi-sites** : trois centres → continuité de service

**Présenter explicitement la progression du fil rouge** (support : `00-cadrage/fil-rouge.md`). Les apprenants doivent comprendre dès la séance 1 que la base NanoOrbit va évoluer par étapes et qu'ils constituent un dossier d'exploitation au fil du module.

**Démo Oracle en direct (10 min)** : connexion sur FREEPDB1 / NANOORBIT_ADMIN, exploration de la base déjà peuplée.

```sql
SELECT table_name, num_rows FROM user_tables ORDER BY num_rows DESC;
SELECT statut, COUNT(*) AS nb FROM satellite GROUP BY statut;
SELECT segment_name, ROUND(bytes/1024/1024, 2) AS mb
FROM user_segments ORDER BY bytes DESC;
```

**Point clé** : la base existe, elle est peuplée, personne ne va la reconstruire — on va apprendre à vivre avec et à la faire progresser.

### ☕ Pause (10 min)

### Bloc 4 — Le contrat de services NanoOrbit (25 min)

Distribution et lecture commentée de `00-cadrage/contrat-de-services.md`. Présentation des rubriques : classification des données en trois familles, disponibilité, RPO/RTO, stratégie de sauvegarde, indicateurs supervisés, PRA.

**Atelier guidé (10 min)** — faire émerger les conséquences opérationnelles :

> *« Si le RPO opérationnel est de 15 minutes, qu'est-ce que ça impose techniquement ? »* → archivelog mode, sauvegarde fréquente des redo logs.

> *« Disponibilité 99,5 % : combien d'heures d'indisponibilité par an ? »* → ≈ 44 h, soit ≈ 50 min/semaine. À mettre en regard d'un passage satellite toutes les 90 min.

> *« Que se passe-t-il si Paris tombe pendant un passage sur Singapour ? »* → continuité multi-sites, traitée en séance 4.

**Point clé** : chaque décision technique du module se justifiera en référence à ce contrat. C'est ce qui transforme l'exercice technique en posture d'administrateur.

### Bloc 5 — Lancement du TD Benchmark SGBD (15 min)

Briefing de `td-benchmark-sgbd.md`. Le benchmark est **contextualisé NanoOrbit** : pour chaque SGBD, évaluer s'il aurait été un bon choix pour la startup, sur quatre critères opérationnels.

**Modalités** : binômes, rendu écrit 2 pages avant la séance 2, restitution orale 15 min en début de séance 2. Le benchmark constitue le **livrable L0-A** du fil rouge.

### Bloc 6 — Synthèse et annonce (5 min)

Trois points clés : changement de posture, fil rouge progressif NanoOrbit, rôle structurant du contrat de services. Annonce de la séance 2 (plan d'administration et outils Oracle).

**Travail pour la séance 2** : finaliser le TD Benchmark, vérifier l'accès à l'environnement Oracle, lire le contrat de services et le fil rouge en entier.

---

## 🎒 Supports à préparer

| Support | Format | Emplacement |
|---|---|---|
| Slides de cadrage | PPTX/PDF, ≈ 20 slides | `slides/` |
| Environnement Oracle peuplé | Instance Docker | `../../01-environnement/` |
| Contrat de services (impression) | PDF | `../../00-cadrage/contrat-de-services.md` |
| Fil rouge NanoOrbit (support de présentation) | PDF | `../../00-cadrage/fil-rouge.md` |
| Fiche TD Benchmark | PDF | `td-benchmark-sgbd.md` |
| Scripts SQL de démo | `.sql` commenté | `ressources/demo-exploration.sql` |

## ⚠️ Points de vigilance

**Démo Oracle live sensible** : prévoir un plan B avec screenshots commentés.

**Résister à la tentation technique** : séance de cadrage, pas de séance d'outils. Les apprenants repartent avec une posture et un cadre.

**Rendre le fil rouge explicite** : c'est la séance où on installe la mécanique « la base va avancer par étapes ». Si ce n'est pas clair ici, le fil rouge se perd.

**Vérifier l'accès à l'environnement** et acter la composition des binômes avant la fin de la séance.

## 📎 Livrables du fil rouge produits dans cette séance

| Réf. | Livrable | Quand |
|---|---|---|
| L0-A | Benchmark SGBD comparatif | Lancé en S1, rendu avant S2 |
| L0-B | Recommandation argumentée | Lancé en S1, rendu avant S2 |

## 📚 Ressources

- [Fil rouge NanoOrbit](../../00-cadrage/fil-rouge.md)
- [Contrat de services](../../00-cadrage/contrat-de-services.md)
- [Objectifs et contenu](../../00-cadrage/objectifs-et-contenu.md)
- [TD Benchmark SGBD](td-benchmark-sgbd.md)
- [Environnement Oracle](../../01-environnement/README.md)

---

*Séance 1 — Module BDOE633 — Branche `academy`*
