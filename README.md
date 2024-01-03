# SAE1.03

## Usage

```bash
chmod +x ./import.sh # Si nécessaire
./import.sh <fichier_données>
```

### Format du fichier des données attendu

Un exemple de fichier est disponible dans [`input.txt`](./input.txt).

```plain
nom:prénom:année:numéro_téléphone:date_naissance
```

Avec `date_naissance` sous le format `JJ/MM/AAAA`.

## Code retours

- `0` : OK
- `1` : Erreur d'argument, nombre d'arguments incorrect. Seulement le fichier des données est attendu.
- `2` : Erreur d'argument, le fichier des données n'existe pas ou n'est pas accessible.
- `3` : Erreur d'argument, le fichier des données n'est pas valide.
