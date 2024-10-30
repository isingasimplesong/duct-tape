#!/usr/bin/env bash

if [[ "$1" != "--public" && "$1" != "--private" ]]; then
    echo "Usage: $(basename "$0") --public | --private" >&2
    exit 1
fi

project_visibility=$1
project_name=$(basename "$(pwd)")
gitignore_source="$HOME/dotfiles/misc/gitignore"
license="$HOME/dotfiles/misc/license"

# Initialisation du dépôt git local
git init || {
    echo "Erreur lors de l'initialisation du dépôt git" >&2
    exit 1
}

# Configuration des fichiers de base
if [[ -f "$gitignore_source" ]]; then
    cat "$gitignore_source" >.gitignore
else
    echo "Erreur : le fichier .gitignore source est introuvable." >&2
    exit 1
fi

touch .env && echo "MY_ENV=$project_name" >>.env

echo "# $project_name" >README.md

if [[ -f "$license" ]]; then
    cat "$license" >LICENSE
else
    echo "Erreur : le fichier 'LICENSE' source est introuvable." >&2
    exit 1
fi

# Création du dépôt GitHub
if ! command -v gh &>/dev/null; then
    echo "Erreur : GitHub CLI (gh) n'est pas installé." >&2
    exit 1
fi

gh repo create "$project_name" "$project_visibility" --source=. --remote=origin || {
    echo "Erreur lors de la création du dépôt GitHub." >&2
    exit 1
}

git add . && git commit -m "initial commit" && git push --set-upstream origin main

echo "Le dépôt GitHub '$project_name' a été créé avec succès à l'adresse \
    https://github.com/isingasimplesong/$project_name"
