# Séance 4 — Stratégie de sauvegarde et plan de reprise d'activité

**Format** : Classe virtuelle · **Durée** : 2 h · **Partie syllabus** : Partie 3 — Stratégie de sauvegarde/restauration

---

## 🧵 Étape du fil rouge

> **Étape 2 — NanoOrbit exige des garanties de continuité.**
> La direction s'inquiète : que se passe-t-il si la base tombe pendant un passage satellite ? Elle exige une stratégie de sauvegarde/restauration et un plan de reprise d'activité conformes au contrat de services.

| | |
|---|---|
| État de la base **en entrée** | Base outillée, stockage organisé — aucune stratégie de sauvegarde formalisée |
| État de la base **en sortie** | Stratégie de sauvegarde et PRA définis et validés (sur le papier) |
| Livrables produits | L2-A (stratégie), L2-B (PRA) |

---

## 🎯 Objectifs pédagogiques

À l'issue de la séance, l'apprenant est capable de :

- **Identifier** les éléments à prendre en compte pour définir une stratégie de sauvegarde/restauration
- **Concevoir** une procédure de sauvegarde et de restauration (type, données, fréquence, conservation, emplacement)
- **Définir** les objectifs d'un plan de reprise d'activité
- **Concevoir** un PRA adapté au contexte NanoOrbit

## ⏱️ Découpage temporel

| Temps | Bloc | Modalité | Durée |
|---|---|---|---|
| 0:00 → 0:10 | Rappel de l'état du fil rouge | Exposé | 10 min |
| 0:10 → 0:45 | La sauvegarde et la restauration | Exposé | 35 min |
| 0:45 → 1:15 | Le plan de reprise d'activité | Exposé + échange | 30 min |
| 1:15 → 1:50 | Atelier : stratégie et PRA NanoOrbit | Atelier guidé | 35 min |
| 1:50 → 2:00 | Présentation du cas pratique n°1 + briefing FOAD | Exposé | 10 min |

---

## 📋 Détail des blocs

### Bloc 1 — Rappel de l'état du fil rouge (10 min)

*« La base NanoOrbit est outillée et son stockage est organisé. Mais elle n'est pas protégée : aucune sauvegarde. Si elle tombe maintenant, NanoOrbit perd ses données. »* Rappel des exigences du contrat de services en matière de continuité (RPO, RTO).

### Bloc 2 — La sauvegarde et la restauration (35 min)

**2.1 du syllabus.** Éléments à prendre en compte pour définir une stratégie. Présentation des cinq dimensions d'une procédure de sauvegarde :

| Dimension | Questions à se poser |
|---|---|
| Type de sauvegarde | Complète, incrémentale, différentielle ? À chaud ou à froid ? |
| Données à sauvegarder | Toute la base ? Certains tablespaces ? Les archive logs ? |
| Fréquence | Quotidienne, horaire ? Selon le RPO ? |
| Durée de conservation | Combien de temps garder chaque sauvegarde ? |
| Emplacement de stockage | Local, distant, archive froide ? |

Faire systématiquement le lien avec le contrat de services NanoOrbit : un RPO de 15 min sur les tables opérationnelles **impose** le mode archivelog et une sauvegarde fréquente des redo logs.

### Bloc 3 — Le plan de reprise d'activité (30 min)

**2.2 du syllabus.** Définition et objectifs d'un PRA. Différence entre PRA et stratégie de sauvegarde. Concevoir un PRA : scénarios de sinistre, procédures de reprise, RTO par scénario, tests périodiques.

Échange sur le cas NanoOrbit multi-sites : que se passe-t-il si le centre de Paris devient indisponible ? Comment Singapour prend-il le relais ? (Le PRA du contrat de services prévoit une bascule.)

### Bloc 4 — Atelier : stratégie et PRA NanoOrbit (35 min)

Les binômes rédigent la **stratégie de sauvegarde/restauration** (L2-A) et le **PRA** (L2-B) de NanoOrbit, en s'appuyant sur le contrat de services. Production cadrée en séance, finalisée en autonomie si nécessaire.

### Bloc 5 — Présentation du cas pratique n°1 + briefing FOAD (10 min)

Présentation de l'énoncé du **cas pratique n°1** (`03-cas-pratiques/cp1-sauvegarde-restauration/`), qui sera traité en séance 5 en FOAD. Les apprenants y mettront en œuvre concrètement la stratégie qu'ils viennent de définir.

---

## 🎒 Supports à préparer

| Support | Format | Emplacement |
|---|---|---|
| Slides sauvegarde/restauration et PRA | PPTX/PDF | `slides/` |
| Trame de stratégie de sauvegarde | Document à compléter | `ressources/trame-strategie-sauvegarde.md` |
| Trame de PRA | Document à compléter | `ressources/trame-pra.md` |
| Énoncé du cas pratique n°1 | Document | `../../03-cas-pratiques/cp1-sauvegarde-restauration/enonce.md` |

## ⚠️ Points de vigilance

**Rester au niveau stratégique** : cette séance définit la stratégie, elle ne la met pas en œuvre. La mise en œuvre RMAN est l'objet de la séance 5. Ne pas anticiper.

**Calibrer le PRA au niveau BAC+3** : scénarios concrets, RTO par scénario, procédures claires. Pas de matrices de criticité complexes ni de SLA contractuels élaborés.

**Lien permanent avec le contrat de services** : chaque choix de la stratégie doit pouvoir se justifier par une ligne du contrat.

## 📎 Livrables du fil rouge

| Réf. | Livrable | Contenu |
|---|---|---|
| L2-A | Stratégie de sauvegarde/restauration | Les 5 dimensions, justifiées par le contrat de services |
| L2-B | Plan de reprise d'activité | Scénarios, procédures, RTO, tests |

## 📚 Ressources

- [Fil rouge NanoOrbit](../../00-cadrage/fil-rouge.md)
- [Contrat de services — stratégie de sauvegarde et PRA](../../00-cadrage/contrat-de-services.md)
- [Cas pratique n°1](../../03-cas-pratiques/cp1-sauvegarde-restauration/enonce.md)
- [Séance 5 — Cas pratique n°1](../seance-5-cas-pratique-backup/README.md)

---

*Séance 4 — Module BDOE633 — Branche `academy`*
