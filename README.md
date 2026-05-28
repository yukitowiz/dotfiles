# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

This repository is designed to support both:

1. A fresh machine with no previous dotfiles.
2. An existing machine that already has locally customized dotfiles.

The goal is not to force every machine into an identical state immediately.
Instead, this repository provides a safe, testable, and incremental workflow for
bringing machines under chezmoi management while preserving useful local
differences.

---

## Design Principles

### 1. Incremental adoption

Existing dotfiles should be adopted step by step.

Instead of replacing the whole home directory at once, we:

- inspect the current state,
- add one file or directory at a time,
- compare differences,
- apply changes only after review.

This makes it possible to migrate an already customized environment without
losing local changes.

### 2. Testable dotfiles

Dotfiles are treated as code.

Before applying changes, we should be able to:

- render templates,
- inspect diffs,
- run dry-runs,
- validate shell scripts,
- test bootstrap behavior in CI where possible.

The default workflow should be:

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
```

Never apply blindly.

### 3. Cross-platform support

Different operating systems and machines may require different configuration.

This repository supports differences such as:

- macOS vs Linux,
- work machine vs personal machine,
- GUI environment vs headless server,
- host-specific paths,
- machine-specific secrets or tokens.

These differences should be expressed using chezmoi templates, data files, and
local configuration rather than uncontrolled manual edits.

---

## Repository Structure

A typical structure is:

```text
.
├── README.md
├── dot_config/
│   ├── git/
│   ├── zsh/
│   └── ...
├── dot_gitconfig.tmpl
├── dot_zshrc.tmpl
├── private_dot_ssh/
├── run_once_before_install-packages.sh.tmpl
├── run_once_after_setup.sh.tmpl
├── .chezmoiignore
└── .chezmoi.toml.tmpl
```

Common chezmoi naming rules:

| Source name | Destination path |
|---|---|
| `dot_zshrc` | `~/.zshrc` |
| `dot_config/git/config` | `~/.config/git/config` |
| `private_dot_ssh/config` | `~/.ssh/config` |
| `executable_dot_local/bin/foo` | `~/.local/bin/foo` |
| `dot_gitconfig.tmpl` | `~/.gitconfig`, rendered from template |

---

## Initial Setup on a Fresh Machine

### 1. Install chezmoi

macOS:

```sh
brew install chezmoi
```

Linux:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)"
```

Or follow the official installation guide:

```sh
chezmoi --version
```

### 2. Initialize this repository

```sh
chezmoi init <GITHUB_USER_OR_REPOSITORY>
```

Example:

```sh
chezmoi init git@github.com:<USER>/dotfiles.git
```

### 3. Inspect before applying

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
```

### 4. Apply

```sh
chezmoi apply
```

### 5. Verify

```sh
chezmoi status
```

If there is no unexpected output, the machine is now managed by chezmoi.

---

## Setup on an Existing Customized Machine

Use this workflow if the machine already has custom files such as:

- `~/.zshrc`
- `~/.bashrc`
- `~/.gitconfig`
- `~/.config/nvim`
- `~/.ssh/config`

The key rule is:

> Do not overwrite existing dotfiles immediately. First inspect, then adopt.

### 1. Initialize chezmoi without applying blindly

```sh
chezmoi init <GITHUB_USER_OR_REPOSITORY>
```

Then inspect what would change:

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
```

If the diff looks unsafe, do not run `chezmoi apply` yet.

### 2. Add one existing file at a time

For example, to adopt the current `~/.zshrc`:

```sh
chezmoi add ~/.zshrc
```

Check the source state:

```sh
chezmoi cd
```

Then inspect the generated file, for example:

```sh
ls
cat dot_zshrc
```

Commit the change:

```sh
git status
git add dot_zshrc
git commit -m "Add zshrc"
```

### 3. Repeat for important files

Examples:

```sh
chezmoi add ~/.gitconfig
chezmoi add ~/.config/nvim
chezmoi add ~/.ssh/config
```

After each addition:

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
git status
```

Commit small logical changes.

### 4. Re-add files after local edits

If you edit the real file directly, update chezmoi's source state with:

```sh
chezmoi re-add ~/.zshrc
```

Or add a specific file again:

```sh
chezmoi add ~/.zshrc
```

Then review:

```sh
chezmoi diff
git diff
```

### 5. Merge when both sides changed

If both the chezmoi source state and the local destination file have changed,
use:

```sh
chezmoi merge ~/.zshrc
```

Then review and commit the result.

---

## Recommended Step-by-Step Migration Plan

### Phase 1: Low-risk files

Start with files that are easy to review:

```sh
chezmoi add ~/.gitconfig
chezmoi add ~/.gitignore_global
chezmoi add ~/.editorconfig
```

Review and commit.

### Phase 2: Shell configuration

Adopt shell files carefully:

```sh
chezmoi add ~/.zshrc
chezmoi add ~/.zprofile
chezmoi add ~/.bashrc
```

Avoid putting machine-specific logic directly into these files.
Prefer templates and OS-specific conditions.

### Phase 3: Application configuration

Adopt application config directories:

```sh
chezmoi add ~/.config/nvim
chezmoi add ~/.config/starship.toml
chezmoi add ~/.config/alacritty
```

If a directory contains cache files, logs, plugins, or generated files, exclude
them with `.chezmoiignore`.

### Phase 4: Scripts

Adopt personal scripts:

```sh
chezmoi add ~/.local/bin
```

Executable files should use chezmoi's `executable_` prefix when appropriate.

### Phase 5: Sensitive files

Be careful with secrets.

Do not commit plain-text credentials, private keys, or tokens.

For sensitive files, consider:

- chezmoi encryption support,
- password managers,
- environment variables,
- host-local configuration outside the repository.

---

## Handling OS Differences

Use templates for files that differ by OS.

Example: `dot_zshrc.tmpl`

```gotemplate
# Common configuration
export EDITOR="nvim"

{{ if eq .chezmoi.os "darwin" }}
# macOS-specific configuration
export PATH="/opt/homebrew/bin:$PATH"
{{ end }}

{{ if eq .chezmoi.os "linux" }}
# Linux-specific configuration
export PATH="$HOME/.local/bin:$PATH"
{{ end }}
```

Supported values include:

```gotemplate
{{ .chezmoi.os }}
{{ .chezmoi.arch }}
{{ .chezmoi.hostname }}
{{ .chezmoi.username }}
{{ .chezmoi.homeDir }}
```

Example:

```gotemplate
{{ if eq .chezmoi.os "darwin" }}
# macOS
{{ else if eq .chezmoi.os "linux" }}
# Linux
{{ end }}
```

---

## Handling Machine-Specific Differences

Some settings should depend on the machine, not only on the OS.

Examples:

- work email vs personal email,
- corporate proxy,
- local project paths,
- GPU availability,
- GUI vs server environment.

Use local chezmoi config:

```toml
[data]
machine_type = "work"
git_email = "your.name@example.com"
```

Then use it in a template:

```gotemplate
[user]
    name = Your Name
    email = {{ .git_email }}

{{ if eq .machine_type "work" }}
[include]
    path = ~/.gitconfig-work
{{ end }}
```

Do not commit private machine-specific values if they should remain local.

---

## Example: Git Configuration

`dot_gitconfig.tmpl`

```gotemplate
[user]
    name = {{ .name | quote }}
    email = {{ .email | quote }}

[init]
    defaultBranch = main

[pull]
    rebase = false

[core]
    editor = nvim

{{ if eq .chezmoi.os "darwin" }}
[credential]
    helper = osxkeychain
{{ end }}

{{ if eq .chezmoi.os "linux" }}
[credential]
    helper = store
{{ end }}
```

Local data can be configured per machine.

Example:

```toml
[data]
name = "Your Name"
email = "your.email@example.com"
```

---

## Editing Managed Files

There are several safe ways to edit files.

### Edit source state directly

```sh
chezmoi cd
$EDITOR .
```

Then:

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
```

### Edit with chezmoi

```sh
chezmoi edit ~/.zshrc
```

Apply after editing:

```sh
chezmoi apply ~/.zshrc
```

Or edit and apply automatically:

```sh
chezmoi edit --apply ~/.zshrc
```

### Edit destination first, then re-add

If you edited the real file:

```sh
$EDITOR ~/.zshrc
chezmoi re-add ~/.zshrc
```

Then review and commit.

---

## Ignore Generated or Local-Only Files

Use `.chezmoiignore` for files that should exist in the source repository but
should not be applied to the destination.

Example `.chezmoiignore`:

```text
README.md
docs/
tests/
```

For application directories, avoid tracking generated files such as:

```text
.cache/
node_modules/
.DS_Store
*.log
```

---

## Dry Run and Review Workflow

Before applying changes:

```sh
chezmoi status
chezmoi diff
chezmoi apply --dry-run --verbose
```

Apply only after confirming the diff:

```sh
chezmoi apply
```

After applying:

```sh
chezmoi status
```

---

## Testing

Dotfiles should be tested as much as practical.

### Render templates

```sh
chezmoi execute-template < dot_zshrc.tmpl
```

### Check shell scripts

```sh
shellcheck run_once_before_install-packages.sh.tmpl
```

If templates contain Go template syntax, render them first before passing to
shellcheck.

Example:

```sh
chezmoi execute-template < run_once_before_install-packages.sh.tmpl | shellcheck -
```

### Test apply behavior

```sh
chezmoi apply --dry-run --verbose
```

### Optional CI strategy

A CI workflow may run checks on multiple operating systems:

- Ubuntu
- macOS

Possible checks:

```sh
chezmoi init --source=. --destination="$HOME"
chezmoi diff
chezmoi apply --dry-run --verbose
```

The goal of CI is not to perfectly reproduce every personal machine.
The goal is to catch obvious template errors, invalid scripts, and unsafe
assumptions.

---

## Bootstrap Scripts

chezmoi supports scripts such as:

```text
run_once_before_install-packages.sh.tmpl
run_once_after_setup.sh.tmpl
```

Use bootstrap scripts carefully.

Recommended rules:

1. Scripts must be idempotent.
2. Scripts should check before installing or modifying anything.
3. Scripts should be OS-aware.
4. Scripts should not require secrets.
5. Scripts should be safe to run multiple times.

Example:

```sh
#!/bin/sh

set -eu

if command -v brew >/dev/null 2>&1; then
  echo "Homebrew already installed"
else
  echo "Homebrew is not installed"
fi
```

---

## Daily Workflow

### Pull latest dotfiles

```sh
chezmoi update
```

### Check local changes

```sh
chezmoi status
chezmoi diff
```

### Apply

```sh
chezmoi apply
```

### Add a new file

```sh
chezmoi add ~/.config/example/config.toml
git add .
git commit -m "Add example config"
```

### Update source after manual local changes

```sh
chezmoi re-add ~/.config/example/config.toml
git diff
git commit -am "Update example config"
```

---

## Conflict Resolution Policy

When there is a conflict between the repository and the local machine:

1. Do not apply immediately.
2. Run:

```sh
chezmoi diff
```

3. If needed, merge:

```sh
chezmoi merge <file>
```

4. Prefer extracting machine-specific differences into templates or local data.
5. Commit only reusable configuration.
6. Keep private or temporary local changes out of the repository.

---

## What Should Be Managed?

Good candidates:

- shell config
- git config
- editor config
- terminal config
- useful scripts
- language tool config
- package manager config

Be careful with:

- SSH private keys
- API tokens
- credentials
- large generated files
- caches
- machine-generated application state
- corporate confidential files

---

## New Machine Checklist

```sh
# 1. Install chezmoi
chezmoi --version

# 2. Initialize repository
chezmoi init <GITHUB_USER_OR_REPOSITORY>

# 3. Review
chezmoi diff
chezmoi apply --dry-run --verbose

# 4. Apply
chezmoi apply

# 5. Verify
chezmoi status
```

---

## Existing Machine Migration Checklist

```sh
# 1. Initialize
chezmoi init <GITHUB_USER_OR_REPOSITORY>

# 2. Inspect before applying
chezmoi diff
chezmoi apply --dry-run --verbose

# 3. Adopt files incrementally
chezmoi add ~/.gitconfig
chezmoi add ~/.zshrc
chezmoi add ~/.config/nvim

# 4. Review source state
chezmoi cd
git status
git diff

# 5. Commit small changes
git add .
git commit -m "Adopt existing dotfiles"

# 6. Apply only after review
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
```

## Task Runner

This repository uses [Task](https://taskfile.dev/) instead of Makefile or custom
shell wrappers.

Task is a cross-platform task runner written in Go. It uses a readable YAML file
and works on macOS, Linux, and Windows.

Common commands:

```sh
task
task diff
task dry-run
task apply
task update
task status
task doctor
task render
task test
task inventory
```

### Install Task

macOS:

```sh
brew install go-task/tap/go-task
```

Windows:

```powershell
winget install Task.Task
```

or:

```powershell
scoop install task
```

Linux:

```sh
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin
```

## Managed Applications

This repository may manage configuration for:

- Git
- Zsh
- Neovim
- Ghostty
- Alacritty
- WezTerm
- Karabiner-Elements
- VS Code
- SSH config

Not every machine needs every application. OS-specific and machine-specific
differences are handled through chezmoi templates and local data.

## Secrets Policy

Secrets must not be committed to this repository.

Do not commit:

- SSH private keys
- API tokens
- passwords
- company confidential hostnames or credentials
- machine-local private paths

Use one of the following instead:

- `~/.zshrc.local`
- `~/.ssh/config.local`
- environment variables
- password managers
- 1Password CLI, pass, gopass, or another secret manager

`~/.ssh/config` may be managed by chezmoi, but private keys must not be managed.


## Machine Types

Each machine has a `machine_type` configured in chezmoi local data.

Supported values:

- `personal`
- `work`
- `server`

Example:

```toml
[data]
machine_type = "work"

Templates can use this value:
{{ if eq .machine_type "work" }}
# work-specific config
{{ end }}
```

## Existing Machine Adoption Order

For an existing customized machine, adopt files gradually.

Recommended order:

1. Basic Git/editor files
   - `~/.gitconfig`
   - `~/.config/git/ignore`
   - `~/.editorconfig`

2. Shell files
   - `~/.zshrc`
   - `~/.zprofile`

3. Terminal configs
   - `~/.config/ghostty`
   - `~/.config/alacritty`
   - `~/.config/wezterm`

4. Editor configs
   - `~/.config/nvim`
   - VS Code `settings.json`

5. SSH config
   - `~/.ssh/config`

6. OS-specific configs
   - `~/.config/karabiner/karabiner.json`

7. Personal scripts
   - `~/.local/bin`

Always review before applying:

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
```

## Existing Machine Adoption Workflow

For an existing customized machine, do not apply immediately.

First inspect the current state:

```sh
task inventory
task diff
task dry-run
```

Then adopt files gradually.

Recommended order:

1. Basic Git/editor files

```sh
chezmoi add ~/.gitconfig
chezmoi add ~/.config/git/ignore
chezmoi add ~/.editorconfig
```

2. Shell files

```sh
chezmoi add ~/.zshrc
chezmoi add ~/.zprofile
```

3. Terminal configs

```sh
chezmoi add ~/.config/ghostty
chezmoi add ~/.config/alacritty
chezmoi add ~/.config/wezterm
```

4. Editor configs

```sh
chezmoi add ~/.config/nvim
chezmoi add ~/.config/Code/User/settings.json
```

5. SSH config

```sh
chezmoi add ~/.ssh/config
```

6. macOS-specific config

```sh
chezmoi add ~/.config/karabiner/karabiner.json
```

7. Personal scripts

```sh
chezmoi add ~/.local/bin
```

Always review before applying:

```sh
task diff
task dry-run
```

Apply only after confirming the diff:

```sh
task apply
```

## Neovim Configuration Policy

Neovim Lua files are kept as normal Lua files whenever possible.

For example:

```text
dot_config/nvim/init.lua
dot_config/nvim/lua/user/options.lua
dot_config/nvim/lua/user/keymaps.lua
```

These files are not written as `.tmpl` files so that Lua tooling continues to work:

- Lua language server
- stylua
- Neovim diagnostics
- syntax highlighting

When chezmoi-specific values are needed, generate a small Lua module instead:

```text
dot_config/nvim/lua/user/chezmoi.lua.tmpl
```

This file renders to:

```text
~/.config/nvim/lua/user/chezmoi.lua
```

and can expose non-secret machine data such as:

- OS
- architecture
- hostname
- machine type

Machine-local or secret Neovim configuration should not be committed.
Use a local-only file such as:

```text
~/.config/nvim/lua/user/local.lua
```

## References

- [chezmoi Usage FAQ](https://chezmoi.io/user-guide/frequently-asked-questions/usage)
- [Manage machine-to-machine differences - chezmoi](https://chezmoi.io/user-guide/manage-machine-to-machine-differences)
- [Dotfiles with Chezmoi - Medium](https://medium.com/@sssanjaya/dotfiles-with-chezmoi-4b5a3b503f36)
- [Managing dotfiles with Chezmoi | Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi)
- [Managing Dotfiles With Chezmoi | Budiman JoJo](https://budimanjojo.com/2021/12/13/managing-dotfiles-with-chezmoi)
- [Testable dotfiles management with chezmoi](https://zenn.dev/shunk031/articles/testable-dotfiles-management-with-chezmoi)
```
