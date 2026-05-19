# Guide de démarrage — Environnement NanoOrbit

> Procédure pas à pas pour lancer la base de données NanoOrbit dans Docker, **dans le bon ordre**.
> Ce guide complète le [README de l'environnement](README.md).

---

## 0. Prérequis

- Docker et Docker Compose installés et démarrés
- Le dépôt cloné sur le poste
- Un terminal ouvert **dans le dossier `01-environnement/`**

```bash
cd chemin/vers/epsi-admin-bdd/01-environnement
```

> 🪟 **Windows / Git Bash uniquement.** Git Bash réécrit les chemins Unix (`/nanoorbit` devient `C:/Program Files/Git/nanoorbit`), ce qui casse les commandes internes au conteneur. Tapez une fois cette commande au début de votre session :
>
> ```bash
> export MSYS_NO_PATHCONV=1
> ```
>
> Toutes les commandes du guide fonctionneront alors telles quelles. Sur macOS / Linux, ignorez cette note.

---

## 1. Démarrer le conteneur Oracle

```bash
docker compose up -d
```

Cette commande télécharge l'image Oracle (au premier lancement seulement) et démarre l'instance.

## 2. Attendre que la base soit prête

Le premier démarrage prend **plusieurs minutes** (création de la base Oracle). Suivez les logs :

```bash
docker compose logs -f
```

Attendez d'apparaître le message :

```
#########################
DATABASE IS READY TO USE!
#########################
```

Quittez le suivi des logs avec `Ctrl+C` (cela n'arrête pas le conteneur).

Vérifiez l'état :

```bash
docker compose ps
```

La colonne `STATUS` doit indiquer `healthy`.

## 3. Lancer l'initialisation de la base NanoOrbit

C'est l'étape qui crée le schéma, les tables, les données, les triggers et le package. On lance l'orchestrateur **manuellement** : c'est la méthode la plus fiable.

```bash
docker exec nanoorbit-oracle bash -c "bash /nanoorbit/init-nanoorbit.sh > /nanoorbit/init.log 2>&1"
```

> ℹ️ La sortie est redirigée dans un fichier `init.log`. C'est volontaire : sous Windows, l'affichage en temps réel se fige parfois alors que le script travaille normalement. Écrire dans un fichier évite toute ambiguïté.

L'orchestrateur enchaîne 6 étapes (schéma → tables → données → triggers → package → vérification). Patientez 1 à 3 minutes que l'invite `$` revienne.

## 4. Vérifier que l'initialisation a réussi

Affichez la fin du journal d'initialisation :

```bash
docker exec nanoorbit-oracle tail -40 /nanoorbit/init.log
```

Vous devez lire le bilan suivant :

```
BILAN DE VERIFICATION
------------------------------------------------------------
  Tables             : 11   (attendu : 11)
  Triggers           : 5    (attendu : 5)
  Package SPEC+BODY  : 2    (attendu : 2)
  Lignes (10 tables) : 43   (attendu : 43)
  Objets invalides   : 0    (attendu : 0)
------------------------------------------------------------
RESULTAT : environnement NanoOrbit CONFORME.
```

> ⚠️ Quelques messages `SP2-0734` peuvent apparaître plus haut dans le journal : ils sont **sans conséquence** (détail d'affichage de SQL*Plus). Seul le bilan « CONFORME » fait foi.

Si le bilan indique une anomalie, voir la section **Dépannage** en bas de ce guide.

## 5. Se connecter à la base

```bash
docker exec -it nanoorbit-oracle sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1
```

Vous obtenez l'invite `SQL>`. La base est prête à l'emploi.

Premières vérifications dans SQL*Plus :

```sql
SET LINESIZE 150
SET PAGESIZE 50
SELECT table_name FROM user_tables ORDER BY table_name;
SELECT * FROM orbite;
```

Pour quitter SQL*Plus : `EXIT;`

---

## 🔄 Cycle de vie courant

| Action | Commande |
|---|---|
| Démarrer l'instance | `docker compose up -d` |
| Arrêter (en conservant les données) | `docker compose stop` |
| Redémarrer | `docker compose start` |
| Se connecter à la base | `docker exec -it nanoorbit-oracle sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1` |
| Voir l'état du conteneur | `docker compose ps` |

> Une fois la base initialisée (étape 3), il **ne faut pas relancer l'init** à chaque démarrage : les données persistent. L'étape 3 ne se refait que pour repartir d'une base neuve.

---

## 🧹 Réinitialiser complètement la base

Pour effacer toutes les données et repartir de zéro :

```bash
docker compose down -v
docker compose up -d
```

Attendez « DATABASE IS READY TO USE! » (étape 2), puis refaites l'étape 3.

> `down -v` supprime le volume `nanoorbit-data` : **tout le travail enregistré dans la base est perdu**. À n'utiliser que pour une remise à zéro volontaire.

---

## 🛠️ Dépannage

### `ORA-01017: invalid credential`
Le schéma `NANOORBIT_ADMIN` n'existe pas encore : l'initialisation (étape 3) n'a pas été faite ou a échoué. Relancez l'étape 3 et vérifiez le bilan (étape 4).

### `No such file or directory` sur un chemin `/nanoorbit`
Git Bash a réécrit le chemin. Vérifiez que `export MSYS_NO_PATHCONV=1` a bien été tapé dans la session (voir étape 0).

### Le bilan n'affiche pas « CONFORME »
Lisez le journal complet pour repérer l'erreur :

```bash
docker exec nanoorbit-oracle cat /nanoorbit/init.log
```

Cherchez les lignes commençant par `ORA-`. Si les fichiers `.sql` ont été enregistrés avec des fins de ligne Windows (CRLF), corrigez-les puis relancez l'étape 3 :

```bash
docker exec nanoorbit-oracle bash -c "cd /nanoorbit && sed -i 's/\r$//' init/*.sql verification.sql init-nanoorbit.sh"
```

### Le conteneur ne démarre pas / `unhealthy`
Vérifiez les logs : `docker compose logs --tail=50`. Le premier démarrage est long ; laissez plusieurs minutes avant de conclure à un échec.

---

## 📋 Récapitulatif — la séquence complète

```bash
# 0. Se placer dans le dossier (+ Windows : export MSYS_NO_PATHCONV=1)
cd epsi-admin-bdd/01-environnement
export MSYS_NO_PATHCONV=1        # Windows / Git Bash uniquement

# 1. Démarrer le conteneur
docker compose up -d

# 2. Attendre « DATABASE IS READY TO USE! »
docker compose logs -f           # Ctrl+C une fois le message affiché

# 3. Initialiser la base NanoOrbit
docker exec nanoorbit-oracle bash -c "bash /nanoorbit/init-nanoorbit.sh > /nanoorbit/init.log 2>&1"

# 4. Vérifier le bilan « CONFORME »
docker exec nanoorbit-oracle tail -40 /nanoorbit/init.log

# 5. Se connecter
docker exec -it nanoorbit-oracle sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1
```

---

*Guide de démarrage — Module BDOE633 — Branche `academy`*
