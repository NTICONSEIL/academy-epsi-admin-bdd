# Séance 6 — Supervision proactive et monitoring

**Format** : FOAD (autoformation) · **Durée** : 2 h · **Partie syllabus** : Partie 5 — Supervision

---

## 🧵 Étape du fil rouge

> **Étape 4 — La base grossit, des lenteurs apparaissent.**
> NanoOrbit grandit, la base aussi. Des lenteurs apparaissent sur certaines requêtes. La direction veut être prévenue *avant* que les incidents surviennent : il faut une supervision proactive.

| | |
|---|---|
| État de la base **en entrée** | Base sauvegardée et restaurable — aucun dispositif de supervision |
| État de la base **en sortie** | Base supervisée, alertes automatiques sur dépassement de seuil |
| Livrables produits | L4-A (tableau des KPI), L4-B (configuration de la supervision) |

---

## 🎯 Objectifs pédagogiques

À l'issue de la séance, l'apprenant est capable de :

- **Définir** les indicateurs-clés de performance d'une base de données
- **Mettre en œuvre** une analyse temps réel et en peser avantages/inconvénients
- **Configurer** la surveillance via alertes et notifications
- **Anticiper** les problèmes susceptibles de survenir

> Cette séance couvre la compétence **ASRBD1.7 — Mesurer et analyser les performances.**

## 🗺️ Déroulé FOAD

### Temps 1 — La supervision proactive et ses indicateurs (30 min)

**3.1 du syllabus.** Identifier les indicateurs-clés de performance :

| Indicateur | Mesuré via | Lié au contrat de services |
|---|---|---|
| Disponibilité | `v$instance`, uptime | Engagements de disponibilité |
| Utilisation des données | Statistiques de tables, accès | — |
| Espace libre | `dba_free_space`, `dba_data_files` | Seuil tablespace |
| Temps de réponse d'une requête | Plans d'exécution, `v$sql` | Latence INSERT |
| Temps d'exécution d'une requête | `v$sql`, AWR | Temps package `pkg_nanoOrbit` |

L'analyse temps réel : avantages (réactivité), inconvénients (charge, bruit), outils. Comment anticiper les problèmes : tendances, seuils d'alerte, projection de croissance.

**Production attendue** : tableau des KPI supervisés avec seuils, aligné sur le contrat de services (livrable L4-A).

### Temps 2 — Mise en œuvre de la surveillance (45 min)

**3.2 du syllabus.** Travaux dirigés sur la mise en œuvre de la surveillance via alertes et notifications :

- **Configuration de la messagerie** : paramétrage de l'envoi de notifications
- **Surveillance des erreurs** : détection et remontée des erreurs de la base
- **Configuration des opérateurs, alertes et notifications** : qui est prévenu, sur quel seuil, par quel canal

Le syllabus mentionne MySQL, Oracle et SQL Server. La mise en œuvre principale se fait sur **Oracle** (cohérence du fil rouge) ; MySQL et SQL Server sont abordés en survol comparatif.

**Production attendue** : configuration de la supervision — scripts, jobs, définition des alertes (livrable L4-B).

### Temps 3 — Indexation et performance (30 min)

Reprise des candidats à l'indexation identifiés en séance 3. Création des index stratégiques et observation de leur effet sur les temps de réponse. Lien entre optimisation du stockage (ASRBD1.8) et mesure de performance (ASRBD1.7).

### Temps 4 — Anticipation des problèmes (15 min)

À partir des indicateurs mis en place : quels problèmes peut-on anticiper ? Croissance de `HISTORIQUE_STATUT`, saturation de tablespace, dégradation de la latence. Ébauche d'un raisonnement préventif qui sera approfondi au cas pratique n°2.

---

## 🎒 Supports à préparer

| Support | Format | Emplacement |
|---|---|---|
| Énoncé FOAD supervision | Document | `ressources/foad-supervision.md` |
| Catalogue des vues `V$` utiles | Cheatsheet | `ressources/cheatsheet-vues-v.md` |
| Scripts de configuration des alertes | `.sql` | `ressources/` |
| Corrigé (section instructeur) | Document | `instructor/` |

## ⚠️ Points de vigilance

**Supervision proactive ≠ supervision réactive** : insister sur la dimension anticipative. Superviser, ce n'est pas regarder les incidents arriver, c'est les prévenir.

**Calibrer le niveau** : vues `V$` essentielles et Enterprise Manager pour des BAC+3. AWR/ASH peuvent être montrés en démonstration mais ne sont pas un attendu de production.

**Aligner les seuils sur le contrat de services** : les seuils d'alerte ne sont pas arbitraires, ils découlent des engagements pris.

**Retour de correction du cas pratique n°1** : à fournir avant ou au début de cette séance.

## 📎 Livrables du fil rouge

| Réf. | Livrable | Contenu |
|---|---|---|
| L4-A | Tableau des KPI supervisés | Indicateurs, seuils d'alerte, justification |
| L4-B | Configuration de la supervision | Scripts, jobs, alertes et notifications |

## 📚 Ressources

- [Fil rouge NanoOrbit](../../00-cadrage/fil-rouge.md)
- [Contrat de services — indicateurs supervisés](../../00-cadrage/contrat-de-services.md)
- [Cas pratique n°2](../../03-cas-pratiques/cp2-supervision/enonce.md)
- [Séance 7 — Évaluation](../seance-7-evaluation/README.md)

---

*Séance 6 — Module BDOE633 — Branche `academy`*
