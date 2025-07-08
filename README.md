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

## 🗂️ Configure Your Identities

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

Example:

```
Which GitHub identity do you want to use?
1) alice
2) bob
3) Cancel

Git configured for alice (alice@email.com)
Use 'my-cool-repo' as your GitHub repo name?
1) Yes
2) No
Enter a custom repo name:
> other-repo-name

Remote added: git@github.com-alicelovesgithub:alicelovesgithub/other-repo-name.git
🎉 Init complete!
```

---

## Privacy

Your identity data lives only in your private `~/.gh-identities` file. Never commit this file. If you ever copy it into a repo, add this to `.gitignore`:

```
.gh-identities
```

---

## 📄 License

MIT license. Free to use, modify, or fork.
