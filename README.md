# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

This repository supports both:

1. Fresh machines with no previous dotfiles.
2. Existing machines that already have locally customized dotfiles.

The goal is not to force every machine into an identical state immediately.
Instead, this repository provides a safe, testable, and incremental workflow for
bringing machines under chezmoi management while preserving useful local
differences.

> [!IMPORTANT]
> For files already managed as templates, edit the source `.tmpl` file instead
> of blindly running `chezmoi add`.
>
> If chezmoi warns that adding a file would remove the template attribute, stop
> and update the template source manually.

---

## Quick Start

### Install chezmoi

macOS:

```sh
brew install chezmoi
```

Linux:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
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

## Git Identity Model

The core dotfiles repository is managed by the personal GitHub account.

Each machine has a `machine_type`:

- `personal`
- `office`

For `personal` machines, the default Git email is stored in the core chezmoi
configuration.

For `office` machines, the office email is not stored in the core dotfiles
repository. Instead, it is loaded from the office-only repository:

```text
~/.local/share/dotfiles-office/git/gitconfig-office
```

The core `~/.gitconfig` includes this file only when:

```toml
machine_type = "office"
```

This keeps office identity information out of the personal dotfiles repository.
```

```markdown
## Office-only Repository

Office-only settings are managed outside chezmoi by a separate Git repository.

The office repository is cloned to:

```text
~/.local/share/dotfiles-office
```

### Recommended office repository

The simplest office repository is a small repository containing only SSH config
snippets:

```text
dotfiles-ssh-office/
└── office.conf
```

Git does not truly clone a single file by itself. If only one file is needed,
keep the office repository small and clone the repository to the target
directory.

Install or update it with Task:

```sh
task office:install
```

The repository URL should be provided by an environment variable so that the core
dotfiles repository does not expose office organization names or private URLs.

macOS / Linux:

```sh
export DOTFILES_OFFICE_REPO=git@githubw.com:<ORG>/dotfiles-ssh-office.git
task office:install
```

Windows PowerShell:

```powershell
$env:DOTFILES_OFFICE_REPO = "git@githubw.com:<ORG>/dotfiles-ssh-office.git"
task office:install
```

This keeps the core dotfiles repository safe to share while allowing office-only
SSH settings to be synced separately.

### Office SSH config example

```sshconfig
# Office-only SSH config.
# This file is managed by the office SSH config repository.
# Do not commit private keys, passwords, or tokens.

Host office-bastion
    HostName example.internal
    User your-user-name
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

Host office-server
    HostName server.internal
    User your-user-name
    ProxyJump office-bastion
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

Private keys are still local-only:

```text
~/.ssh/id_ed25519_work
```

---

## Fresh Machine Setup

Install chezmoi and Task first.

If SSH is not configured yet, initialize with HTTPS first:

```sh
chezmoi init https://github.com/<USER>/dotfiles.git
```

If SSH is already configured:

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

After SSH config is applied, you may switch the repository remote to SSH:

```sh
git remote set-url origin git@github.com:<USER>/dotfiles.git
```

---

## Where to Run Task

`Taskfile.yml` lives in the chezmoi source directory, not in `$HOME`.

Check the source directory with:

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

## Template-First Workflow

Some files are managed as chezmoi templates.

Examples:

| Destination | Source |
|---|---|
| `~/.gitconfig` | `dot_gitconfig.tmpl` |
| `~/.zshrc` | `dot_zshrc.tmpl` |
| `~/.ssh/config` | `private_dot_ssh/config.tmpl` |
| `~/.config/alacritty/alacritty.toml` | `dot_config/alacritty/alacritty.toml.tmpl` |
| `~/.config/wezterm/wezterm.lua` | `dot_config/wezterm/wezterm.lua.tmpl` |

For template-managed files, prefer editing the template source directly.

Recommended workflow:

```sh
chezmoi cd
$EDITOR private_dot_ssh/config.tmpl
```

Then inspect the rendered diff:

```sh
chezmoi diff ~/.ssh/config
chezmoi apply --dry-run --verbose ~/.ssh/config
```

Apply only after reviewing the rendered output:

```sh
chezmoi apply ~/.ssh/config
```

Commit the source template:

```sh
git add private_dot_ssh/config.tmpl
git commit -m "Update SSH config template"
```

### Do not blindly re-add template-managed files

If a destination file is already managed as a template, running:

```sh
chezmoi add ~/.ssh/config
```

may show a warning like:

```text
adding .ssh/config would remove template attribute, continue?
```

In most cases, answer:

```text
n
```

This warning means that `chezmoi add` would replace the template source with a
plain file and remove the `.tmpl` behavior.

Instead, compare the current rendered template with the local file, then edit the
template source manually:

```sh
chezmoi cat ~/.ssh/config > /tmp/ssh-config.chezmoi
diff -u /tmp/ssh-config.chezmoi ~/.ssh/config || true
```

Or with VS Code:

```sh
code --diff /tmp/ssh-config.chezmoi ~/.ssh/config
```

Then update the source template:

```sh
chezmoi cd
$EDITOR private_dot_ssh/config.tmpl
```

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

The recommended source file is:

```text
private_dot_ssh/config.tmpl
```

This renders to:

```text
~/.ssh/config
```

### SSH privacy model

`private_dot_ssh` in chezmoi means that the destination file should have private
file permissions. It does not mean that the file is encrypted in the repository.

Therefore, anything committed to:

```text
private_dot_ssh/config.tmpl
```

must be safe to exist in this repository.

This repository should only contain reusable SSH core settings, such as:

- generic `Host *` defaults,
- public service aliases,
- GitHub account switching aliases,
- `IdentityFile` paths,
- local include points.

This repository should not contain:

- SSH private keys,
- passwords,
- tokens,
- confidential company hostnames,
- bastion hosts,
- proxy settings,
- customer names,
- machine-local private paths.

---

## SSH Config Layout

The core SSH config should provide include points for local or office-specific
settings.

Important rules:

1. `Include` directives should be placed before the first `Host` block.
2. Explicit host entries should come before `Host *`.
3. `Host *` should generally be placed at the end.
4. Do not use obsolete options such as `UseRoaming`.

Example:

```sshconfig
# -*-mode:ssh-config-*- vim:ft=sshconfig

# Managed by chezmoi.
# Keep this file safe to commit.
# Do not put private keys, passwords, tokens, or confidential host information here.

# Local / office-specific SSH snippets.
# These files are not managed by the core dotfiles repository.
Include ~/.ssh/config.d/*.conf
Include ~/.ssh/config.d/*/*.conf
Include ~/.ssh/config.local

Host github.com
    HostName github.com
    User git
    Port 22
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes

Host githubw.com
    HostName github.com
    User git
    Port 22
    IdentityFile ~/.ssh/id_ecdsa_w
    IdentitiesOnly yes

Host *
    # Accelerate connections by reusing existing connections to the same host.
    ControlMaster auto
    ControlPath ~/.ssh/controlmasters/%C
    ControlPersist 5m

    # Add keys to the SSH agent.
    AddKeysToAgent yes

{{ if eq .chezmoi.os "darwin" }}
    # Allow storing passphrases in the macOS keychain.
    UseKeychain yes
{{ end }}

    # Keep connections alive by sending periodic messages.
    ServerAliveCountMax 6
    ServerAliveInterval 15

    TCPKeepAlive yes
    IdentitiesOnly yes
```

Create the ControlMaster directory if needed:

```sh
mkdir -p ~/.ssh/controlmasters
chmod 700 ~/.ssh
chmod 700 ~/.ssh/controlmasters
```

---

## Office-only SSH Config

The core dotfiles repository does not contain office-confidential SSH host
entries.

Office-only SSH settings should be stored in a separate Git repository and cloned
into:

```text
~/.ssh/config.d/office/
```

For example:

```text
~/.ssh/config.d/office/office.conf
```

The core SSH config includes it through:

```sshconfig
Include ~/.ssh/config.d/*/*.conf
```

---

## SSH Template Update Quick Recipe

```sh
# 1. Do not overwrite the template.
# If chezmoi asks whether to remove the template attribute, answer "n".

# 2. Compare rendered template with the current local file.
chezmoi cat ~/.ssh/config > /tmp/ssh-config.chezmoi
diff -u /tmp/ssh-config.chezmoi ~/.ssh/config || true

# 3. Edit the source template.
chezmoi cd
$EDITOR private_dot_ssh/config.tmpl

# 4. Review rendered result.
chezmoi diff ~/.ssh/config
chezmoi apply --dry-run --verbose ~/.ssh/config

# 5. Apply only SSH config.
chezmoi apply ~/.ssh/config

# 6. Validate SSH.
ssh -G github.com > /tmp/ssh-github.resolved
ssh -T git@github.com

# 7. Commit.
git add private_dot_ssh/config.tmpl
git commit -m "Update SSH config template"
```

---

## First-time SSH Config Adoption

If this repository does not yet have an SSH config template, you may add the
existing file as a template:

```sh
chezmoi add --template ~/.ssh/config
```

Then review the generated source:

```sh
chezmoi cd
git diff
```

The generated file should be:

```text
private_dot_ssh/config.tmpl
```

Before committing, remove or move out:

- private keys,
- passwords,
- tokens,
- confidential hostnames,
- company-only proxy or bastion settings,
- machine-local private paths.

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

SSH config is prioritized because it is often required before other private
repositories can be cloned.

If this repository does not yet manage SSH config:

```sh
chezmoi add --template ~/.ssh/config
```

If this repository already has:

```text
private_dot_ssh/config.tmpl
```

do not run a plain `chezmoi add ~/.ssh/config`.

Instead:

```sh
chezmoi cat ~/.ssh/config > /tmp/ssh-config.chezmoi
diff -u /tmp/ssh-config.chezmoi ~/.ssh/config || true
chezmoi cd
$EDITOR private_dot_ssh/config.tmpl
```

Review:

```sh
chezmoi diff ~/.ssh/config
chezmoi apply --dry-run --verbose ~/.ssh/config
```

Apply only SSH config:

```sh
chezmoi apply ~/.ssh/config
```

Commit:

```sh
git add private_dot_ssh/config.tmpl
git commit -m "Adopt SSH config template"
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
git commit -m "Adopt local dotfiles incrementally"
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
task office:install
task office:update
task office:status
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
| `task office:install` | Clone or update office-only SSH config repository |
| `task office:status` | Show office-only SSH config repository status |

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
│   │   └── karabiner.json.tmpl
│   ├── Code/
│   │   └── User/
│   │       └── settings.json.tmpl
│   └── starship.toml
├── private_dot_ssh/
│   ├── config.tmpl
│   └── controlmasters/
│       └── .keep
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
| `private_dot_ssh/controlmasters/.keep` | `~/.ssh/controlmasters/.keep` |
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
- `~/.ssh/config.d/*.conf`
- `~/.ssh/config.d/*/*.conf`
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

There are two different workflows depending on whether the file is managed as a
plain file or as a template.

### Plain managed files

Example:

```text
~/.config/nvim/init.lua
```

Source:

```text
dot_config/nvim/init.lua
```

Edit the source directly:

```sh
chezmoi cd
$EDITOR dot_config/nvim/init.lua
```

Then review and apply:

```sh
chezmoi diff ~/.config/nvim/init.lua
chezmoi apply --dry-run --verbose ~/.config/nvim/init.lua
chezmoi apply ~/.config/nvim/init.lua
```

If you edited the destination file directly, update the source state:

```sh
chezmoi re-add ~/.config/nvim/init.lua
```

Then review:

```sh
chezmoi cd
git diff
```

### Template-managed files

Example:

```text
~/.ssh/config
```

Source:

```text
private_dot_ssh/config.tmpl
```

For template-managed files, prefer editing the source template directly:

```sh
chezmoi cd
$EDITOR private_dot_ssh/config.tmpl
```

Then review the rendered destination:

```sh
chezmoi diff ~/.ssh/config
chezmoi apply --dry-run --verbose ~/.ssh/config
```

Apply:

```sh
chezmoi apply ~/.ssh/config
```

Do not blindly run `chezmoi add` on a destination file that is already managed as
a template.

If you see:

```text
adding .ssh/config would remove template attribute, continue?
```

answer:

```text
n
```

Then compare the rendered template with the local destination:

```sh
chezmoi cat ~/.ssh/config > /tmp/ssh-config.chezmoi
diff -u /tmp/ssh-config.chezmoi ~/.ssh/config || true
```

After reviewing the difference, manually update the template source.

### When to use `chezmoi re-add`

Use `chezmoi re-add` mainly for plain managed files.

Good examples:

```sh
chezmoi re-add ~/.config/nvim/init.lua
chezmoi re-add ~/.config/git/ignore
```

Be careful with template-managed files because re-adding or adding them may remove
the template attribute.

For templates, prefer:

```sh
chezmoi cd
$EDITOR <source>.tmpl
```

### When to use `chezmoi merge`

`chezmoi merge` can help when both the source state and destination file have
changed.

Example:

```sh
chezmoi merge ~/.zshrc
```

However, for template-managed files, merge is only a helper.

It cannot decide:

- which lines belong in an OS-specific block,
- which settings belong in `work`, `personal`, or `server`,
- which settings are confidential,
- which settings should move to a local-only file.

For files such as `~/.ssh/config`, prefer manual classification and template
editing.

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

Do not install chezmoi in CI with:

```sh
go install github.com/twpayne/chezmoi/v2@latest
```

Use the official chezmoi installer instead.

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

### Add a new plain file

For files that do not need OS or machine-specific rendering:

```sh
chezmoi add ~/.config/example/config.toml
```

### Add a new template file

For files that need OS or machine-specific rendering:

```sh
chezmoi add --template ~/.config/example/config.toml
```

Then edit the generated `.tmpl` source:

```sh
chezmoi cd
$EDITOR dot_config/example/config.toml.tmpl
```

### Update source after manual local changes

For plain managed files:

```sh
chezmoi re-add ~/.config/example/config.toml
chezmoi cd
git diff
git commit -am "Update example config"
```

For template-managed files, edit the `.tmpl` source directly instead.

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
private paths should stay in local-only files, office-only repositories, or
password managers.

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
- small template boundaries,
- office-only repositories when needed.

The goal is not perfect uniformity.
The goal is reproducible, understandable, and safely adaptable environments.

### 7. Template-first for files with machine differences

Files with OS-specific, machine-specific, or role-specific differences should be
managed as templates.

Examples:

- `~/.ssh/config`
- `~/.gitconfig`
- `~/.zshrc`
- terminal emulator settings

For these files, the source template is the canonical file.

Do not blindly re-add rendered destination files if doing so would remove the
template attribute.

Instead:

1. compare rendered output with the local destination,
2. classify the difference,
3. update the template source,
4. review with dry-run,
5. apply intentionally.

### 8. Keep office-specific settings outside the core repository

If a setting is office-confidential, do not commit it to the core dotfiles
repository.

For the current setup, office-specific SSH settings are stored in a separate Git
repository and cloned into:

```text
~/.ssh/config.d/office/
```

This avoids the complexity of multi-source chezmoi while keeping confidential
settings out of the core repository.

### 9. Bootstrap scripts policy

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
