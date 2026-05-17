# Cas pratique n°1 — Sauvegarde et restauration de la base NanoOrbit

**Module** : BDOE633 · **Séance** : 5 (FOAD) · **Partie syllabus** : Partie 4 · **Modalité** : binômes

---

## 🧵 Place dans le fil rouge

> **Étape 3 — Incident : perte de données simulée.**
> Vous avez défini en séance 4 une stratégie de sauvegarde/restauration et un PRA. Il s'agit maintenant de les mettre en œuvre concrètement sur la base NanoOrbit et de prouver votre capacité à restaurer.

---

## 🎯 Contexte

NanoOrbit exploite sa base de production Oracle. La direction exige la preuve que l'équipe d'administration sait sauvegarder et restaurer la base conformément au contrat de services. Un incident est simulé pour le démontrer.

Vous travaillez sur l'environnement Oracle NanoOrbit (`NANOORBIT_ADMIN` sur `FREEPDB1`), dans l'état laissé par la séance 3 (stockage organisé en tablespaces par famille de données).

## 📋 Travail demandé

### 1. Définir une stratégie de sauvegarde/restauration

Reprenez et finalisez la stratégie définie en séance 4 (livrable L2-A). Elle doit être applicable sur l'environnement réel.

### 2. Concevoir la procédure de sauvegarde et de restauration

Précisez les cinq dimensions :

- **Type de sauvegarde** : complète, incrémentale, à chaud, à froid
- **Données à sauvegarder** : base entière, tablespaces, archive logs
- **Fréquence des sauvegardes** : conforme au RPO du contrat de services
- **Durée de conservation** : conforme aux engagements de rétention
- **Emplacement de stockage** : où sont stockées les sauvegardes

### 3. Présenter et expliquer les tests de capacité à récupérer les données

Pour chaque scénario de restauration, vous devez tester et documenter que les données restaurées sont cohérentes et réutilisables.

### 4. Mise en œuvre Oracle

Réalisez concrètement, avec RMAN, les opérations suivantes :

**Modèles de récupération**
- Vérifier et configurer le mode d'archivage (archivelog)
- Comprendre le rôle du journal de transactions dans la stratégie de sauvegarde

**Sauvegarde des données**
- Sauvegarde complète base arrêtée (base en mode MOUNT)
- Sauvegarde base ouverte (à chaud)

**Restauration des données**
- Scénarios de restauration
- Point de récupération temporel
- Restauration des bases de données systèmes et des fichiers individuels

**Restauration complète** avec ou sans archivage

**Restauration de tablespace**
- Simuler la perte de `TBS_OPERATION`
- Restaurer ce tablespace sans affecter le référentiel

## ✅ Livrables attendus

| Réf. | Livrable | Contenu |
|---|---|---|
| L3-A | Script RMAN de sauvegarde | Scripts commentés des sauvegardes complète et base ouverte |
| L3-B | Procédures de restauration | Restauration complète, de tablespace, point temporel — documentées |
| L3-C | Compte rendu des tests | Pour chaque scénario : démarche, résultat, temps de restauration comparé au RTO |

Tous les livrables sont versés au **dossier d'exploitation NanoOrbit**.

## 📐 Critères d'évaluation

| Critère | Pondération |
|---|---|
| Conformité de la stratégie au contrat de services | 25 % |
| Correction technique des scripts RMAN | 30 % |
| Réussite et documentation des scénarios de restauration | 30 % |
| Qualité du compte rendu des tests | 15 % |

## 💡 Conseils

- Une sauvegarde n'a de valeur que si la restauration fonctionne. **Testez toujours la restauration.**
- Mesurez le temps de chaque restauration et comparez-le au RTO du contrat de services. Une restauration qui dépasse le RTO est un échec, même si elle réussit.
- La restauration de tablespace est plus subtile que la restauration complète : c'est elle qui prouve la maîtrise.

## 📚 Référence

- [Contrat de services NanoOrbit](../../00-cadrage/contrat-de-services.md)
- [Séance 5 — déroulé détaillé](../../02-seances/seance-5-cas-pratique-backup/README.md)
- [Fil rouge NanoOrbit](../../00-cadrage/fil-rouge.md)

---

*Cas pratique n°1 — Module BDOE633 — Branche `academy`*
