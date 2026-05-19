# Trame — Plan d'administration de la base NanoOrbit

> **Livrable L1-A du fil rouge.** Ce document est une trame à compléter en binôme. Il constitue le premier élément de votre dossier d'exploitation NanoOrbit.
>
> Remplacez chaque zone `[ … ]` par votre contenu. Justifiez chaque choix en référence au [contrat de services](../../../00-cadrage/contrat-de-services.md).

---

## 1. Identification

| Rubrique | Valeur |
|---|---|
| Base administrée | NanoOrbit — schéma `NANOORBIT_ADMIN` sur `FREEPDB1` |
| SGBD | Oracle Database 23ai |
| Binôme | `[ noms ]` |
| Date de rédaction | `[ date ]` |
| Version du document | `[ v1, v2… ]` |

## 2. Périmètre et classification des données

Rappelez les trois familles de données du contrat de services et les tables qui les composent.

| Famille | Tables concernées | Caractéristique métier |
|---|---|---|
| Référentiel | `[ … ]` | `[ … ]` |
| Opérationnel | `[ … ]` | `[ … ]` |
| Historique | `[ … ]` | `[ … ]` |

## 3. Engagements de service à garantir

Reportez ici les engagements du contrat de services qui structurent votre plan.

| Engagement | Référentiel | Opérationnel | Historique |
|---|---|---|---|
| Disponibilité cible | `[ … ]` | `[ … ]` | `[ … ]` |
| RPO (perte maximale) | `[ … ]` | `[ … ]` | `[ … ]` |
| RTO (temps de reprise) | `[ … ]` | `[ … ]` | `[ … ]` |

## 4. Éléments à surveiller

Pour chaque élément, indiquez ce que vous surveillez et pourquoi (quel engagement du contrat le justifie).

| Élément | Ce qui est surveillé | Engagement justificatif |
|---|---|---|
| Disponibilité | `[ … ]` | `[ … ]` |
| Volumétrie et croissance | `[ … ]` | `[ … ]` |
| Espace de stockage | `[ … ]` | `[ … ]` |
| Performances des requêtes | `[ … ]` | `[ … ]` |
| Sauvegardes | `[ … ]` | `[ … ]` |

## 5. Fenêtres de maintenance

Définissez les créneaux pendant lesquels une intervention de maintenance est possible sans rompre le service.

| Famille | Indisponibilité tolérée | Fenêtre de maintenance proposée | Justification |
|---|---|---|---|
| Référentiel | `[ … ]` | `[ … ]` | `[ … ]` |
| Opérationnel | `[ … ]` | `[ … ]` | `[ … ]` |
| Historique | `[ … ]` | `[ … ]` | `[ … ]` |

> 💡 Rappel : les satellites passent toutes les 90 minutes et la disponibilité opérationnelle est de 99,5 %. Une fenêtre de maintenance doit tenir compte de ces deux contraintes.

## 6. Indicateurs candidats (premiers KPI)

Listez les premiers indicateurs que vous suivrez. Ils seront précisés et paramétrés en séance 6.

| Indicateur | Ce qu'il mesure | Seuil d'alerte envisagé |
|---|---|---|
| `[ … ]` | `[ … ]` | `[ … ]` |
| `[ … ]` | `[ … ]` | `[ … ]` |
| `[ … ]` | `[ … ]` | `[ … ]` |
| `[ … ]` | `[ … ]` | `[ … ]` |

## 7. Outils d'administration retenus

Indiquez les outils Oracle que vous utiliserez et pour quel usage.

| Outil | Usage prévu dans le module |
|---|---|
| `[ SQL*Plus / SQLcl ]` | `[ … ]` |
| `[ Oracle Enterprise Manager ]` | `[ … ]` |
| `[ autre ]` | `[ … ]` |

## 8. Première cartographie de la base

À compléter après exploration de la base avec le script `exploration-dictionnaire.sql`.

| Constat | Observation |
|---|---|
| Nombre de tables | `[ … ]` |
| Volumétrie totale approximative | `[ … ]` |
| Table la plus volumineuse | `[ … ]` |
| Organisation actuelle du stockage | `[ … ]` |
| Index existants | `[ … ]` |

## 9. Points d'attention identifiés

Notez ici ce qui, dès la prise en main, vous semble devoir être amélioré.

- `[ … ]`
- `[ … ]`
- `[ … ]`

---

## ✅ Critères de qualité du livrable

Avant de déposer ce plan, vérifiez que :

- [ ] Chaque choix est justifié par référence au contrat de services
- [ ] Les trois familles de données sont traitées distinctement
- [ ] Les fenêtres de maintenance respectent les engagements de disponibilité
- [ ] La cartographie reflète une exploration réelle de la base
- [ ] Le document est lisible et pourra être intégré au dossier d'exploitation

---

*Trame L1-A — Séance 2 — Module BDOE633 — Branche `academy`*
