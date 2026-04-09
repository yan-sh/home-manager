# AGENTS.md

## Язык

- Общаемся на русском.

## Что это за репозиторий

Личный репозиторий dotfiles для Nix Home Manager. Файлы отслеживаются здесь и подключаются симлинками через `home.file` в `home.nix`.

## Архитектура

- **`home.nix`** — единственный конфиг Home Manager, который реально важен для применения изменений.
  - Импортирует каналы `nixpkgs` и `nixpkgs-unstable`.
  - Здесь описаны пакеты, `zsh`, `git` и все маппинги `home.file.*.source`.
- **`init.lua`** — активная конфигурация Neovim (менеджер плагинов `lazy.nvim`, LSP, keymaps).
- **`tmux.conf`** — конфиг tmux (prefix `C-a`, vi-режим, мышь включена).
- **`alacritty.toml` / `alacritty.yml`** — конфиг Alacritty (в репо есть оба формата).
- **`packman.lua`** — старый кастомный менеджер плагинов Neovim (неактуален).
- **`packer.nvim/`** — вендорный `wbthomason/packer.nvim` (legacy, не используется активной конфигурацией).
- **`ftplugin/haskell.vim`** — локальная настройка Vim для Haskell.
- **`24-bit-color.sh`** — утилита для проверки truecolor в терминале.

## Как применять изменения

```sh
home-manager switch
```

Других команд сборки/тестов/линта в репозитории нет: это чисто конфигурационный репо.

## Важные соглашения

- Плагины Neovim управляются через **lazy.nvim** в `init.lua`, а не через packer/packman.
- Часть пакетов берется из `<nixpkgs-unstable>`; для корректной работы должны быть доступны оба канала.
- `home.stateVersion = "25.05"`; не менять без осознанной миграции.
- Ожидаемые пользователь и домашний каталог: `freak` и `/home/freak`.
- `packer.nvim/` и `packman.lua` считаем устаревшими; актуальный список плагинов находится в `require('lazy').setup({...})` внутри `init.lua`.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
