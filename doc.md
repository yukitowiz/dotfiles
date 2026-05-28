Yukiさん、はい、README はアップデートした方がよいです。今回の変更でリポジトリの思想がかなり明確になります。

Makefile をやめて、読みやすい scripts/dotfiles コマンドに置き換える
nvim / ghostty / alacritty / wezterm / karabiner / VS Code / SSH を初期管理対象に入れる
「秘密情報は管理しない」「OS差分・用途差分はテンプレートで吸収する」「既存環境は段階的に取り込む」ことを README に明記する

以下、そのまま反映できる形で整理します。

1. Makefile の代案
推奨案: scripts/dotfiles に集約する
Makefile より読みやすく、依存も増やさない案です。
./scripts/dotfiles diff
./scripts/dotfiles dry-run
./scripts/dotfiles apply
./scripts/dotfiles test
./scripts/dotfiles render
./scripts/dotfiles doctor
./scripts/dotfiles inventory

make diff より少し長いですが、処理内容を普通の shell script として読めるので、保守性が高いです。

2. 更新後のディレクトリ構成案
dotfiles/
├── README.md
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
│   └── config.tmpl
├── executable_dot_local/
│   └── bin/
│       └── dotfiles-healthcheck
├── run_once_before_00-install-packages.sh.tmpl
├── run_once_after_90-healthcheck.sh.tmpl
├── scripts/
│   ├── dotfiles
│   ├── install-chezmoi.sh
│   ├── inventory.sh
│   ├── test.sh
│   └── render.sh
├── tests/
│   └── chezmoi-ci.toml
└── .github/
    └── workflows/
        └── ci.yml

補足です。

dot_config/Code/User/settings.json.tmpl
Linux 用


macOS の VS Code は本来 ~/Library/Application Support/Code/User/settings.json
これは必要なら後で追加するのが安全です


dot_config/karabiner/
macOS 専用として扱います


private_dot_ssh/config.tmpl
SSH config は管理する
秘密鍵は管理しない




3. Makefile 代替: scripts/dotfiles
scripts/dotfiles
#!/bin/sh

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/dotfiles <command>

Commands:
  diff        Show chezmoi diff
  dry-run     Run chezmoi apply in dry-run mode
  apply       Apply dotfiles
  update      Pull and apply latest dotfiles
  status      Show chezmoi status
  doctor      Run diagnostics
  render      Render templates for CI/local check
  test        Run all tests
  inventory   List existing local dotfiles candidates
  cd          Open chezmoi source directory
EOF
}

cmd="${1:-}"

case "$cmd" in
  diff)
    chezmoi diff
    ;;

  dry-run)
    chezmoi apply --dry-run --verbose
    ;;

  apply)
    chezmoi apply
    ;;

  update)
    chezmoi update
    ;;

  status)
    chezmoi status
    ;;

  doctor)
    chezmoi doctor
    chezmoi status
    ;;

  render)
    "$ROOT/scripts/render.sh"
    ;;

  test)
    "$ROOT/scripts/test.sh"
    ;;

  inventory)
    "$ROOT/scripts/inventory.sh"
    ;;

  cd)
    chezmoi cd
    ;;

  "" | help | -h | --help)
    usage
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac

権限付与：
chmod +x scripts/dotfiles


4. .chezmoi.toml.tmpl の更新
work / personal / server 分岐を明確にします。
{{- $name := promptStringOnce . "name" "Your full name" -}}
{{- $email := promptStringOnce . "email" "Git email address" -}}
{{- $machineType := promptStringOnce . "machine_type" "Machine type: personal/work/server" -}}
{{- $installPackages := promptBoolOnce . "install_packages" "Install packages automatically?" false -}}

[data]
name = {{ $name | quote }}
email = {{ $email | quote }}
machine_type = {{ $machineType | quote }}
install_packages = {{ $installPackages }}


5. .chezmoiignore.tmpl の更新
README、CI、テスト、スクリプトなどはホームディレクトリへ展開しません。
加えて、OS 専用設定を制御します。
.chezmoiignore.tmpl
README.md
scripts/
tests/
.github/

{{ if ne .chezmoi.os "darwin" }}
dot_config/karabiner/
{{ end }}

必要になったら、macOS 専用 VS Code パスや Ghostty の macOS ネイティブパスもここで分岐できます。

6. アプリ別テンプレート
dot_config/nvim/init.lua
最初は最小構成でよいです。既存の Neovim 設定がある場合は、後で chezmoi add ~/.config/nvim で取り込む方が安全です。
-- Managed by chezmoi

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.termguicolors = true

vim.g.mapleader = " "


dot_config/ghostty/config.tmpl
# Managed by chezmoi

font-family = JetBrainsMono Nerd Font
font-size = 14
theme = dark:GruvboxDark,light:GruvboxLight
window-padding-x = 8
window-padding-y = 8

{{ if eq .machine_type "work" }}
# Work machine specific settings
confirm-close-surface = true
{{ end }}

{{ if eq .machine_type "personal" }}
# Personal machine specific settings
confirm-close-surface = false
{{ end }}


dot_config/alacritty/alacritty.toml.tmpl
# Managed by chezmoi

[window]
padding = { x = 8, y = 8 }
opacity = 0.95

[font]
size = 14

[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"

[selection]
save_to_clipboard = true

{{ if eq .chezmoi.os "darwin" }}
[window.option_as_alt]
option = "Both"
{{ end }}


dot_config/wezterm/wezterm.lua.tmpl
-- Managed by chezmoi

local wezterm = require("wezterm")
local config = {}

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 14.0
config.color_scheme = "Gruvbox Dark"
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

{{ if eq .chezmoi.os "darwin" }}
config.native_macos_fullscreen_mode = true
config.send_composed_key_when_left_alt_is_pressed = true
{{ end }}

{{ if eq .machine_type "server" }}
config.enable_tab_bar = false
{{ else }}
config.enable_tab_bar = true
{{ end }}

return config


dot_config/karabiner/karabiner.json.tmpl
macOS 専用です。最初は最小構成にします。
{
  "global": {
    "check_for_updates_on_startup": true,
    "show_in_menu_bar": true,
    "show_profile_name_in_menu_bar": false
  },
  "profiles": [
    {
      "name": "Default",
      "selected": true,
      "simple_modifications": [],
      "complex_modifications": {
        "rules": []
      },
      "virtual_hid_keyboard": {
        "keyboard_type_v2": "ansi"
      }
    }
  ]
}

既に Karabiner をかなりカスタムしている場合は、これは初期テンプレートとして置かず、既存の ~/.config/karabiner/karabiner.json を後で取り込む方がよいです。

dot_config/Code/User/settings.json.tmpl
Linux 向けの VS Code 設定です。macOS も同じ XDG パスで使う運用ならこのままでよいですが、通常の macOS VS Code は別パスです。
{
  "editor.fontFamily": "JetBrainsMono Nerd Font, Menlo, Monaco, 'Courier New', monospace",
  "editor.fontSize": 14,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.formatOnSave": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.defaultProfile.linux": "zsh",
  "workbench.colorTheme": "Default Dark Modern"
}


7. SSH 方針とテンプレート
方針
管理するもの：

~/.ssh/config
Host 定義
IdentityFile のパス
User
HostName
ForwardAgent などの設定

管理しないもの：

秘密鍵
秘密鍵の passphrase
API token
社内ホスト名で公開できないもの
機密性の高い踏み台情報

機密性があるものは以下へ逃がします。

~/.zshrc.local
password manager
1Password CLI
環境変数
Git 管理外の ~/.ssh/config.local


private_dot_ssh/config.tmpl
# Managed by chezmoi
# Do not put private keys or secrets in this file.

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

# Put confidential work-only settings in ~/.ssh/config.local.
Include ~/.ssh/config.local

{{ end }}

{{ if eq .machine_type "server" }}

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519

{{ end }}

注意点：

~/.ssh/config.local は chezmoi 管理外
Include ~/.ssh/config.local により、社内用の非公開設定を分離
秘密鍵ファイルは絶対に commit しない


8. .zshrc.local 対応
dot_zshrc.tmpl
既に近い形ですが、明示的に方針を入れます。
# Managed by chezmoi

export EDITOR="nvim"
export LANG="en_US.UTF-8"
export PATH="$HOME/.local/bin:$PATH"

{{ if eq .chezmoi.os "darwin" }}
if [ -d /opt/homebrew/bin ]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi
{{ end }}

{{ if eq .chezmoi.os "linux" }}
if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi
{{ end }}

{{ if eq .machine_type "work" }}
# Work-specific non-secret defaults can go here.
export DOTFILES_MACHINE_TYPE="work"
{{ else if eq .machine_type "personal" }}
export DOTFILES_MACHINE_TYPE="personal"
{{ else if eq .machine_type "server" }}
export DOTFILES_MACHINE_TYPE="server"
{{ end }}

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Local overrides.
# This file is intentionally not managed by chezmoi.
# Use it for secrets, tokens, corporate proxy, and machine-local paths.
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi


9. 既存手元ファイル確認用: scripts/inventory.sh
Yukiさんの実環境に対して、まず「何があるか」を確認するためのスクリプトです。
scripts/inventory.sh
#!/bin/sh

set -eu

candidates='
~/.gitconfig
~/.gitignore_global
~/.editorconfig
~/.zshrc
~/.zprofile
~/.bashrc
~/.bash_profile
~/.config/git/ignore
~/.config/nvim
~/.config/ghostty
~/.config/alacritty
~/.config/wezterm
~/.config/karabiner
~/.config/Code/User/settings.json
~/.ssh/config
~/.local/bin
'

echo "Existing dotfile candidates:"
echo

for path in $candidates; do
  expanded=$(eval echo "$path")

  if [ -e "$expanded" ]; then
    if [ -d "$expanded" ]; then
      count=$(find "$expanded" -type f | wc -l | tr -d ' ')
      echo "[dir ] $path  files=$count"
    else
      size=$(wc -c < "$expanded" | tr -d ' ')
      echo "[file] $path  size=${size}B"
    fi
  else
    echo "[none] $path"
  fi
done

権限付与：
chmod +x scripts/inventory.sh

実行：
./scripts/dotfiles inventory


10. 「何から chezmoi add するべきか」チェックリスト
大原則
既存環境では、いきなり chezmoi apply しません。
最初は必ず：
chezmoi init git@github.com:<USER>/dotfiles.git
chezmoi diff
chezmoi apply --dry-run --verbose

その後、1ファイルずつ取り込みます。

Phase 0: 現状確認
./scripts/dotfiles inventory
chezmoi status
chezmoi diff

ここで見るもの：

既に存在する dotfiles
サイズが大きすぎる設定ディレクトリ
キャッシュや生成物が混ざっていそうなディレクトリ
秘密情報が含まれていそうなファイル


Phase 1: 低リスクなファイル
最初に取り込む候補です。
chezmoi add ~/.gitconfig
chezmoi add ~/.config/git/ignore
chezmoi add ~/.editorconfig

確認：
chezmoi cd
git diff
chezmoi diff

コミット：
git add .
git commit -m "Adopt basic git and editor config"


Phase 2: shell 設定
次に shell 設定です。
chezmoi add ~/.zshrc
chezmoi add ~/.zprofile

取り込み後にやること：

秘密情報を削除
machine-specific な値を .zshrc.local へ移す
OS差分を {{ if eq .chezmoi.os "darwin" }} へ移す
用途差分を {{ if eq .machine_type "work" }} へ移す

確認：
chezmoi diff
chezmoi apply --dry-run --verbose


Phase 3: terminal 設定
次に terminal 系です。
chezmoi add ~/.config/ghostty
chezmoi add ~/.config/alacritty
chezmoi add ~/.config/wezterm

優先順位としては、実際に使っているものだけでよいです。
おすすめ：

メインで使っている terminal
サブで使っている terminal
ほぼ使っていないものは後回し


Phase 4: editor 設定
Neovim:
chezmoi add ~/.config/nvim

VS Code Linux:
chezmoi add ~/.config/Code/User/settings.json

VS Code は extensions list も別途管理できますが、最初は settings.json だけで十分です。

Phase 5: SSH config
SSH は慎重に扱います。
chezmoi add ~/.ssh/config

その後、source 側を確認します。
chezmoi cd
git diff

必ず確認すること：

秘密鍵そのものが入っていないか
社内ホスト名を公開してよいか
踏み台情報が含まれていないか
token や password が入っていないか
IdentityFile がパスだけになっているか

必要に応じて、以下の形へ分離します。
Include ~/.ssh/config.local

そして ~/.ssh/config.local は Git 管理しません。

Phase 6: macOS 専用設定
Karabiner は macOS のみです。
chezmoi add ~/.config/karabiner/karabiner.json

注意：

Karabiner の設定は大きくなりがち
GUI 操作で頻繁に変わる
まずは安定した設定だけ取り込む


Phase 7: scripts
最後に自作スクリプトです。
chezmoi add ~/.local/bin

ただし、以下は除外した方がよいです。

会社専用スクリプト
token を含むスクリプト
一時作業用スクリプト
生成物
サイズの大きいバイナリ


11. README に追加すべき内容
README は更新した方がよいです。追加するなら、以下のセクションを入れるのがおすすめです。

README 追加セクション案
## Tooling

This repository does not use a Makefile.

Common operations are provided by a readable shell command:

```sh
./scripts/dotfiles diff
./scripts/dotfiles dry-run
./scripts/dotfiles apply
./scripts/dotfiles test
./scripts/dotfiles inventory

The command is intentionally implemented as a simple shell script so that theworkflow remains easy to inspect and modify.

---

```markdown
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


---

```markdown
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


---

# 12. CI の更新ポイント

`Makefile` をやめるので、CI はこうします。

## `.github/workflows/ci.yml` の該当部分

```yaml
      - name: Run tests
        shell: bash
        run: |
          chmod +x scripts/*.sh
          chmod +x scripts/dotfiles
          ./scripts/dotfiles test


13. 次にやる実作業順
Yukiさんの手元では、次の順番がよいです。
# 1. scripts/dotfiles を追加
chmod +x scripts/dotfiles scripts/*.sh

# 2. inventory
./scripts/dotfiles inventory

# 3. dry-run
./scripts/dotfiles diff
./scripts/dotfiles dry-run

# 4. 低リスクファイルから add
chezmoi add ~/.gitconfig
chezmoi add ~/.config/git/ignore

# 5. shell を add
chezmoi add ~/.zshrc
chezmoi add ~/.zprofile

# 6. 実際に使っている terminal/editor を add
chezmoi add ~/.config/nvim
chezmoi add ~/.config/ghostty
chezmoi add ~/.config/alacritty
chezmoi add ~/.config/wezterm

# 7. SSH config を慎重に add
chezmoi add ~/.ssh/config

# 8. 差分確認
chezmoi cd
git diff
chezmoi diff

# 9. コミット
git add .
git commit -m "Adopt local dotfiles incrementally"


14. 結論
今回の方針だと、更新内容はこうです。

Makefile は廃止
scripts/dotfiles を導入
nvim / ghostty / alacritty / wezterm / karabiner / VS Code / SSH の雛形を追加
~/.ssh/config はテンプレート管理
秘密鍵・秘密情報は管理しない
.zshrc.local と ~/.ssh/config.local を逃がし先にする
work / personal / server は .machine_type で分岐
README に運用ポリシーと既存環境移行順を追加

この形にしておくと、新規環境にも既存カスタム環境にも同じ思想で導入できます。


---

Yukiさん、その指摘は完全に正しいです。  
`scripts/dotfiles` は **POSIX shell 前提**なので、Windows では Git Bash / WSL がないと素直に動きません。  
クロスプラットフォーム前提なら、**Makefile でも shell script でもなく Taskfile 採用がかなり良い**です。

結論としては、以下に方針変更するのがおすすめです。

- `Makefile` は使わない
- `scripts/dotfiles` も中核から外す
- **`Taskfile.yml` を操作インターフェースにする**
- OS 固有処理だけ `scripts/inventory.sh` / `scripts/inventory.ps1` のように分ける
- README も `make xxx` / `./scripts/dotfiles xxx` ではなく `task xxx` 前提に更新する

参考に挙げてくれた記事でも、Taskfile は Makefile の読みにくさや暗黙性を避けるための、Go 製・YAML ベースのタスクランナーとして紹介されています。  
また検索結果でも、Task は Makefile 代替として、YAML 構文・依存関係管理・クロスプラットフォーム性が特徴とされています。

- [Taskfile: The Modern Alternative to Makefile That Will Change Your Workflow](https://marmelab.com/blog/2026/03/12/taskfile-alternative-makefile.html)
- [How to Use Task (Taskfile) as a Make Alternative on Ubuntu](https://oneuptime.com/blog/post/2026-03-02-use-task-taskfile-make-alternative-ubuntu/view)
- [Introduction to Taskfile: a Makefile alternative - DEV Community](https://dev.to/stack-labs/introduction-to-taskfile-a-makefile-alternative-h92)

---

# 1. 更新後の方針

## 採用する操作体系

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

これなら macOS / Linux / Windows でほぼ同じ操作にできます。

Windows では PowerShell から：

```powershell
task diff
task dry-run
task apply
task inventory
```

macOS / Linux では：

```sh
task diff
task dry-run
task apply
task inventory
```

---

# 2. 更新後のリポジトリ構成案

```text
dotfiles/
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
│   └── config.tmpl
├── executable_dot_local/
│   └── bin/
│       └── dotfiles-healthcheck
├── run_once_before_00-install-packages.sh.tmpl
├── run_once_after_90-healthcheck.sh.tmpl
├── scripts/
│   ├── inventory.sh
│   └── inventory.ps1
├── tests/
│   └── chezmoi-ci.toml
└── .github/
    └── workflows/
        └── ci.yml
```

`scripts/dotfiles` は削除でよいです。  
操作の入口は `Taskfile.yml` に統一します。

---

# 3. `Taskfile.yml`

```yaml
version: '3'

vars:
  ROOT: '{{.TASKFILE_DIR}}'
  CI_CONFIG: '{{.TASKFILE_DIR}}/tests/chezmoi-ci.toml'
  TEST_DEST: '{{.TASKFILE_DIR}}/.tmp/chezmoi-dest'

tasks:
  default:
    desc: Show available tasks
    cmds:
      - task --list

  diff:
    desc: Show differences between chezmoi source and destination
    cmds:
      - chezmoi diff

  dry-run:
    desc: Run chezmoi apply in dry-run mode
    cmds:
      - chezmoi apply --dry-run --verbose

  apply:
    desc: Apply dotfiles
    cmds:
      - chezmoi apply

  update:
    desc: Pull and apply latest dotfiles
    cmds:
      - chezmoi update

  status:
    desc: Show chezmoi status
    cmds:
      - chezmoi status

  doctor:
    desc: Run diagnostics
    cmds:
      - chezmoi doctor
      - chezmoi status

  cd:
    desc: Print chezmoi source directory
    cmds:
      - chezmoi source-path

  prepare-test-dest:
    desc: Prepare temporary destination directory for tests
    cmds:
      - cmd: mkdir -p "{{.TEST_DEST}}"
        platforms: [linux, darwin]
      - cmd: powershell -NoProfile -ExecutionPolicy Bypass -Command "New-Item -ItemType Directory -Force -Path '{{.TEST_DEST}}' | Out-Null"
        platforms: [windows]

  clean:
    desc: Remove temporary test files
    cmds:
      - cmd: rm -rf "{{.ROOT}}/.tmp"
        platforms: [linux, darwin]
      - cmd: powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -Recurse -Force '{{.ROOT}}/.tmp' -ErrorAction SilentlyContinue"
        platforms: [windows]

  render:
    desc: Render chezmoi templates with CI config
    deps:
      - prepare-test-dest
    cmds:
      - >
        chezmoi
        --source="{{.ROOT}}"
        --destination="{{.TEST_DEST}}"
        --config="{{.CI_CONFIG}}"
        apply
        --dry-run
        --verbose

  test:
    desc: Run cross-platform tests
    cmds:
      - task: render
      - task: lint-shell

  lint-shell:
    desc: Run shellcheck where available
    cmds:
      - cmd: |
          if command -v shellcheck >/dev/null 2>&1; then
            find "{{.ROOT}}" -type f \( -name "*.sh" -o -name "*.sh.tmpl" \) -print | while read -r file; do
              echo "Checking $file"
              shellcheck "$file" || exit 1
            done
          else
            echo "shellcheck not found. Skipping."
          fi
        platforms: [linux, darwin]
      - cmd: powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Skipping shellcheck on Windows.'"
        platforms: [windows]

  inventory:
    desc: List existing local dotfile candidates
    cmds:
      - cmd: sh "{{.ROOT}}/scripts/inventory.sh"
        platforms: [linux, darwin]
      - cmd: powershell -NoProfile -ExecutionPolicy Bypass -File "{{.ROOT}}/scripts/inventory.ps1"
        platforms: [windows]
```

これで、OS ごとの差分は Taskfile の `platforms` で吸収できます。

---

# 4. `scripts/inventory.sh`

macOS / Linux 用です。

```sh
#!/bin/sh

set -eu

candidates='
~/.gitconfig
~/.gitignore_global
~/.editorconfig
~/.zshrc
~/.zprofile
~/.bashrc
~/.bash_profile
~/.config/git/ignore
~/.config/nvim
~/.config/ghostty
~/.config/alacritty
~/.config/wezterm
~/.config/karabiner
~/.config/Code/User/settings.json
~/.ssh/config
~/.local/bin
'

echo "Existing dotfile candidates:"
echo

for path in $candidates; do
  expanded=$(eval echo "$path")

  if [ -e "$expanded" ]; then
    if [ -d "$expanded" ]; then
      count=$(find "$expanded" -type f | wc -l | tr -d ' ')
      echo "[dir ] $path  files=$count"
    else
      size=$(wc -c < "$expanded" | tr -d ' ')
      echo "[file] $path  size=${size}B"
    fi
  else
    echo "[none] $path"
  fi
done
```

---

# 5. `scripts/inventory.ps1`

Windows 用です。

```powershell
$ErrorActionPreference = "Stop"

$candidates = @(
    "~\.gitconfig",
    "~\.gitignore_global",
    "~\.editorconfig",
    "~\.config\git\ignore",
    "~\.config\nvim",
    "~\.config\alacritty",
    "~\.config\wezterm",
    "~\AppData\Roaming\Code\User\settings.json",
    "~\.ssh\config",
    "~\.local\bin"
)

Write-Host "Existing dotfile candidates:"
Write-Host ""

foreach ($path in $candidates) {
    $expanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)

    if (Test-Path $expanded) {
        $item = Get-Item $expanded

        if ($item.PSIsContainer) {
            $count = Get-ChildItem $expanded -Recurse -File -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
            Write-Host "[dir ] $path  files=$count"
        } else {
            $size = $item.Length
            Write-Host "[file] $path  size=${size}B"
        }
    } else {
        Write-Host "[none] $path"
    }
}
```

---

# 6. `.chezmoiignore.tmpl` の更新

`Taskfile.yml` や `scripts/` はホームディレクトリに配置しないようにします。

```gotemplate
README.md
Taskfile.yml
scripts/
tests/
.github/

{{ if ne .chezmoi.os "darwin" }}
dot_config/karabiner/
{{ end }}

{{ if eq .chezmoi.os "windows" }}
dot_zshrc.tmpl
dot_zprofile.tmpl
{{ end }}
```

Windows で zsh を使うなら最後の除外は外してよいです。  
ただ、まずは Windows ネイティブ運用では zsh 系は除外して安全にするのがよいと思います。

---

# 7. VS Code 設定の扱い

ここは注意点があります。

`dot_config/Code/User/settings.json.tmpl` は主に Linux の XDG パスです。

Windows の VS Code は通常：

```text
~/AppData/Roaming/Code/User/settings.json
```

macOS の VS Code は通常：

```text
~/Library/Application Support/Code/User/settings.json
```

なので、クロスプラットフォームで厳密にやるなら、最終的にはこうするのがよいです。

```text
dot_config/
└── Code/
    └── User/
        └── settings.json.tmpl

AppData/
└── Roaming/
    └── Code/
        └── User/
            └── settings.json.tmpl

Library/
└── Application Support/
    └── Code/
        └── User/
            └── settings.json.tmpl
```

ただし、同じ JSON を3箇所に複製すると保守しづらいです。

最初は以下のどちらかがおすすめです。

## 案A: VS Code は OS ごとに後で導入

最初は Linux 用だけ置く。

```text
dot_config/Code/User/settings.json.tmpl
```

Windows / macOS は実機で確認してから追加。

## 案B: VS Code Settings Sync に任せる

VS Code の設定同期を使うなら、chezmoi では最低限だけ管理します。

個人的には、最初は **案A** が安全です。

---

# 8. Taskfile 導入方法を README に追加

README には以下を追加するとよいです。

```markdown
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
```

---

# 9. README の既存環境導入手順も更新

```markdown
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
```

---

# 10. GitHub Actions CI も Windows を入れる

`.github/workflows/ci.yml` はこうできます。

```yaml
name: CI

on:
  push:
    branches:
      - main
      - master
  pull_request:

jobs:
  test:
    name: Test on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}

    strategy:
      fail-fast: false
      matrix:
        os:
          - ubuntu-latest
          - macos-latest
          - windows-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: stable

      - name: Install chezmoi and Task
        shell: bash
        run: |
          go install github.com/twpayne/chezmoi/v2@latest
          go install github.com/go-task/task/v3/cmd/task@latest
          echo "$(go env GOPATH)/bin" >> "$GITHUB_PATH"

      - name: Install shellcheck on Ubuntu
        if: runner.os == 'Linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck

      - name: Install shellcheck on macOS
        if: runner.os == 'macOS'
        run: |
          brew install shellcheck

      - name: Run tests
        shell: bash
        run: |
          task test
```

Windows では `shellcheck` はスキップし、chezmoi の render / dry-run を通す方針です。

---

# 11. 変更後の実作業順

Yukiさんの手元では、この順番がよいです。

```sh
# 1. Makefile を削除
rm -f Makefile

# 2. scripts/dotfiles も削除
rm -f scripts/dotfiles

# 3. Taskfile.yml を追加
# 4. inventory.sh / inventory.ps1 を追加

# 5. 動作確認
task
task inventory
task render
task test

# 6. 既存環境の確認
task diff
task dry-run
```

その後、低リスクなものから：

```sh
chezmoi add ~/.gitconfig
chezmoi add ~/.config/git/ignore
chezmoi add ~/.zshrc
chezmoi add ~/.zprofile
chezmoi add ~/.config/nvim
chezmoi add ~/.ssh/config
```

確認：

```sh
chezmoi cd
git diff
task diff
task dry-run
```

コミット：

```sh
git add .
git commit -m "Adopt Taskfile-based cross-platform workflow"
```

---

# 12. 結論

はい、クロスプラットフォーム前提なら **Taskfile 採用が自然**です。

特に今回の dotfiles では、

- macOS
- Linux
- Windows
- 新規環境
- 既存カスタム済み環境
- CI

を同じ操作体系で扱いたいので、`scripts/dotfiles` より `Taskfile.yml` の方が合っています。

おすすめの最終方針はこれです。

```text
操作入口: Taskfile.yml
OS固有補助: scripts/inventory.sh / scripts/inventory.ps1
設定管理: chezmoi templates
検証: task render / task test
CI: ubuntu + macos + windows
```

この形なら、README もかなり綺麗にできます。

---

Yukiさん、結論から言うと **`dot_config/nvim/init.lua` だけ `.tmpl` ではないのは「基本的には合っています」**。  
ただし、方針を README に明記した方がよいです。

---

# 1. なぜ `init.lua` は `.tmpl` にしない方がよいか

Neovim の設定は Lua なので、`init.lua.tmpl` にすると中身に Go template が混ざります。

```lua
{{ if eq .chezmoi.os "darwin" }}
-- macOS only
{{ end }}
```

これは chezmoi が render する前は **正しい Lua ではありません**。

そのため、以下が壊れやすくなります。

- `stylua`
- Lua language server
- Neovim 上での補完・診断
- エディタ上での構文ハイライト
- Lua ファイル単体でのテスト

なので、基本方針はこれがよいです。

```text
init.lua は通常の Lua として管理する
OS差分・machine差分は Lua 側で吸収する
chezmoi template は必要最小限にする
```

---

# 2. 推奨構成

`init.lua` は `.tmpl` にせず、必要なら **別ファイルだけ template 化**します。

```text
dot_config/
└── nvim/
    ├── init.lua
    └── lua/
        └── user/
            ├── options.lua
            ├── keymaps.lua
            ├── autocmds.lua
            ├── plugins.lua
            ├── local.lua
            └── chezmoi.lua.tmpl
```

chezmoi 適用後はこうなります。

```text
~/.config/nvim/
├── init.lua
└── lua/
    └── user/
        ├── options.lua
        ├── keymaps.lua
        ├── autocmds.lua
        ├── plugins.lua
        ├── local.lua
        └── chezmoi.lua
```

---

# 3. 具体例

## `dot_config/nvim/init.lua`

```lua
-- Managed by chezmoi

require("user.options")
require("user.keymaps")
require("user.autocmds")

pcall(require, "user.chezmoi")
pcall(require, "user.local")
pcall(require, "user.plugins")
```

---

## `dot_config/nvim/lua/user/options.lua`

```lua
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.termguicolors = true

vim.g.mapleader = " "
```

---

## `dot_config/nvim/lua/user/chezmoi.lua.tmpl`

ここだけ chezmoi template にします。

```gotemplate
-- Generated by chezmoi
-- Do not edit directly.

_G.dotfiles = {
  os = {{ .chezmoi.os | quote }},
  arch = {{ .chezmoi.arch | quote }},
  hostname = {{ .chezmoi.hostname | quote }},
  machine_type = {{ .machine_type | quote }},
}
```

適用後は Lua として正しいファイルになります。

```lua
_G.dotfiles = {
  os = "darwin",
  arch = "arm64",
  hostname = "example-host",
  machine_type = "work",
}
```

---

## `dot_config/nvim/lua/user/local.lua`

これは **任意のローカル上書き用**にできます。

```lua
-- Local Neovim overrides.
-- Keep this file non-secret if committed.
```

機密や端末固有情報を入れたいなら、むしろこのファイルは chezmoi 管理しない方が安全です。

その場合は README にこう書きます。

```text
~/.config/nvim/lua/user/local.lua is intentionally local-only.
Use it for machine-local Neovim overrides.
Do not commit secrets.
```

---

# 4. OS差分は Lua 側でも書ける

chezmoi template を使わなくても、Neovim 側で OS 判定できます。

```lua
local is_mac = vim.fn.has("mac") == 1
local is_linux = vim.fn.has("unix") == 1 and not is_mac
local is_windows = vim.fn.has("win32") == 1

if is_mac then
  vim.opt.clipboard = "unnamedplus"
end

if is_windows then
  vim.opt.shell = "pwsh"
end
```

`machine_type` のような chezmoi 側の値が必要なときだけ、`user.chezmoi.lua.tmpl` を使うのがよいです。

```lua
local machine_type = _G.dotfiles and _G.dotfiles.machine_type or "unknown"

if machine_type == "work" then
  -- work-specific non-secret behavior
end
```

---

# 5. README にはこう追記するのがおすすめ

```markdown
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
```

---

# 結論

`nvim/init.lua` が `.tmpl` ではないのは **正しい方針**です。

おすすめはこれです。

```text
init.lua              → tmpl にしない
通常の Lua 設定       → tmpl にしない
chezmoi 由来の値だけ  → lua/user/chezmoi.lua.tmpl
秘密・端末固有設定    → lua/user/local.lua など Git 管理外
```

この方針なら、chezmoi の柔軟性を使いつつ、Neovim/Lua の開発体験を壊しにくいです。
