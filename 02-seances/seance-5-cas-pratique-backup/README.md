# Séance 5 — Cas pratique n°1 : sauvegarde et restauration

**Format** : FOAD (autoformation) · **Durée** : 2 h · **Partie syllabus** : Partie 4 — Cas pratique n°1

---

## 🧵 Étape du fil rouge

> **Étape 3 — Incident : perte de données simulée.**
> Un incident est simulé sur la base NanoOrbit. L'équipe doit mettre en œuvre concrètement la stratégie définie en séance 4 et prouver qu'elle sait restaurer.

| | |
|---|---|
| État de la base **en entrée** | Stratégie de sauvegarde et PRA définis — sauvegardes non encore opérationnelles |
| État de la base **en sortie** | Base effectivement sauvegardée et restaurable ; capacité de restauration prouvée |
| Livrables produits | L3-A (scripts RMAN), L3-B (procédures de restauration), L3-C (compte rendu des tests) |

---

## 🎯 Objectifs pédagogiques

À l'issue de la séance, l'apprenant est capable de :

- **Mettre en œuvre** une stratégie de sauvegarde avec RMAN
- **Réaliser** une sauvegarde complète base arrêtée et une sauvegarde base ouverte
- **Exécuter** différents scénarios de restauration (complète, tablespace, point temporel)
- **Tester et documenter** la capacité à récupérer et réutiliser les données

> Cette séance met en œuvre le cas pratique n°1 du syllabus. L'énoncé complet est dans [`03-cas-pratiques/cp1-sauvegarde-restauration/enonce.md`](../../03-cas-pratiques/cp1-sauvegarde-restauration/enonce.md).

## 🗺️ Déroulé FOAD

La séance applique l'énoncé du cas pratique n°1. Elle est structurée en quatre temps.

### Temps 1 — Préparation et modèle de récupération (20 min)

Vérifier le mode de la base et activer l'archivelog mode si nécessaire (conformément à la stratégie définie en séance 4) :

```sql
SELECT log_mode FROM v$database;
-- Si NOARCHIVELOG, basculer en ARCHIVELOG
```

Comprendre le rôle du journal de transactions (redo logs) et des archive logs dans la capacité de restauration au point temporel.

### Temps 2 — Sauvegarde des données (40 min)

Mettre en œuvre les deux types de sauvegarde via RMAN :

- **Sauvegarde complète base arrêtée** (cohérente, base en mode MOUNT)
- **Sauvegarde base ouverte** (à chaud, nécessite l'archivelog mode)

```
RMAN> BACKUP DATABASE;
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;
```

**Production attendue** : scripts RMAN de sauvegarde commentés (livrable L3-A).

### Temps 3 — Scénarios de restauration (45 min)

Simuler des incidents et restaurer :

- **Restauration complète** avec ou sans archivage
- **Restauration de tablespace** : perte de `TBS_OPERATION`, restauration ciblée sans toucher au référentiel
- **Point de récupération temporel** : restauration à un instant précédant une insertion erronée dans `FENETRE_COM`

```
RMAN> RESTORE TABLESPACE tbs_operation;
RMAN> RECOVER TABLESPACE tbs_operation;
```

**Production attendue** : procédures de restauration documentées (livrable L3-B).

### Temps 4 — Tests de capacité à récupérer les données (15 min)

Pour chaque scénario : vérifier que les données restaurées sont cohérentes et réutilisables. Documenter le test, le résultat, le temps de restauration constaté (à comparer au RTO du contrat de services).

**Production attendue** : compte rendu des tests de restauration (livrable L3-C).

---

## 🎒 Supports à préparer

| Support | Format | Emplacement |
|---|---|---|
| Énoncé du cas pratique n°1 | Document | `../../03-cas-pratiques/cp1-sauvegarde-restauration/enonce.md` |
| Aide-mémoire RMAN | Cheatsheet | `ressources/cheatsheet-rman.md` |
| Corrigé (section instructeur) | Document | `../../03-cas-pratiques/cp1-sauvegarde-restauration/` (réservé) |

## ⚠️ Points de vigilance

**Environnement Oracle robuste indispensable** : la séance manipule la base en profondeur (arrêt, restauration). Prévoir une image de référence pour réinitialiser un environnement cassé.

**Sauvegarde base arrêtée = base en MOUNT** : erreur classique de tenter une sauvegarde cohérente base ouverte sans archivelog. Bien distinguer les deux modes.

**Comparer systématiquement au RTO du contrat** : la restauration ne se mesure pas qu'à son succès, mais aussi à son temps. C'est la posture d'administrateur.

**Correction du cas pratique** : prévoir un retour de correction avant la séance 6, pour que les apprenants abordent la supervision avec un cas pratique n°1 maîtrisé. La base de ce cas pratique sert d'environnement au cas pratique n°2.

## 📎 Livrables du fil rouge

| Réf. | Livrable | Contenu |
|---|---|---|
| L3-A | Scripts RMAN de sauvegarde | Sauvegarde complète + base ouverte, commentées |
| L3-B | Procédures de restauration | Restauration complète, tablespace, point temporel |
| L3-C | Compte rendu des tests | Tests, résultats, temps comparés au RTO |

## 📚 Ressources

- [Fil rouge NanoOrbit](../../00-cadrage/fil-rouge.md)
- [Cas pratique n°1 — énoncé complet](../../03-cas-pratiques/cp1-sauvegarde-restauration/enonce.md)
- [Contrat de services — RTO/RPO](../../00-cadrage/contrat-de-services.md)
- [Séance 6 — Supervision](../seance-6-supervision/README.md)

---

*Séance 5 — Module BDOE633 — Branche `academy`*
