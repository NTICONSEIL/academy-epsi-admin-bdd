# Contrat de services — Plateforme de données NanoOrbit

> **Document de référence du module BDOE633.**
> Toutes les décisions techniques d'administration prises au cours du module se justifient en référence à ce contrat.

---

## 1. Contexte et parties prenantes

| Élément | Détail |
|---|---|
| Client | NanoOrbit SAS — opérateur de constellation CubeSats |
| Prestataire | Équipe Administration BDD (les apprenants) |
| Périmètre couvert | Base de données Oracle `NANOORBIT_ADMIN` sur instance `FREEPDB1` |
| Centres de contrôle desservis | Paris (référence), Singapour, Houston |
| Date d'effet | Année universitaire 2025-2026 |

## 2. Classification des données

Toutes les données ne se valent pas. Le contrat distingue trois familles, avec des engagements différenciés.

| Famille | Tables concernées | Caractéristique métier |
|---|---|---|
| **Référentiel** | `ORBITE`, `INSTRUMENT`, `CENTRE_CONTROLE`, `STATION_SOL`, `MISSION` | Données stables, peu de modifications, structurantes |
| **Opérationnel** | `SATELLITE`, `EMBARQUEMENT`, `AFFECTATION_STATION`, `PARTICIPATION`, `FENETRE_COM` | Données vivantes, écritures fréquentes, critiques pour les opérations |
| **Historique** | `HISTORIQUE_STATUT` | Données en croissance continue, lecture rare mais conservation longue |

## 3. Engagements de disponibilité

| Famille de données | Disponibilité cible | Plage horaire | Indisponibilité tolérée |
|---|---|---|---|
| Référentiel | 99,9 % | Heures ouvrées centre Paris (08:00-20:00 UTC+1) | ≈ 8 h / an |
| Opérationnel | 99,5 % | H24 — passages satellites en continu | ≈ 44 h / an, soit ≈ 50 min / semaine |
| Historique | 99,0 % | H24 mais non bloquant | ≈ 88 h / an |

**Justification opérationnelle** : un satellite passe au-dessus d'une station environ toutes les 90 minutes. Une indisponibilité de 50 minutes sur les tables opérationnelles correspond donc, dans le pire cas, à la perte d'**une fenêtre de communication** — incident gérable. Au-delà, la perte devient inacceptable pour le métier.

## 4. Engagements sur la perte de données et la reprise

### RPO — Recovery Point Objective (perte maximale acceptable)

| Famille | RPO | Conséquence technique |
|---|---|---|
| Référentiel | 24 h | Sauvegarde quotidienne suffisante |
| Opérationnel | **15 minutes** | Mode archivelog obligatoire, sauvegarde des redo logs |
| Historique | 24 h | Sauvegarde quotidienne suffisante |

### RTO — Recovery Time Objective (temps de reprise maximal)

| Famille | RTO | Implication |
|---|---|---|
| Référentiel | 1 heure | Restauration depuis sauvegarde complète acceptable |
| Opérationnel | **30 minutes** | Procédure de restauration testée, automatisée |
| Historique | 4 heures | Restauration différée acceptable |

## 5. Stratégie de sauvegarde

| Type de sauvegarde | Fréquence | Horaire | Cible |
|---|---|---|---|
| Sauvegarde complète (RMAN) | Hebdomadaire | Dimanche 02:00 UTC | Base entière |
| Sauvegarde incrémentale (RMAN) | Toutes les 4 heures | 00, 04, 08, 12, 16, 20 UTC | Blocs modifiés depuis la dernière sauvegarde |
| Sauvegarde des archive logs | Continue | À chaque switch de redo | Tous les archive logs |

### Conservation

- **30 jours** en stockage en ligne (rapide à restaurer)
- **1 an** en stockage archive (restauration différée acceptable)
- **7 ans** en stockage froid pour les sauvegardes annuelles (obligations contractuelles missions scientifiques)

## 6. Indicateurs supervisés

L'administrateur met en place une supervision proactive sur les indicateurs suivants :

| Indicateur | Seuil d'alerte | Seuil critique | Famille concernée |
|---|---|---|---|
| Disponibilité instance Oracle | < 100 % sur 5 min | < 99,5 % sur 1 h | Toutes |
| Latence moyenne INSERT `FENETRE_COM` | > 200 ms | > 500 ms | Opérationnel |
| Taux d'occupation tablespace | > 80 % | > 90 % | Toutes |
| Taille de `HISTORIQUE_STATUT` | Croissance > 10 % / semaine | Croissance > 25 % / semaine | Historique |
| Échec d'un job RMAN | 1 échec | 2 échecs consécutifs | Toutes |
| Sessions actives Oracle | > 50 | > 80 | Toutes |
| Temps moyen d'exécution du package `pkg_nanoOrbit` | > 1 s | > 3 s | Opérationnel |

## 7. Plan de reprise d'activité (PRA)

| Scénario | Procédure | RTO cible |
|---|---|---|
| Corruption d'un bloc de données | Block recovery RMAN | 15 min |
| Perte d'un fichier de données | Restauration de tablespace | 30 min |
| Perte d'un tablespace complet | Restauration de tablespace + recovery | 1 h |
| Perte de l'instance complète | Restauration complète + recovery | 4 h |
| Indisponibilité centre Paris | Bascule sur centre Singapour | 1 h |

**Test du PRA** : un exercice de restauration complète est réalisé **trimestriellement** sur un environnement isolé. La procédure et le temps de reprise sont documentés.

## 8. Engagements de l'administrateur

L'administrateur s'engage à :

- Maintenir le **journal d'exploitation** des opérations critiques (sauvegardes, restaurations, incidents)
- Produire un **rapport mensuel** synthétisant le respect des engagements (disponibilité réelle, incidents, sauvegardes réalisées)
- Notifier le client **dans l'heure** en cas d'incident critique
- Tenir à jour la **documentation d'exploitation** du système

## 9. Hors périmètre

Les éléments suivants ne sont **pas** couverts par ce contrat :

- Le développement applicatif (modifications de schéma, écriture de code PL/SQL)
- L'administration des serveurs hôtes (OS, réseau, stockage matériel)
- La gestion de la sécurité applicative (gestion des comptes utilisateurs métier)
- Le support fonctionnel aux utilisateurs métier de NanoOrbit

---

## Annexe — Glossaire des engagements

| Terme | Définition |
|---|---|
| **RPO** | Perte de données maximale acceptable, mesurée en temps. Un RPO de 15 minutes signifie qu'en cas de sinistre, on accepte de perdre au maximum les 15 dernières minutes de données. |
| **RTO** | Délai maximal de remise en service après un sinistre. Un RTO de 30 minutes signifie que le service doit être restauré au plus tard 30 minutes après l'incident. |
| **Disponibilité 99,5 %** | Tolérance d'indisponibilité de 0,5 % sur la période considérée, soit environ 44 h par an ou 50 min par semaine. |
| **Archivelog mode** | Mode Oracle dans lequel les redo logs sont archivés avant d'être réutilisés, permettant la restauration jusqu'à un point précis dans le temps. |
| **PRA** | Plan de reprise d'activité — ensemble des procédures à exécuter pour restaurer le service après un sinistre majeur. |

---

*Document maintenu dans le cadre du module BDOE633 — version pédagogique. Toute ressemblance avec un contrat de services réel est volontaire ; les valeurs chiffrées sont calibrées pour servir la progression pédagogique.*
