# Cas pratique n°2 — Supervision de la base NanoOrbit

**Module** : BDOE633 · **Séance** : 7 (FOAD) · **Partie syllabus** : Partie 6 · **Modalité** : binômes

---

## 🧵 Place dans le fil rouge

> **Étape 5 — Audit complet demandé par la direction.**
> La base NanoOrbit est outillée, sauvegardée, restaurable. La direction demande maintenant un audit complet de sa supervision et un plan d'actions préventif.

---

## 🎯 Contexte

Ce cas pratique se déroule **à partir de l'environnement du cas pratique n°1** et à l'aide du SGBD Oracle. La base NanoOrbit est dans l'état laissé par les séances précédentes : stockage organisé, sauvegardes opérationnelles, premiers éléments de supervision posés en séance 6.

La direction de NanoOrbit veut s'assurer que la base est supervisée selon les règles de l'art et que l'équipe sait anticiper les problèmes.

## 📋 Travail demandé

### 1. Définir les indicateurs-clés de performance

Définissez les indicateurs-clés de performance de la base NanoOrbit **tout en respectant le contrat de services** présenté pour ce cas. Chaque indicateur doit être rattaché à un engagement du contrat.

### 2. Mettre en œuvre le paramétrage de la supervision

Mettez en œuvre le paramétrage de la supervision à l'aide des indicateurs-clés définis à la question 1, en utilisant le SGBD Oracle. Cela comprend la configuration des seuils, des alertes et des notifications.

### 3. Expliquer le traitement des remontées d'alertes

Expliquez comment sont traitées les remontées d'alertes de l'outil de supervision : qui est notifié, selon quel canal, et quelle action est déclenchée pour chaque type d'alerte.

### 4. Définir le plan d'actions préventif

Définissez le plan d'actions pour anticiper les problèmes pouvant survenir sur la base NanoOrbit : saturation de tablespace, croissance de l'historique, dégradation des temps de réponse, échec de sauvegarde.

## ✅ Livrables attendus

| Réf. | Livrable | Contenu |
|---|---|---|
| L5-A | Rapport d'audit | État de la supervision, indicateurs définis, points forts et axes d'amélioration |
| L5-B | Plan d'actions | Actions correctives et préventives, priorisées |
| — | Dossier d'exploitation complet | Assemblage de tous les livrables L0 à L5 |

Le dossier d'exploitation complet constitue le support de l'**évaluation formative**.

## 📐 Critères d'évaluation

| Critère | Pondération |
|---|---|
| Pertinence des indicateurs et rattachement au contrat de services | 25 % |
| Correction du paramétrage de la supervision Oracle | 25 % |
| Clarté de l'explication du traitement des alertes | 20 % |
| Qualité et réalisme du plan d'actions préventif | 30 % |

## 💡 Conseils

- Un bon indicateur est **actionnable** : s'il dépasse son seuil, on sait quoi faire. Évitez les indicateurs qu'on regarde sans pouvoir agir.
- La supervision proactive se juge sur sa capacité à **prévenir**, pas à constater. Le plan d'actions préventif est le cœur de ce cas pratique.
- Ce cas pratique est aussi le moment d'assembler votre dossier d'exploitation. Relisez vos livrables L0 à L4 : forment-ils un ensemble cohérent ?

## 📚 Référence

- [Contrat de services NanoOrbit](../../00-cadrage/contrat-de-services.md)
- [Cas pratique n°1 — environnement de départ](../cp1-sauvegarde-restauration/enonce.md)
- [Séance 7 — déroulé détaillé](../../02-seances/seance-7-evaluation/README.md)
- [Évaluation — mise en situation](../../04-evaluation/mise-en-situation.md)

---

*Cas pratique n°2 — Module BDOE633 — Branche `academy`*
