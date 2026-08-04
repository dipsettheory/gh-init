# gh-init

A small CLI helper to initialize a Git repo using the correct GitHub identity (name, email, SSH remote) when working with multiple GitHub accounts.

This tool is ideal for developers who maintain multiple GitHub identities (e.g. personal and work) and want to avoid accidentally pushing with the wrong user/email.

---

## Installation

Clone the repo:

```bash
git clone https://github.com/your-username/gh-init.git
cd /path/to/gh-init
```

Install `gh-init` globally:

```bash
chmod +x gh-init.sh
sudo ln -s "$PWD/gh-init.sh" /usr/local/bin/gh-init
```

Now you can run it from anywhere:

```bash
gh-init
```

---

## Configure Your Identities

Create a file called `~/.gh-identities`:

```bash
vim ~/.gh-identities
```

Paste in your identities:

```bash
# ~/.gh-identities

# List of GitHub identities
identities=("alice" "bob")

alice_name="Alice"
alice_email="alice@email.com"
alice_user="alicelovesgithub"
alice_host="github.com-alicelovesgithub"

bob_name="Bob"
bob_email="bob@email.com"
bob_user="bobthedev"
bob_host="github.com-bobthedev"
```

You can define as many identities as you want. Just add them to the `identities=(...)` list and define the corresponding variables.

---

## SSH Host Configuration

Each identity’s `*_host` value should match a `Host` alias in your `~/.ssh/config`:

```ssh
# ~/.ssh/config

Host github.com-alicelovesgithub
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_alicelovesgithub
  AddKeysToAgent yes
  UseKeychain yes
```

If you don’t have a key yet, generate one:

```bash
ssh-keygen -t ed25519 -C "alice@email.com" -f ~/.ssh/id_ed25519_alicelovesgithub
```

Then add the public key (`~/.ssh/id_ed25519_alicelovesgithub.pub`) to your GitHub account under **SSH and GPG keys**.

---

## Usage

From the root of your new or existing project folder, run:

```bash
gh-init
```

It will:

1. Ask which identity to use
2. Set your Git name/email for the project
3. Suggest using the current folder name as your repo name
4. Add the correct Git remote using your SSH config
5. Ask which branch name to use (defaults to "main") and rename the branch to match
6. Set upstream tracking if the branch already exists on the remote, otherwise tell you how to create it

### Running against an existing repo

Re-running `gh-init` is how you move a project from one identity to another. It updates in place:

- the identity is rewritten with `git config`
- an existing `origin` is rewritten with `git remote set-url`, not left alone
- the current branch is renamed with `git branch -M`

Every git command is checked, so the script will not report a step it did not perform.

### About upstream tracking

`git branch --set-upstream-to=origin/<branch>` needs the **remote-tracking ref**, which exists only
after the branch is on the remote. Having local commits is not enough. So:

- **Branch exists on the remote:** the script fetches it and sets upstream.
- **Branch is not on the remote yet:** it tells you to run `git push -u origin <branch>`, which
  creates the branch and sets upstream in one step.
- **Remote unreachable, or the repo does not exist on GitHub yet:** it says so and gives you the
  same push command for once the remote is ready.

Note that `gh-init` never creates the repository on GitHub. Create it there first, or let your first
`git push` prompt you.

Example, on a repo that does not exist on GitHub yet:

```
Which GitHub identity do you want to use?
1) alice
2) bob
3) Cancel
#? 1

Git configured for alice (alice@email.com)
Use 'my-cool-repo' as your GitHub repo name?
1) Yes
2) No
#? 2
Enter a custom repo name:
> other-repo-name

Remote added: git@github.com-alicelovesgithub:alicelovesgithub/other-repo-name.git
Use 'main' as your branch name?
1) Yes
2) No
#? 1
Branch: main
Could not check origin (exit 128): the repo may not exist on
GitHub yet, or the host is unreachable.
Run 'git push -u origin main' once the remote is ready.
Init complete!
```

Switching an existing project to the other identity:

```
Git configured for bob (bob@email.com)
Remote updated: git@github.com-alicelovesgithub:alicelovesgithub/my-cool-repo.git -> git@github.com-bobthedev:bobthedev/my-cool-repo.git
Branch set to trunk (was main)
Init complete!
```

---

## Troubleshooting

### Pushing as the wrong account

Check what the remote actually resolves to, and who that authenticates as:

```bash
git remote -v
ssh -T git@github.com-alicelovesgithub    # → Hi alicelovesgithub!
```

If the remote host is a bare `github.com` rather than one of your `Host` aliases, SSH falls back to
the default key (`~/.ssh/id_ed25519`), so you authenticate as whichever account owns that key,
regardless of the name and email in `git config`. Identity and authentication are configured
separately: the email only labels the commit, the SSH key decides who GitHub thinks you are.

Re-running `gh-init` fixes the remote. To stop bare URLs reaching SSH at all, have Git rewrite them
per directory, alongside a conditional identity include in `~/.gitconfig`:

```ini
# ~/.gitconfig
[includeIf "gitdir:~/Code/alice/"]
  path = ~/.gitconfig-alice
```

```ini
# ~/.gitconfig-alice
[user]
  name = Alice
  email = alice@email.com

[url "git@github.com-alicelovesgithub:"]
  insteadOf = git@github.com:
```

Any repo cloned under that directory then lands on the right key even if you paste a bare
`github.com` URL.

---

## Privacy

Your identity data lives only in your private `~/.gh-identities` file. Never commit this file. If you ever copy it into a repo, add this to `.gitignore`:

```
.gh-identities
```

---

## License

MIT license. Free to use, modify, or fork.
