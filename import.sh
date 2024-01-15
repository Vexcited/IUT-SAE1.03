#!/bin/bash

if (( $# != 1 )); then
	echo "Erreur: Ce script doit prendre qu'un seul argument: le fichier des utilisateurs."
	exit 1
fi

if [ ! -f "$1" ]; then
	echo "Erreur: $1 n'est pas un fichier valide."
	exit 2
fi

# Si les fichiers de sortie existent déjà, on les supprime.
rm -f users_pass_tmp.txt a1.txt a2.txt a3.txt
# On crée les fichiers.
touch a1.txt a2.txt a3.txt

# Dans chaque ligne du fichier, on récupère les informations.
while read line; do
  # On ne traite pas les lignes vides.
  if [ -z "$line" ]; then
    continue
  fi

	nom=$(echo "$line" | cut -d":" -f1)
	prenom=$(echo "$line" | cut -d":" -f2)
	annee=$(echo "$line" | cut -d":" -f3)
	numero_tel=$(echo "$line" | cut -d":" -f4)
	date_naissance=$(echo "$line" | cut -d":" -f5)
	jour_naissance=$(echo $date_naissance | cut -d"/" -f1)
	jour_naissance=$(echo $jour_naissance | sed 's/^0//')
  mois_naissance=$(echo $date_naissance | cut -d"/" -f2)
	mois_naissance=$(echo $mois_naissance | sed 's/^0//')
	annee_naissance=$(echo $date_naissance | cut -d"/" -f3)

  # On récupère le mot du mois de naissance (en minuscule)
  # On utilise la commande "date" pour convertir le mois en mot.
  # +"%B" est le format qu'on utilise pour récupérer le nom entier du mois uniquement. 
  # On utilise -d pour spécifier la date.
  mot_mois=$(date -d "$annee_naissance/$mois_naissance/$jour_naissance" +"%B" | tr "[A-Z]" "[a-z]")

  # On vérifie le format de la ligne courante.
  if   [ -z "$nom" ] \
    || [ -z "$prenom" ] \
    || [ -z "$annee" ] \
    || [ -z "$numero_tel" ] \
    || [ -z "$date_naissance" ] \
    || [ -z "$jour_naissance" ] \
    || [ -z "$mois_naissance" ] \
    || [ -z "$annee_naissance" ] \
    || [[ $annee -lt 1 || $annee -gt 3 ]] \
    || [[ $jour_naissance -lt 1 || $jour_naissance -gt 31 ]] \
    || [[ $mois_naissance -lt 1 || $mois_naissance -gt 12 ]];
  then
    echo "Erreur: Le format du fichier fourni est invalide."
    # On supprime les fichiers crées, car ils peuvent contenir des informations erronées.
    rm -f users_pass_tmp.txt a1.txt a2.txt a3.txt
    exit 3
  fi

  # Génération du nom d'utilisateur.
  # --------------------------------

  # On enlève les espaces en double dans le nom de famille.
  nom="$(echo $nom | tr -s ' ')"

  # Le login est constitué de la première lettre du prénom suivi
  # du caractère _ et du nom de famille.
	username=$(echo $prenom | cut -c 1)_$nom

  # On convertit les accents en caractères ASCII.
  # https://unix.stackexchange.com/a/171902
  username=$(echo "$username" | iconv -f utf8 -t ascii//TRANSLIT)

  # On convertit les caractères qui peuvent poser problème
  # https://serverfault.com/q/73084
  # On ajoute `\n` pour éviter de supprimer le caractère de fin de ligne.
  username=$(echo "$username" | tr -cd '^[a-zA-Z][-a-zA-Z0-9]*\\n')

  # Génération du mot de passe.
  # ---------------------------

  # 1. Lettre du nom au hasard en majuscule.
	lettre_nom=$(echo $nom | fold -w1 | shuf -n1 | tr "[a-z]" "[A-Z]")
	# 2. Lettre du prénom au hasard en minuscule.
  lettre_prenom=$(echo $nom | fold -w1 | shuf -n1 | tr "[A-Z]" "[a-z]")
	# 3. 3ème chiffre du numéro de téléphone.
  chiffre_tel=$(echo $numero_tel | cut -c 3)
  # 4. Un caractère spécial au hasard. 
  caractere_special=$(echo "$%*:;.,?#|@+*/()[]{}_-=&!" | fold -w1 | shuf -n1)
  # 5. Première lettre du mois de naissance en minuscule.
  lettre_mois=$(echo $mot_mois | cut -c 1)

  password="$lettre_nom$lettre_prenom$chiffre_tel$caractere_special$lettre_mois"

  # Création de l'utilisateur.
  # --------------------------

  # On assigne le shell par défaut sur /bin/bash
	sudo useradd -g a$annee -s /bin/bash --create-home --home "/home/$username" $username

  # On vérifie le code de retour de "useradd".
  if (( $? != 0 )); then
		echo "Erreur: Survenue lors de la création de l'utilisateur $username"
		exit 4
	fi

  userinfo=$nom:$prenom:$username:$password
  echo $userinfo >> a$annee.txt

  chuser=$username:$password
  # On assigne le nom d'utilisateur et le mot de passe de l'utilisateur dans `users_pass_tmp.txt`
  echo $chuser >> users_pass_tmp.txt

  # Configuration de Visual Studio Code
  # -----------------------------------

  # On crée le dossier de configuration.
  sudo mkdir -p /home/$username/.config/Code/User
  # On copie le fichier
  sudo cp $HOME/.config/Code/User/settings.json /home/$username/.config/Code/User/settings.json

  # On copie les extensions
  sudo mkdir -p /home/$username/.vscode/extensions
  sudo cp -r $HOME/.vscode/extensions /home/$username/.vscode/extensions
done < "$1"

# Une fois l'opération terminé, on va utiliser `chpasswd` et le fichier
# `users_pass_tmp.txt` pour assigner le mot de pass de tout les utilisateurs.
sudo chpasswd < users_pass_tmp.txt
# On supprime le fichier temporaire
rm -f users_pass_tmp.txt

echo "Opération terminé avec succès."
echo "Les utilisateurs sont dans les fichiers a1.txt a2.txt et a3.txt"
