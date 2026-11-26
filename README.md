# dotfiles

Personal setup for macOS (laptop) and Ubuntu (servers): **zsh, tmux, Vim, git**,
plus **Ghostty, Starship and Zed** on macOS.

The golden rule is **keep it simple and keep it standard**. The laptop is
themed and comfortable, but the keys, behaviours and muscle memory that matter
are the stock ones, so a bare Ubuntu server feels the same:

- tmux keeps the default `Ctrl-B` prefix.
- The Vim core works on a stock Vim with no plugin at all.
- The zsh prompt is vi-mode, but every usual macOS / bash / emacs line-editing
  key still works.

## Contents

1. [Install](#install)
2. [Update](#update)
3. [Layout](#layout)
4. [Vim](#vim)
5. [tmux](#tmux)
6. [Shell (zsh)](#shell-zsh)
7. [Starship prompt](#starship-prompt)
8. [Ghostty](#ghostty)
9. [Git](#git)
10. [Zed](#zed)
11. [Theme](#theme)
12. [Troubleshooting](#troubleshooting)
13. [Design decisions](#design-decisions)

---

## Install

```sh
git clone <this repo> ~/Code/personnel/dotfiles
cd ~/Code/personnel/dotfiles
./bootstrap.sh --dry-run    # preview, changes nothing
./bootstrap.sh
exec zsh
```

Then **quit and reopen Ghostty** (font, Option key and clipboard settings only
apply to new windows) and open new tmux panes (old panes keep the old shell).

Set your git identity once, it is deliberately **not** stored in this repo:

```sh
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

### What `bootstrap.sh` does, in order

1. Detects the platform (macOS, or Ubuntu; anything else aborts).
2. **Links the configs** (symlinks into this repo). Every link is checked
   first: if any target already exists and is not a link to this repo, the
   script stops and **changes nothing**, so you never end up half configured.
3. macOS: installs Homebrew if missing, then runs
   `brew bundle --no-upgrade` on the `Brewfile`, then installs the pinned
   `intelephense` language server with npm.
4. Ubuntu: `apt-get install` of a small list (zsh, fzf, zoxide, direnv,
   ripgrep, fd-find, bat, jq, git, tmux, vim, universal-ctags) and `chsh` to zsh.
5. Installs the Vim plugins (pinned commits) as native packages.

It is safe to run again at any time: existing links and plugins are left alone.

### What each platform gets

| | macOS | Ubuntu |
| --- | --- | --- |
| zsh, tmux, git config | yes | yes |
| Vim core + core plugins | yes | yes |
| Vim `ide` layer (ALE, LSP, linters) | yes | no |
| Starship prompt | yes | no (plain zsh prompt) |
| Ghostty, Zed, fonts, Homebrew tools | yes | no |

Ubuntu keeps a plain prompt on purpose: Starship is not packaged for the
current LTS releases, and servers should stay lean.

---

## Update

| What | How |
| --- | --- |
| The dotfiles themselves | `git pull` in the repo. Links are symlinks, so changes are live. Re-run `./bootstrap.sh` only if a file was added. |
| Homebrew tools | `brew upgrade` (on purpose: `bootstrap.sh` never upgrades). New entries: `brew bundle --no-upgrade`. |
| A Vim plugin | Get the new commit with `git ls-remote https://github.com/<user>/<repo>.git HEAD`, put it in `config/vim/plugins.txt`, run `config/vim/install-plugins.sh`. |
| Add a Vim plugin | Add a line to `plugins.txt` (`group repo commit`) and run `install-plugins.sh`. Group `core` goes everywhere, `ide` is macOS only. |
| `intelephense` | Bump `INTELEPHENSE_VERSION` in `bootstrap.sh`, run `./bootstrap.sh`. |
| tmux config | `tmux source ~/.tmux.conf` (or `prefix r` inside tmux). |
| Zed extensions | Listed in `config/zed/extensions.txt` for reference only; install by hand with `zed --install-extension <name>`. |

Plugins are pinned to exact commits and installed as native Vim packages (no
plugin manager) into `~/.vim/pack/plugins/start/`. `install-plugins.sh
--dry-run` shows what would change.

To uninstall, delete the symlinks listed in [Layout](#layout).

---

## Layout

| Path in this repo | Linked to | Platform |
| --- | --- | --- |
| `config/zsh/zshenv` | `~/.zshenv` | both |
| `config/zsh/zprofile` | `~/.zprofile` | both |
| `config/zsh/zshrc` | `~/.zshrc` | both |
| `config/tmux/tmux.conf` | `~/.tmux.conf` | both |
| `config/vim/vimrc` | `~/.vimrc` | both |
| `config/vim/ide.vim` | `~/.vim/ide.vim` | both (only active when plugins exist) |
| `config/git/config` | `~/.config/git/config` | both |
| `config/starship/starship.toml` | `~/.config/starship.toml` | macOS |
| `config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` | macOS |
| `config/zed/settings.json`, `keymap.json` | `~/.config/zed/` | macOS |
| `config/glow/gruvbox.json` | `~/.config/glow/gruvbox.json` | macOS |
| `config/vim/plugins.txt` | read by `install-plugins.sh` | both |
| `Brewfile` | read by `brew bundle` | macOS |

---

## Vim

Two layers:

- **`vimrc` (portable core).** Works with a stock Vim and no plugin. Loads
  Vim's bundled defaults, sets sane options, and works on any server.
- **`ide.vim` (plugin layer).** Sourced last, only if it exists. Every block is
  guarded on its plugin being installed, so a machine with some or none of the
  plugins still starts cleanly. ALE, language servers and linters are macOS
  only; the fzf, git and editing plugins work on Ubuntu too.

**Leader key: `Space`.** Vim 8.1+ is required for the plugin layer.

### Find and open (fzf + ripgrep)

| Keys | Action |
| --- | --- |
| `<Space>f` | Fuzzy **file name** finder with preview. Respects `.gitignore` |
| `<Space>a` | Same, but **includes ignored files** (`vendor/`, `node_modules/`) |
| `<Space>/` | **Live content search** (ripgrep re-runs on every keystroke) |
| `<Space>?` | Live content search that **ignores `.gitignore`** (search `vendor/`) |
| `<Space>*` | Search the word under the cursor |
| `<Space>b` | Open buffers |
| `<Space>H` | Recently opened files |
| `<Space>o` | Outline of the current file (functions, classes, via ctags) |
| `<Space>s` | **Symbol search**: type a class or function name across the whole project, `Enter` |
| `-` | Open the parent directory (vinegar). `-` again goes up |
| `<Space><Space>` | Clear search highlighting |
| `<Space>m` | **Preview the Markdown file** (see below) |

Inside any fzf list: type to filter, `Ctrl-J/K` or arrows to move, `Enter` to
open, `Ctrl-T` / `Ctrl-X` / `Ctrl-V` to open in a tab / split / vsplit, `Tab`
to mark several results, then `Enter` to send them to the **quickfix list**.

Other fzf commands (type them with `:`): `:GFiles` (tracked files), `:GFiles?`
(changed files), `:Lines`, `:BLines` (search lines in all / this buffer),
`:Tags`, `:BTags`, `:Marks`, `:Commits`, `:BCommits`, `:Commands`, `:Maps`,
`:Helptags`, `:Filetypes`, `:Windows`.

### Project-wide refactors with the quickfix list

1. Search with `<Space>/`, mark results with `Tab`, press `Enter`.
2. `:copen` shows the list; `]q` / `[q` move through it.
3. `:cdo s/old/new/g | update` edits every entry; `:cfdo` once per file.
4. `:cfilter /pattern/` narrows the list (the `cfilter` package is loaded).

`:grep` is wired to ripgrep as well (`:grep foo`), and `:find <part of name>`
works on the whole project (`path+=**`).

### Code intelligence (ALE, macOS only)

| Keys | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `<Space>rn` | Rename symbol (**PHP: needs an Intelephense licence**, use `:Rg` + `:cdo` instead) |
| `<Space>ca` | Code actions |
| `<Space>d` | Full diagnostic message |
| `]d` / `[d` | Next / previous diagnostic |
| `<Space>F` | Fix the file now (prettier where configured) |
| `Ctrl-O` / `Ctrl-I` | Jump back / forward after `gd` (stock Vim) |
| `Tab` / `Shift-Tab` | Walk the completion menu; `Enter` accepts the selected item |

Languages and tools (a missing tool is skipped silently; check with `:ALEInfo`):

| Language | Linter / language server | Fixer |
| --- | --- | --- |
| PHP | intelephense (free tier: definitions, references, hover, completion) | none, on purpose |
| JavaScript, TypeScript | tsserver, eslint | prettier (on demand) |
| Vue | volar, eslint | prettier (on demand) |
| JSON | vscode-json | prettier (on demand) |
| Go | gopls | gofmt on save |
| Terraform | terraform-ls | `terraform fmt` on save |
| YAML | yamllint | trim whitespace |
| Ansible | ansible-lint | |
| Dockerfile | hadolint | trim whitespace |
| Shell | bash-language-server (+ shellcheck) | trim whitespace |

On save, ALE trims trailing whitespace only on shell, YAML and Dockerfile
files. **PHP is never reformatted**, so legacy code gets no noisy diffs.
Prettier never runs on save, only with `<Space>F`. Project-local tools in
`node_modules/.bin` win over global ones.

PHP code runs in Docker for you, so phpstan and the tests are meant to run in
a tmux pane inside the container, not through Vim. Intelephense reads the
bind-mounted source on the host.

### Markdown

- **`<Space>m`** (in a `.md` buffer) saves the file and shows it **rendered**
  with [glow](https://github.com/charmbracelet/glow): styled titles, bold and
  italic text, lists, task lists, tables, quotes, links and syntax-highlighted
  code blocks, in a scrollable pager. Inside tmux it opens in a **popup** over
  Vim; elsewhere it takes the whole screen. `q` closes it and you are back in
  Vim at the same place. Needs `glow` (macOS: in the Brewfile). The look comes
  from `config/glow/gruvbox.json` (see [Markdown style](#markdown-style)).
- Code inside fenced blocks (php, sh, yaml, json, go, html, javascript,
  dockerfile, terraform) is **syntax highlighted** in the editor itself.
- `gc` / `gcc` comments lines, and `gx` opens the link under the cursor.

Outside Vim, use `md` in the shell (see [Shell](#shell-zsh)).

### Git (fugitive + gitgutter)

| Keys | Action |
| --- | --- |
| `<Space>gs` | Git status window (`-` stage/unstage, `cc` commit, `dv` diff) |
| `<Space>gd` | Diff split of the current file |
| `<Space>gb` | Blame |
| `<Space>gl` | Log graph |
| `]c` / `[c` | Next / previous changed hunk |
| `<Space>hs` / `hp` / `hu` | Stage / preview / undo the hunk under the cursor |
| `ic` / `ac` | Hunk text objects (e.g. `dic`) |

The status line shows the current branch and, on macOS, ALE error and warning
counts (`E:2 W:1`). Changed lines show in the sign column.

### Editing plugins

- **vim-surround:** `ysiw"` surround a word, `cs"'` change quotes, `ds(` delete
  the pair, `S"` in visual mode.
- **vim-repeat:** makes `.` repeat surround and unimpaired commands.
- **vim-unimpaired:** `]q [q` quickfix, `]b [b` buffers, `]f [f` files,
  `]<Space> [<Space>` add blank lines, `[e ]e` move lines, and toggles such as
  `yow` (wrap), `yon` (numbers), `yoh` (highlight), `yol` (list characters).
- **vim-vinegar:** `-` opens the directory view; `~` goes home, `.` builds a
  shell command with the file under the cursor.
- **vim-eunuch:** `:Rename`, `:Move`, `:Delete`, `:Mkdir`, `:Chmod`,
  `:SudoWrite`, `:SudoEdit`, `:Remove`, `:Unlink`.
- **Filetype support:** helm, ansible, terraform (`:TerraformFmt`).

Bundled with Vim 9 and loaded when present: `matchit` (`%` jumps between
tags and keywords), `comment` (`gc` / `gcc` toggle comments), `editorconfig`,
`cfilter`.

### Core settings (work everywhere)

- **Display:** line numbers (relative in normal mode, absolute in insert),
  cursor line, sign column always on, 5 lines of scroll margin, no wrapping,
  visible tabs / trailing spaces / non-breaking spaces, truecolor when the
  terminal supports it, 256 colors on a basic `$TERM`.
- **Indent:** 4 spaces, 2 for YAML, Helm and Terraform.
- **Search:** case-insensitive, becoming case-sensitive when you type a capital;
  results highlighted.
- **Files:** no backup files; swap and persistent **undo** live in `~/.vim`
  (private). Files changed outside Vim are reloaded automatically.
- **Secrets are never written to swap, undo or viminfo** for `.env`, `*.pem`,
  `*.key`, `*.tfvars`, `*.tfstate`, `*secret*`, `*vault*`, `~/.ssh`, `~/.aws`,
  `~/.kube`, `~/.gnupg`, `/tmp`, `/etc`, and the files that `kubectl edit`,
  `crontab -e` and `sudoedit` create.
- **Clipboard:** yanks and deletes use the system clipboard. **Over SSH**, plain
  `y` yanks are sent to your Mac clipboard through OSC 52 (works through tmux
  too), so copying from a remote Vim just works.
- **Mouse:** enabled.
- **Tags:** `<C-]>` jumps to a tag; generate them with `ctags -R .`.
- **Tools:** `:grep` uses ripgrep; `vendor`, `node_modules`, `.git` and
  `.terraform` are excluded from file-name completion.

### Vim habits worth building

These are stock Vim, so they work on every server:

- `Ctrl-^` toggles between the last two files (the single most useful key).
- `Ctrl-O` / `Ctrl-I` walk the jump history; `''` returns to the last position.
- `gf` opens the file under the cursor; `*` and `#` search the word under it.
- Text objects: `ci"`, `ci(`, `dit`, `yap`, `vi{`; `.` repeats the last change;
  `cgn` then `.` replaces matches one by one.
- Macros `qa` ... `q`, replay with `@a`; marks `ma`, jump with `'a`.
- `:g/pattern/d`, `:g/pattern/norm A;` run a command on every matching line.
- `:cdo` / `:argdo` for edits across files.

---

## tmux

Default `Ctrl-B` prefix, kept on purpose so it matches every remote machine.
`prefix` below means `Ctrl-B`.

| Keys | Action |
| --- | --- |
| `prefix c` | New window in the current directory |
| `prefix %` / `prefix "` | Split right / below, in the current directory |
| `prefix h j k l` | Move between panes (arrows also work) |
| `prefix H J K L` | Resize panes by 5 cells (hold to repeat) |
| `prefix [` | Copy mode (Vim keys) |
| `prefix r` | Reload `~/.tmux.conf` |
| `prefix z` | Zoom the pane (a `Z` shows next to the window name) |
| `prefix d` | Detach |
| `prefix ,` | Rename the window |
| `prefix w` | Session and window tree |
| `prefix n` / `prefix p` | Next / previous window |
| `prefix x` | Close the pane |

**Copy mode:** `prefix [`, move with `h j k l`, `/` to search, `v` to start
selecting (`Ctrl-V` for a rectangle), `y` to copy and leave. Copies reach the
Mac clipboard through OSC 52, including from a remote machine. Mouse
selection copies the same way.

**Behaviour:** mouse on, 50,000 lines of history, windows and panes numbered
from 1, windows renumber when one closes, `escape-time` 10 ms (no lag on
`Esc` in Vim), true color, focus events on (Vim auto-reload works inside tmux).

**Shell alias:** `ta` attaches to the session `main`, or creates it
(`tmux new -As main`).

### Status bar

Gruvbox with powerline arrows. It needs a Nerd Font (Maple Mono NF).

- **Left:** the session name in a green block. It **turns orange while the
  prefix is active**, so you can see that tmux is listening.
- **Windows:** inactive windows are dim; the current window is a **yellow
  block**, with `Z` when zoomed.
- **Right:** date and time, then the host name (useful when sessions nest).
- Pane borders are dark gray, the active pane border is green. Messages and
  the copy-mode selection are yellow.

To change colors, edit the hex values in `config/tmux/tmux.conf` (the palette
is listed in a comment) and run `prefix r`.

---

## Shell (zsh)

### Vi mode at the prompt

`Esc` switches to normal mode (the prompt character becomes `❮`), `i` / `a`
go back to insert. In normal mode: `h l w b e 0 $` move, `x dw cw D` edit,
`/` and `?` search history, `k` / `j` browse it, `v` edits the command in Vim.

In **insert mode all the usual keys still work**, like in any shell on macOS:

| Keys | Action |
| --- | --- |
| `Ctrl-A` / `Ctrl-E` | Start / end of line |
| `Ctrl-B` / `Ctrl-F` | Back / forward one character |
| `Alt-B` / `Alt-F` (left Option) | Back / forward one word |
| `Ctrl-K` / `Ctrl-U` / `Ctrl-W` | Kill to end / to start / previous word |
| `Alt-D` | Kill next word |
| `Ctrl-Y` | Paste what you killed |
| `Ctrl-P` / `Ctrl-N` | Previous / next history entry |
| `Ctrl-X Ctrl-E` | Edit the command line in Vim |

`KEYTIMEOUT` is 10 ms, so `Esc` is instant.

### fzf, zoxide, direnv

| Keys / command | Action |
| --- | --- |
| `Ctrl-R` | Fuzzy history search (gruvbox colors) |
| `Ctrl-T` | Fuzzy file picker; inserts the path (`vim ` then `Ctrl-T`) |
| `Alt-C` | Fuzzy `cd` into a subdirectory |
| `**<Tab>` | Fuzzy completion, e.g. `vim **<Tab>`, `kill <Tab>` |
| `z <part of path>` | Jump to a directory you visited before (zoxide) |
| `zi` | Same, with an interactive picker |

direnv loads and unloads `.envrc` files when you `cd`. On older fzf versions
(Ubuntu apt) the integration scripts are sourced instead of `fzf --zsh`.

### Markdown in the terminal

| Command | Action |
| --- | --- |
| `md file.md` | Render the file in a scrollable pager (`q` to quit) |
| `md` | Browse the Markdown files of the current directory (glow's file browser) |
| `glow -p file.md` | Same renderer, called directly; `glow https://...` renders a remote README |
| `bat file.md` | Syntax-highlighted source, not rendered |

`md` uses glow when installed (macOS) and falls back to `bat`, then `less`,
so it also works on Ubuntu servers. `GLOW_STYLE` points glow at the gruvbox
style, so a plain `glow file.md` is styled the same way.

### Markdown style

glow's built-in `dark` style paints background blocks (violet behind titles,
gray behind inline code) that clash with gruvbox and a translucent terminal.
`config/glow/gruvbox.json` (linked to `~/.config/glow/gruvbox.json`) uses
**no background colors at all**:

| Element | Rendering |
| --- | --- |
| `#` title | yellow, bold, underlined, with a `▌` marker |
| `##` title | green, bold, underlined |
| `###` to `######` | aqua, blue, purple, gray, bold, with the `#` marks kept |
| Bold / italic / strike | orange bold / purple italic / gray crossed out |
| Inline code | orange |
| Code blocks | gruvbox syntax highlighting, indented |
| Links | blue bold text, gray underlined URL |
| Quotes | gray italic with a `▌` bar |
| Lists, tasks | `•` bullets, numbers, `[✓]` and `[ ]` |
| Tables | box-drawing borders |

To change a color, edit the hex values in that file and preview again (no
restart needed). The code-block colors are quantized to the 256-color palette by
the renderer, so they are close to, not exactly, the gruvbox hexes.

### Options

- History: 50,000 entries, shared between terminals, no consecutive
  duplicates, commands starting with a space are not saved, extra blanks
  removed.
- `# comment` lines can be pasted at the prompt.
- Completion is on; `k` completes like `kubectl`.
- `$EDITOR` and `$VISUAL` are `vim`; `LANG` is `en_US.UTF-8`.
- `PATH` has no duplicates and `~/.local/bin` comes first.
- `bat` uses the `gruvbox-dark` theme. On Ubuntu, `bat` and `fd` aliases map to
  `batcat` and `fdfind`.

### Aliases

| Alias | Command |
| --- | --- |
| `gws` | `git status` |
| `gia` | `git add` |
| `gcm` | `git commit --message` |
| `gcam` | `git commit --all --message` |
| `gp` | `git push` |
| `gl` | `git log` |
| `gwd` | `git diff` |
| `glg` | `git log --oneline --decorate --graph` |
| `gltag` | `git describe --abbrev=0 --tags` |
| `t` | `tmux` |
| `ta` | `tmux new -As main` |
| `dk` | `docker` |
| `k` | `kubectl` |

### Tools installed by the Brewfile

Shell: starship, fzf, zoxide, direnv. CLI: ripgrep, fd, bat, jq, yq, glow. Terminal:
tmux, vim. Git: git. DevOps: awscli, kubectl, helm, k9s, terraform, ansible.
Editor tooling: node, go, gopls, universal-ctags, shellcheck, hadolint,
yamllint, ansible-lint, prettier, terraform-ls, bash-language-server,
vscode-langservers-extracted. Apps: Ghostty, Zed, OrbStack, Vivaldi. Fonts:
Maple Mono NF, Victor Mono.

---

## Starship prompt

macOS only, two lines: a row of rounded **pills**, then the `❯` prompt
character. Each pill draws its own caps, so it can appear or disappear without
leaving gaps. A blank line separates commands.

| Pill | Color | Shows |
| --- | --- | --- |
| Directory | yellow | Path with `~` for home, last 4 components; a longer path is cut and marked `…/` (`…/vinatis/devops/internal/outline`). Lock icon if read-only |
| Git branch | green | Branch name |
| Git status | orange | **Only appears when there is something to show** (hidden in a clean repo). `$` stashed, `!` modified, `+` staged, `?` untracked, `»` renamed, `✘` deleted, `⇡` ahead, `⇣` behind, `⇕` diverged |
| Kubernetes | blue | Context and namespace. **Only in Kubernetes projects** (`Chart.yaml`, `kustomization.yaml`, `helmfile.yaml`, or a `k8s`, `kubernetes`, `helm`, `charts`, `.kube` folder) |
| Docker | aqua | Docker context. Only where a `Dockerfile` or a compose file exists |
| Exit status | red | The exit code of a failed command |

The prompt character is **green** after success, **red** after a failure, and
becomes a yellow `❮` in vi normal mode.

---

## Ghostty

- **Look:** Gruvbox Dark, Maple Mono NF 13 pt, 90% opacity with blur, 7 px
  padding, hidden title bar, blinking block cursor, mouse hidden while typing,
  a size overlay while resizing.
- **Quick terminal:** `Cmd-Shift-Space` (global) slides a terminal in from the
  right, 70% of the screen, on the main display.
- **Option key:** the **left Option acts as Alt** (Alt-B / Alt-F in zsh, Vim,
  tmux). The **right Option stays a normal modifier**, so AZERTY characters
  such as `{ [ | ~` still type.
- **Clipboard:** programs may **write** (this is what makes yanking from
  tmux and Vim over SSH work). **Reading is set to ask**, so a remote server
  cannot silently read your clipboard. Selecting text copies it.
- **SSH:** the shell integration installs the `xterm-ghostty` terminfo on the
  remote machine or falls back to `xterm-256color`, so colors and keys work
  on servers that do not know Ghostty. It also provides the cursor, title and
  sudo integrations.
- `ghostty +list-keybinds` shows every shortcut; `ghostty +validate-config`
  checks the config file.

---

## Git

`config/git/config` is linked to `~/.config/git/config`. Git reads it
together with `~/.gitconfig`, which keeps your name and e-mail.

| Setting | Effect |
| --- | --- |
| `core.editor = vim` | Vim for commit messages |
| `pull.rebase = true` | `git pull` rebases instead of creating merge commits |
| `push.autoSetupRemote = true` | First `git push` of a branch sets the upstream |
| `fetch.prune = true` | Deleted remote branches disappear locally |
| `merge.conflictStyle = diff3` | Conflict markers also show the common ancestor |
| `diff.algorithm = histogram` | Better-quality diffs |

`diff3` is used instead of `zdiff3` because Ubuntu 22.04 ships git 2.34, which
fails on `zdiff3`.

---

## Zed

Kept as a secondary editor, with Vim mode on and the same Gruvbox theme:

- Vim mode, relative line numbers, 4-space tabs, format on save, inlay hints,
  inline diagnostics, Operator Mono font, soft wrap.
- Intelephense is used for PHP (phpactor disabled); Helm file types are mapped
  for `templates/` and `helmfile.d/`.
- Edit predictions are off on secret files; the AI agent is disabled.
  **Telemetry is still on** (`diagnostics` and `metrics`): change it in
  `settings.json` if you want it off.

---

## Theme

**Gruvbox dark** everywhere: Ghostty, Vim, tmux, Starship, fzf, bat and Zed.

| Role | Hex |
| --- | --- |
| Background | `#282828` / `#3c3836` / `#504945` |
| Foreground | `#ebdbb2` |
| Gray | `#928374` / `#a89984` |
| Green | `#98971a` / `#b8bb26` |
| Yellow | `#d79921` / `#fabd2f` |
| Orange | `#d65d0e` / `#fe8019` |
| Blue | `#458588` |
| Aqua | `#689d6a` / `#8ec07c` |
| Red | `#cc241d` / `#fb4934` |

The **Maple Mono NF** font (Nerd Font) supplies the icons for the tmux status
bar and the Starship pills. Without it you will see empty boxes: run
`brew bundle --no-upgrade` and restart Ghostty.

---

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `command not found: bind` / `setw` after reloading tmux | You ran `source ~/.tmux.conf` in the shell. The command is **`tmux source ~/.tmux.conf`**. Close that terminal tab: zsh executed the tmux file and changed some shell options. |
| Empty boxes in the prompt or tmux bar | Maple Mono NF is not installed, or Ghostty was not restarted. |
| Prompt is not in vi mode | The shell started before the change. Open a new tab or pane. |
| Vim shows no plugin features | `./config/vim/install-plugins.sh` has not run, or this is an Ubuntu host (ALE is macOS only). |
| `gd` / `K` / completion do nothing in PHP | `intelephense` is not installed or not on `PATH`. Check `npm ls -g intelephense` and `:ALEInfo`. |
| `<Space>rn` fails in PHP | Intelephense rename is a paid feature. Use `<Space>/` + `:cdo`. |
| Colors look wrong over SSH | Check `echo $COLORTERM $TERM`; Vim uses 256 colors when truecolor is not advertised. |
| Remote yank does not reach the Mac clipboard | Inside tmux, `set -g set-clipboard on` must be active (it is in this config); outside tmux Ghostty must allow clipboard writes. |
| `bootstrap.sh` stops with "already exists" | A real file sits where a link should go. Move it away (check it first), then run again. Nothing was changed. |
| `shellcheck` | `shellcheck bootstrap.sh config/vim/install-plugins.sh` |

---

## Design decisions

- **Stay standard.** No custom prefix in tmux, no remapped core Vim keys, no
  plugin manager. Everything beyond stock sits under `<Space>` in Vim.
- **Portable core, optional layer.** The vimrc works alone; `ide.vim` only
  adds. A machine without plugins behaves like plain Vim.
- **Pinned and reproducible.** Vim plugins are pinned to commits;
  `intelephense` is pinned; `brew bundle` never upgrades silently.
- **Safe by default.** No backup files, secrets excluded from swap and undo,
  clipboard reads from the terminal set to ask, links checked before any change.
- **Vim over Neovim, for now.** The skills transfer; Vim is what servers have.
  Revisit if ALE's LSP support becomes limiting.
- **No whitespace or formatter surprises in legacy PHP.** PHP files are never
  reformatted on save.
