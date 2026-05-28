# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

This repository supports both:

1. Fresh machines with no previous dotfiles.
2. Existing machines that already have locally customized dotfiles.

The goal is not to force every machine into an identical state immediately.
Instead, this repository provides a safe, testable, and incremental workflow for
bringing machines under chezmoi management while preserving useful local
differences.

---

## Quick Start

### Install chezmoi

macOS:

```sh
brew install chezmoi
```

Linux:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin
```

Windows:

```powershell
winget install twpayne.chezmoi
```

Verify:

```sh
chezmoi --version
```

### Install Task

This repository uses [Task](https://taskfile.dev/) instead of Makefile or custom
shell wrappers.

macOS:

```sh
brew install go-task/tap/go-task
```

Linux:

```sh
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin
```

Windows:

```powershell
winget install Task.Task
```

or:

```powershell
scoop install task
```

Verify:

```sh
task --version
```

---


## Fresh Machine Setup

Install chezmoi and Task first.

Then initialize this repository:

```sh
chezmoi init <GITHUB_USER_OR_REPOSITORY>
```

Example:

```sh
chezmoi init git@github.com:<USER>/dotfiles.git
```

Move to the chezmoi source directory:

```sh
cd "$(chezmoi source-path)"
```

On Windows PowerShell:

```powershell
Set-Location (chezmoi source-path)
```

Inspect before applying:

```sh
task diff
task dry-run
```

Apply only after reviewing the diff:

```sh
task apply
```

---

## Where to Run Task

`Taskfile.yml` lives in the chezmoi source directory, not in `$HOME`.

After running:

```sh
chezmoi init <GITHUB_USER_OR_REPOSITORY>
```

the repository is cloned into the chezmoi source directory.

Check the path with:

```sh
chezmoi source-path
```

Move there before running Task:

```sh
cd "$(chezmoi source-path)"
task diff
task dry-run
task apply
```

On Windows PowerShell:

```powershell
Set-Location (chezmoi source-path)
task diff
task dry-run
task apply
```

Alternatively, run Task with an explicit directory:

```sh
task -d "$(chezmoi source-path)" diff
```

---

## Existing Machine Setup

For an existing customized machine, do not apply immediately.

First inspect the current state:

```sh
task inventory
task diff
task dry-run
```

Then adopt files gradually.

The default rule is:

> Inspect first. Add one file at a time. Review before applying.

---

## Priority: SSH Config Adoption

SSH config is intentionally prioritized because it is often needed early when
setting up a new development environment.

This repository may manage:

```text
~/.ssh/config
```

This repository must not manage:

```text
~/.ssh/id_*
~/.ssh/*.pem
~/.ssh/*.key
private keys
passwords
tokens
```

To adopt an existing SSH config:

```sh
chezmoi add ~/.ssh/config
chezmoi cd
git diff
```

The source file will typically be:

```text
private_dot_ssh/config
```

If OS-specific or machine-specific differences are needed, convert it to:

```text
private_dot_ssh/config.tmpl
```

Recommended policy:

- Manage reusable SSH host entries.
- Manage `IdentityFile` paths, but not private keys.
- Move confidential work-only settings to `~/.ssh/config.local`.
- Keep `~/.ssh/config.local` outside this repository.
- Do not commit private hostnames if they are confidential.

Example:

```sshconfig
# Managed by chezmoi
# Do not put private keys, passwords, tokens, or confidential host information here.

Host *
  AddKeysToAgent yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
  IdentitiesOnly yes

{{ if eq .chezmoi.os "darwin" }}
Host *
  UseKeychain yes
{{ end }}

{{ if eq .machine_type "personal" }}

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal

{{ end }}

{{ if eq .machine_type "work" }}

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work

# Put confidential work-only hosts and proxy/bastion settings here.
Include ~/.ssh/config.local

{{ end }}

{{ if eq .machine_type "server" }}

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519

{{ end }}
```

Review before applying:

```sh
task diff
task dry-run
```

Apply only the SSH config if needed:

```sh
chezmoi apply ~/.ssh/config
```

---

## Recommended Existing Machine Adoption Order

For an existing machine, adopt files in this order.

### Phase 0: Inspect

```sh
task inventory
task diff
task dry-run
```

### Phase 1: SSH config

```sh
chezmoi add ~/.ssh/config
```

Review carefully:

```sh
chezmoi cd
git diff
```

### Phase 2: Basic Git/editor files

```sh
chezmoi add ~/.gitconfig
chezmoi add ~/.config/git/ignore
chezmoi add ~/.editorconfig
```

### Phase 3: Shell files

```sh
chezmoi add ~/.zshrc
chezmoi add ~/.zprofile
```

Move secrets, tokens, proxies, and machine-local paths to:

```text
~/.zshrc.local
```

This file should not be committed.

### Phase 4: Terminal configs

Adopt only the terminal emulators you actually use.

```sh
chezmoi add ~/.config/ghostty
chezmoi add ~/.config/alacritty
chezmoi add ~/.config/wezterm
```

### Phase 5: Editor configs

Neovim:

```sh
chezmoi add ~/.config/nvim
```

VS Code on Linux:

```sh
chezmoi add ~/.config/Code/User/settings.json
```

VS Code paths differ by OS:

```text
Linux:   ~/.config/Code/User/settings.json
macOS:   ~/Library/Application Support/Code/User/settings.json
Windows: ~/AppData/Roaming/Code/User/settings.json
```

### Phase 6: macOS-specific configs

```sh
chezmoi add ~/.config/karabiner/karabiner.json
```

### Phase 7: Personal scripts

```sh
chezmoi add ~/.local/bin
```

Do not commit:

- company-only scripts,
- tokens,
- generated files,
- large binaries,
- temporary scripts.

After each phase:

```sh
task diff
task dry-run
git status
git diff
```

Commit small logical changes:

```sh
git add .
git commit -m "Adopt SSH config"
```

---

## Task Runner

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

Command meanings:

| Command | Description |
|---|---|
| `task inventory` | List existing local dotfile candidates |
| `task diff` | Show chezmoi diff |
| `task dry-run` | Preview apply operation |
| `task apply` | Apply dotfiles |
| `task update` | Pull and apply latest dotfiles |
| `task status` | Show chezmoi status |
| `task doctor` | Run diagnostics |
| `task render` | Render templates using test config |
| `task test` | Run local test workflow |

---

## Repository Structure

```text
.
├── README.md
├── Taskfile.yml
├── .chezmoi.toml.tmpl
├── .chezmoiignore.tmpl
├── dot_gitconfig.tmpl
├── dot_zshrc.tmpl
├── dot_zprofile.tmpl
├── dot_config/
│   ├── git/
│   │   └── ignore
│   ├── nvim/
│   │   └── init.lua
│   ├── ghostty/
│   │   └── config.tmpl
│   ├── alacritty/
│   │   └── alacritty.toml.tmpl
│   ├── wezterm/
│   │   └── wezterm.lua.tmpl
│   ├── karabiner/
│   │   └── karabiner.json.tmpl │   └── User/
│   │       └── settings.json.tmpl
│   └── starship.toml
├── private_dot_ssh/
│   └── config.tmpl
├── executable_dot_local/
│   └── bin/
│       └── dotfiles-healthcheck
├── scripts/
│   ├── inventory.sh
│   └── inventory.ps1
├── tests/
│   └── chezmoi-ci.toml
└── .github/
    └── workflows/
        └── ci.yml
```

Common chezmoi naming rules:

| Source name | Destination path |
|---|---|
| `dot_zshrc` | `~/.zshrc` |
| `dot_config/git/ignore` | `~/.config/git/ignore` |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config`, rendered from template |
| `executable_dot_local/bin/foo` | `~/.local/bin/foo` |
| `dot_gitconfig.tmpl` | `~/.gitconfig`, rendered from template |

---

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
- personal scripts

Not every machine needs every application.

OS-specific and machine-specific differences are handled through chezmoi
templates, local data, and local-only files.

---

## Machine Types

Each machine has a `machine_type` configured in chezmoi local data.

Supported values:

```text
personal
work
server
```

Example:

```toml
[data]
machine_type = "work"
```

Templates can use this value:

```gotemplate
{{ if eq .machine_type "work" }}
# work-specific config
{{ end }}
```

Typical usage:

| Machine type | Purpose |
|---|---|
| `personal` | Personal laptop or desktop |
| `work` | Work-managed machine |
| `server` | Remote server or headless environment |

---

## Secrets Policy

Secrets must not be committed to this repository.

Do not commit:

- SSH private keys
- API tokens
- passwords
- credentials
- company confidential hostnames
- machine-local private paths
- generated application state

Use one of the following instead:

- `~/.zshrc.local`
- `~/.ssh/config.local`
- environment variables
- password managers
- 1Password CLI
- `pass`
- `gopass`
- another secret manager

`~/.ssh/config` may be managed by chezmoi, but private keys must not be managed.

---

## OS Differences

Use chezmoi templates for files that genuinely differ by OS.

Example:

```gotemplate
{{ if eq .chezmoi.os "darwin" }}
# macOS-specific config
{{ end }}

{{ if eq .chezmoi.os "linux" }}
# Linux-specific config
{{ end }}

{{ if eq .chezmoi.os "windows" }}
# Windows-specific config
{{ end }}
```

Useful variables:

```gotemplate
{{ .chezmoi.os }}
{{ .chezmoi.arch }}
{{ .chezmoi.hostname }}
{{ .chezmoi.username }}
{{ .chezmoi.homeDir }}
```

Keep templates small when possible.

If a language has its own runtime OS detection, prefer that over mixing too much
Go template syntax into source files.

---

## Neovim Configuration Policy

The initial Neovim configuration is intentionally minimal.

At first, this repository may only contain:

```text
dot_config/nvim/init.lua
```

`init.lua` is not written as a `.tmpl` file because it should remain valid Lua.
This keeps normal Lua tooling working:

- Lua language server
- stylua
- Neovim diagnostics
- syntax highlighting

If chezmoi-specific values are needed later, generate a small Lua module instead:

```text
dot_config/nvim/lua/user/chezmoi.lua.tmpl
```

This renders to:

```text
~/.config/nvim/lua/user/chezmoi.lua
```

and can expose non-secret data such as:

- OS
- architecture
- hostname
- machine type

Machine-local or secret Neovim configuration should not be committed.

Use a local-only file if needed:

```text
~/.config/nvim/lua/user/local.lua
```

---

## Editing Managed Files

Edit source state directly:

```sh
chezmoi cd
$EDITOR .
```

Then review:

```sh
task diff
task dry-run
```

Apply:

```sh
task apply
```

Edit a managed file with chezmoi:

```sh
chezmoi edit ~/.zshrc
chezmoi apply ~/.zshrc
```

If you edited the real file directly, update chezmoi source state:

```sh
chezmoi re-add ~/.zshrc
```

Review:

```sh
git diff
task diff
```

---

## Conflict Resolution

When there is a conflict between the repository and the local machine:

1. Do not apply immediately.
2. Inspect the diff.

```sh
task diff
```

3. Merge if needed.

```sh
chezmoi merge <file>
```

4. Extract machine-specific differences into templates or local-only files.
5. Commit only reusable configuration.
6. Keep private or temporary local changes out of the repository.

---

## Testing

Dotfiles should be tested as much as practical.

Run:

```sh
task render
task test
```

The test workflow should check:

- template rendering,
- dry-run apply behavior,
- shell scripts where possible,
- obvious cross-platform assumptions.

CI should run on:

- Linux
- macOS
- Windows

The goal of CI is not to perfectly reproduce every personal machine.
The goal is to catch obvious template errors, invalid scripts, and unsafe
assumptions.

---

## Daily Workflow

Pull latest dotfiles:

```sh
task update
```

Check local status:

```sh
task status
task diff
```

Apply:

```sh
task apply
```

Add a new file:

```sh
chezmoi add ~/.config/example/config.toml
chezmoi cd
git add .
git commit -m "Add example config"
```

Update source after manual local changes:

```sh
chezmoi re-add ~/.config/example/config.toml
chezmoi cd
git diff
git commit -am "Update example config"
```

---

## Design Philosophy

This repository follows these principles.

### 1. Incremental adoption over big-bang migration

Existing machines may already contain valuable local customization.

This repository should not overwrite those files blindly. Instead, files are
adopted gradually, reviewed carefully, and committed in small logical steps.

### 2. Safe by default

The default workflow is always:

```sh
task diff
task dry-run
task apply
```

Never apply blindly.

### 3. Cross-platform first

The repository should work across:

- macOS
- Linux
- Windows

Taskfile is used as the cross-platform command interface.
chezmoi templates are used for OS-specific and machine-specific configuration.

### 4. Secrets stay local

Secrets do not belong in dotfiles.

Private keys, tokens, passwords, company-confidential settings, and machine-local
private paths should stay in local-only files or password managers.

### 5. Prefer readable native config

Configuration files should remain valid in their native language whenever
possible.

For example:

- Lua files should remain valid Lua.
- JSON files should remain valid JSON where practical.
- Shell scripts should remain readable and testable.

Use `.tmpl` only when the value genuinely needs chezmoi rendering.

### 6. Shared core, local edges

The repository should capture the reusable core of the environment.

Machine-specific edges should be expressed through:

- `machine_type`,
- OS conditions,
- local-only files,
- password managers,
- small template boundaries.

The goal is not perfect uniformity.
The goal is reproducible, understandable, and safely adaptable environments.

### 7. Bootstrap Scripts Policy

This repository intentionally does not run package installation or system setup
automatically during the initial adoption phase.

In particular, it does not include `run_once_*` scripts by default.

This keeps `chezmoi apply` safe and predictable, especially on existing machines
and across macOS, Linux, and Windows.

If bootstrap scripts are added later, they must be:

- explicit,
- idempotent,
- OS-aware,
- safe to run multiple times,
- free of secrets,
- guarded by local data such as `install_packages = true`.

For now, system setup should be performed through explicit Taskfile commands or
manual steps.

---

## References

- [chezmoi Usage FAQ](https://chezmoi.io/user-guide/frequently-asked-questions/usage)
- [Manage machine-to-machine differences - chezmoi](https://chezmoi.io/user-guide/manage-machine-to-machine-differences)
- [Task](https://taskfile.dev/)
- [Testable dotfiles management with chezmoi](https://zenn.dev/shunk031/articles/testable-dotfiles-management-with-chezmoi)
- [Taskfile: The Modern Alternative to Makefile That Will Change Your Workflow](https://marmelab.com/blog/2026/03/12/taskfile-alternative-makefile.html)
