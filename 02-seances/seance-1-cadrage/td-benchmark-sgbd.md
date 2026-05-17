# TD — Benchmark SGBD contextualisé NanoOrbit

**Module** : BDOE633 — Administration et Optimisation des Bases de Données
**Séance** : 1 (lancement) → restitution séance 2
**Modalité** : binômes
**Volume horaire** : ≈ 2 h de travail personnel

---

## 🎯 Objectif

Réaliser un benchmark des principaux SGBD du marché **dans une perspective d'administrateur** et formuler une recommandation argumentée pour le contexte NanoOrbit.

Ce TD n'est pas un comparatif générique de fonctionnalités. C'est un exercice de **jugement d'administrateur** : confronter les caractéristiques de chaque SGBD aux exigences d'un cas d'usage réel.

## 🛰️ Rappel du contexte NanoOrbit

NanoOrbit exploite une constellation de CubeSats depuis trois centres de contrôle (Paris, Singapour, Houston). La base de données doit :

- Garantir une disponibilité de 99,5 % H24 sur les tables opérationnelles
- Supporter un RPO de 15 minutes (perte de données acceptable très limitée)
- Permettre un RTO de 30 minutes sur les tables opérationnelles
- Supporter une architecture multi-sites (réplication, fragmentation, ou autre approche)
- Offrir un outillage de supervision et de sauvegarde mature

*Pour les détails, se référer au [contrat de services](../../00-cadrage/contrat-de-services.md).*

## 📋 SGBD à étudier

Vous étudiez **les 6 SGBD suivants** :

1. **Oracle Database** (référence du module)
2. **PostgreSQL**
3. **MySQL**
4. **Microsoft SQL Server**
5. **MariaDB**
6. **MongoDB**

> ℹ️ MongoDB est inclus volontairement bien qu'il soit NoSQL : l'enjeu est d'évaluer si un SGBD non relationnel aurait pu convenir à NanoOrbit, et de justifier votre conclusion.

## 🔍 Critères d'évaluation

Pour chaque SGBD, évaluez les **quatre critères suivants** sur une échelle de 1 à 5 :

### Critère 1 — Capacité de sauvegarde/restauration native

- Quels outils de sauvegarde le SGBD fournit-il en natif ?
- Sauvegarde à chaud possible ? Sauvegarde incrémentale ? Point-in-time recovery ?
- Restauration partielle (tablespace, schéma, table) possible ?

### Critère 2 — Outillage de supervision

- Quels outils de monitoring sont fournis (consoles, vues système, métriques) ?
- Possibilité d'alertes automatisées ?
- Intégration avec des outils tiers (Grafana, Zabbix, etc.)

### Critère 3 — Support du multi-sites

- Mécanismes de réplication disponibles (synchrone, asynchrone, multi-maître) ?
- Possibilité de fragmentation horizontale ou verticale ?
- Robustesse face à une panne de site ?

### Critère 4 — Coût de licence à l'échelle d'une startup

- Modèle de licence (open source, commercial, freemium) ?
- Coût estimé pour une infrastructure de 3 sites avec haute disponibilité ?
- Existence d'une édition gratuite avec limites acceptables ?

## 📊 Format de restitution écrite

Document de **2 pages maximum** structuré ainsi :

### Page 1 — Tableau de synthèse

| SGBD | Sauvegarde | Supervision | Multi-sites | Coût | **Total /20** |
|---|---|---|---|---|---|
| Oracle | /5 | /5 | /5 | /5 | /20 |
| PostgreSQL | /5 | /5 | /5 | /5 | /20 |
| MySQL | /5 | /5 | /5 | /5 | /20 |
| SQL Server | /5 | /5 | /5 | /5 | /20 |
| MariaDB | /5 | /5 | /5 | /5 | /20 |
| MongoDB | /5 | /5 | /5 | /5 | /20 |

Sous le tableau, une **justification d'une ou deux phrases** par SGBD expliquant la note dominante.

### Page 2 — Recommandation argumentée

- **Quel SGBD auriez-vous recommandé à NanoOrbit et pourquoi ?**
- Quelles seraient les limites de votre choix et comment les compenser ?
- Le choix d'Oracle (imposé dans ce module) vous semble-t-il pertinent pour NanoOrbit ? Justifiez.

## 🗣️ Restitution orale (séance 2)

**Format** : 15 minutes par binôme, suivies de 5 minutes de questions.

**Attendus** :
- Présentation du tableau de synthèse
- Argumentation de la recommandation
- Réponses aux questions de la promo et de l'intervenant

## 📚 Ressources autorisées

- Documentation officielle des SGBD étudiés
- Comparatifs DB-Engines (https://db-engines.com)
- Articles techniques et retours d'expérience
- Bibliothèque ENI (accès EPSI)

**Attention** : citez vos sources. Une recommandation non sourcée est considérée comme une opinion non étayée.

## 🎓 Critères d'évaluation du TD

| Critère | Pondération |
|---|---|
| Qualité du tableau de synthèse (exhaustivité, justesse) | 30 % |
| Pertinence des justifications par critère | 25 % |
| Cohérence de la recommandation avec le contexte NanoOrbit | 25 % |
| Qualité de la restitution orale | 20 % |

## 📅 Calendrier

| Étape | Échéance |
|---|---|
| Constitution des binômes | Fin de séance 1 |
| Travail personnel | Entre séance 1 et séance 2 |
| Rendu écrit (PDF, 2 pages) | Veille de la séance 2, 23:59 |
| Restitution orale | Début de séance 2 |

---

## 💡 Conseils

**Ne refaites pas le comparatif générique** que tout le monde trouve sur Internet. Votre valeur ajoutée est de **prendre position** en référence au contexte NanoOrbit.

**Le SGBD le mieux noté n'est pas forcément celui qu'il faut recommander** : un SGBD très complet mais hors budget pour une startup n'est pas le bon choix. Le jugement d'administrateur intègre les contraintes business.

**Soyez critiques sur Oracle** : c'est le SGBD du module, mais ce n'est pas forcément le meilleur choix pour toutes les situations. Une recommandation lucide qui pointe les limites d'Oracle pour ce cas d'usage sera mieux notée qu'un éloge complaisant.

---

*TD — Module BDOE633 — Séance 1*
