#!/bin/bash

# Load identity config
CONFIG_FILE="$HOME/.gh-identities"
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  echo "❌ Missing config file: $CONFIG_FILE"
  echo "Create it and define your GitHub identities. See README for example."
  return 1 2>/dev/null || exit 1
fi

echo "Which GitHub identity do you want to use?"
select identity in "${identities[@]}" "Cancel"; do
  case "$identity" in
    Cancel)
      echo "❌ Aborted."
      return 1 2>/dev/null || exit 1
      ;;
    *)
      # Lookup variables dynamically
      name_var="${identity}_name"
      email_var="${identity}_email"
      user_var="${identity}_user"
      host_var="${identity}_host"

      name="${!name_var}"
      email="${!email_var}"
      gh_user="${!user_var}"
      host="${!host_var}"

      if [[ -z "$name" || -z "$email" || -z "$gh_user" || -z "$host" ]]; then
        echo "❌ Missing configuration for '$identity'. Check your ~/.gh-identities file."
        return 1 2>/dev/null || exit 1
      fi
      break
      ;;
  esac
done

git init
git config user.name "$name"
git config user.email "$email"
echo "Git configured for $identity ($email)"

# Use current directory name as default repo name
default_repo_name=$(basename "$PWD")

echo "Use '$default_repo_name' as your GitHub repo name?"
select yn in "Yes" "No"; do
  case $yn in
    Yes)
      repo_name="$default_repo_name"
      break
      ;;
    No)
      echo "Enter a custom repo name:"
      read repo_name
      break
      ;;
    *)
      echo "Invalid choice. Please choose Yes or No."
      ;;
  esac
done

git remote add origin git@$host:$gh_user/$repo_name.git
echo "Remote added: git@$host:$gh_user/$repo_name.git"

echo "Use 'main' as your branch name?"
select yn in "Yes" "No"; do
  case $yn in
    Yes)
      branch_name="main"
      break
      ;;
    No)
      echo "Enter a custom branch name:"
      read branch_name
      break
      ;;
    *)
      echo "Invalid choice. Please choose Yes or No."
      ;;
  esac
done

# Check if there are any commits before setting upstream
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git branch --set-upstream-to=origin/$branch_name
  echo "Upstream branch set to origin/$branch_name"
else
  echo "No commits yet. Use 'git push -u origin $branch_name' for your first push to set upstream."
fi

echo "🎉 Init complete!"
