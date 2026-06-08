# Séance 4 — Étape 1 : Où en est NanoOrbit ?

> **Module BDOE633 · Séance 4 · Temps 1 (10 min)**
> Classe virtuelle — pas de manipulation Oracle.

---

## Le chemin parcouru

```
Étape 0          Étape 1              Étape 2           Étape 3
Benchmark     Prise en main        ◄ VOUS ÊTES ICI ►    RMAN
SGBD          + stockage           Stratégie + PRA      (mise en œuvre)
   ✅              ✅                    🔲                  🔲

Étape 4          Étape 5
Supervision      Audit
   🔲              🔲
```

---

## Ce qui est acquis

Après les séances 2 et 3, la base NanoOrbit est dans cet état :

| Acquis | Détail |
|---|---|
| ✅ Base initialisée | 11 tables, 5 triggers, package `pkg_nanoOrbit`, 43 lignes de données |
| ✅ Outils en place | SQL*Plus / VS Code SQL Developer connectés à `FREEPDB1` |
| ✅ Stockage organisé | 3 tablespaces créés : `TBS_REFERENTIEL`, `TBS_OPERATION`, `TBS_HISTORIQUE` |
| ✅ Plan d'administration | Livrable L1-A rédigé — RPO/RTO/familles documentés |
| ✅ Cartographie | Livrable L1-B — état initial + cible + candidats indexation |

---

## Ce qui manque encore

La base est organisée. Mais si un incident survient **maintenant** :

- Un opérateur exécute par erreur `DELETE FROM FENETRE_COM` → **toutes les fenêtres planifiées sont perdues**
- Le serveur Docker tombe → **la base est inaccessible**
- Le fichier `tbs_operation.dbf` est corrompu → **les données opérationnelles sont perdues**

Dans les trois cas, **il n'existe aucune sauvegarde**. La restauration est impossible.

> Le contrat exige pourtant :
> - **RPO 15 min** sur l'Opérationnel — perte de données maximale acceptable
> - **RTO 30 min** sur l'Opérationnel — délai maximal de remise en service
> - **Disponibilité 99,5 %** — soit ≈ 50 min d'indisponibilité tolérée par semaine

Ces engagements sont aujourd'hui **non couverts**. C'est l'objet de cette séance.

---

## La question de la séance

> **Comment garantir que NanoOrbit pourra toujours être restaurée, dans les délais du contrat, quel que soit l'incident ?**

La réponse passe par deux livrables :

| Livrable | Contenu | Séance |
|---|---|---|
| **L2-A** | Stratégie de sauvegarde — ce qu'on sauvegarde, quand, où | Séance 4 (aujourd'hui) |
| **L2-B** | Plan de Reprise d'Activité — comment on restaure, en combien de temps | Séance 4 (aujourd'hui) |
| L3-A/B/C | Mise en œuvre RMAN + tests de restauration | Séance 5 (FOAD) |

---

*Séance 4 · Temps 1 · Module BDOE633*
