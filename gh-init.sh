#!/bin/bash
#
# gh-init - initialize a Git repo with the correct GitHub identity and SSH
# remote when working with multiple GitHub accounts.
#
# Re-running against an existing repo updates the identity, remote and branch
# in place. Every git command is checked, so the script never reports a step it
# did not actually perform.
#
# The body lives in a function so that a failure can `return` cleanly whether
# the script is executed or sourced. `set -e` is deliberately not used: it would
# leak into the caller's shell when sourced.

gh_init_main() {
  local config_file="$HOME/.gh-identities"

  if [[ ! -f "$config_file" ]]; then
    echo "❌ Missing config file: $config_file" >&2
    echo "Create it and define your GitHub identities. See README for an example." >&2
    return 1
  fi

  # shellcheck source=/dev/null
  source "$config_file"

  if [[ ${#identities[@]} -eq 0 ]]; then
    echo "❌ No identities defined in $config_file." >&2
    return 1
  fi

  # --- identity -------------------------------------------------------------

  local identity
  echo "Which GitHub identity do you want to use?"
  select identity in "${identities[@]}" "Cancel"; do
    if [[ -z "$identity" ]]; then
      echo "Invalid choice. Pick a number from the list."
      continue
    fi
    if [[ "$identity" == "Cancel" ]]; then
      echo "❌ Aborted."
      return 1
    fi
    break
  done

  local name_var="${identity}_name"
  local email_var="${identity}_email"
  local user_var="${identity}_user"
  local host_var="${identity}_host"

  local name="${!name_var-}"
  local email="${!email_var-}"
  local gh_user="${!user_var-}"
  local host="${!host_var-}"

  if [[ -z "$name" || -z "$email" || -z "$gh_user" || -z "$host" ]]; then
    echo "❌ Missing configuration for '$identity'. Check $config_file." >&2
    return 1
  fi

  git init || return 1
  git config user.name "$name" || return 1
  git config user.email "$email" || return 1
  echo "Git configured for $identity ($email)"

  # --- repo name ------------------------------------------------------------

  local default_repo_name repo_name="" yn
  default_repo_name=$(basename "$PWD")

  echo "Use '$default_repo_name' as your GitHub repo name?"
  select yn in "Yes" "No"; do
    case "$yn" in
      Yes)
        repo_name="$default_repo_name"
        break
        ;;
      No)
        while [[ -z "$repo_name" ]]; do
          echo "Enter a custom repo name:"
          read -r repo_name
          [[ -z "$repo_name" ]] && echo "Repo name cannot be empty."
        done
        break
        ;;
      *)
        echo "Invalid choice. Please choose Yes or No."
        ;;
    esac
  done

  # --- remote ---------------------------------------------------------------
  # An existing origin is updated rather than left in place. `git remote add`
  # fails when origin exists, and swallowing that error is how a repo ends up
  # pointing at the wrong account while the script claims otherwise.

  local remote_url="git@$host:$gh_user/$repo_name.git"
  local existing_url

  if existing_url=$(git remote get-url origin 2>/dev/null); then
    if [[ "$existing_url" == "$remote_url" ]]; then
      echo "Remote already set: $remote_url"
    else
      git remote set-url origin "$remote_url" || return 1
      echo "Remote updated: $existing_url -> $remote_url"
    fi
  else
    git remote add origin "$remote_url" || return 1
    echo "Remote added: $remote_url"
  fi

  # --- branch ---------------------------------------------------------------

  local branch_name=""
  echo "Use 'main' as your branch name?"
  select yn in "Yes" "No"; do
    case "$yn" in
      Yes)
        branch_name="main"
        break
        ;;
      No)
        while [[ -z "$branch_name" ]]; do
          echo "Enter a custom branch name:"
          read -r branch_name
          [[ -z "$branch_name" ]] && echo "Branch name cannot be empty."
        done
        break
        ;;
      *)
        echo "Invalid choice. Please choose Yes or No."
        ;;
    esac
  done

  # The chosen name has to be applied. `git branch -M` handles both an unborn
  # HEAD (fresh repo, no commits) and a branch with history.
  local current_branch
  current_branch=$(git branch --show-current)
  if [[ "$current_branch" != "$branch_name" ]]; then
    git branch -M "$branch_name" || return 1
    echo "Branch set to $branch_name (was ${current_branch:-detached HEAD})"
  else
    echo "Branch: $branch_name"
  fi

  # --- upstream -------------------------------------------------------------
  # Upstream tracking needs the remote-tracking ref, not just a local commit,
  # so the branch must already exist on the remote. Otherwise the first push
  # is what creates it.

  local ls_status=0
  git ls-remote --exit-code --heads origin "$branch_name" >/dev/null 2>&1 || ls_status=$?

  if ((ls_status == 0)); then
    git fetch --quiet origin "$branch_name" || return 1
    git branch --set-upstream-to="origin/$branch_name" "$branch_name" || return 1
    echo "Upstream branch set to origin/$branch_name"
  elif ((ls_status == 2)); then
    echo "origin/$branch_name does not exist yet."
    echo "Run 'git push -u origin $branch_name' to create it and set upstream."
  else
    echo "Could not check origin (exit $ls_status): the repo may not exist on"
    echo "GitHub yet, or the host is unreachable."
    echo "Run 'git push -u origin $branch_name' once the remote is ready."
  fi

  echo "Init complete!"
}

gh_init_main "$@"
_gh_init_status=$?
return $_gh_init_status 2>/dev/null || exit $_gh_init_status
