# Laptop

## Install developer tools
```bash
xcode-select --install
```

## Setup SSH key
- [Generate Key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [Add Key to GitHub Account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

## Git

Set Git user in `~/.gitconfig.local`:
```
[github]
  user = github_username
[user]
  name = Your Name
  email = email@example.com
```

## Install

Clone:

```bash
export LAPTOP="$HOME/laptop"
git clone git@github.com:LexBartnicki/laptop.git $LAPTOP
cd $LAPTOP
```

Review:

```
less laptop.sh
```

Run:

```
./laptop.sh
```
