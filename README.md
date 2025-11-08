# notes-tooling

CLI utilities and templates for a terminal-native note system (vim + tmux +
ripgrep + llm).
Designed so the tooling is public while your notes live in a separate, private repo.

## Purpose

Keep notes as plain Markdown in a predictable tree, automate the boring parts
(new daily note, meeting notes, weekly review), and add sharp, composable
commands for search, agenda import, task roll-ups, and LLM-powered
summaries—without leaving the terminal.


## Setup

```sh
brew install just # [Docs](https://github.com/casey/just)
pip install files-to-prompt # [Docs](https://github.com/simonw/files-to-prompt)
```
# notes-tooling

CLI utilities and templates for a terminal-native note system (vim + tmux + ripgrep + `llm`).
Designed so the **tooling is public** while your **notes live in a separate, private repo**.

---

## 1) Purpose

Keep notes as plain Markdown in a predictable tree, automate the boring parts (new daily note, meeting notes, weekly review), and add sharp, composable commands for search, agenda import, task roll-ups, and LLM-powered summaries—without leaving the terminal.

---

## 2) Setup

You can use this repo in two ways.

### A) Recommended: vendored inside your private notes repo

1. In your private repo (e.g., `~/notes`), clone this public repo into `.tooling/`:

   ```bash
   cd ~/notes
   git clone https://github.com/<you>/notes-tooling .tooling
   ln -sfn .tooling/bin .scripts
   echo 'export NOTES_DIR="$PWD"' >> .envrc   # if you use direnv
   echo 'export PATH="$PWD/.scripts:$PATH"' >> .envrc
   ```

   Then `direnv allow`, or export the two lines in your shell rc.

2. (Optional) Pin a version:

   ```bash
   echo v0.1.0 > .tooling-version
   (cd .tooling && git fetch --tags && git checkout v0.1.0)
   ```

3. (Optional) Use the provided `install.sh` from your **private** repo (it automates the steps above, creates core folders, writes a helpful `Justfile`, etc.).

### B) Standalone: install anywhere and point `NOTES_DIR` at your notes

```bash
git clone https://github.com/<you>/notes-tooling ~/code/notes-tooling
echo 'export PATH="$HOME/code/notes-tooling/bin:$PATH"' >> ~/.zshrc
echo 'export NOTES_DIR="$HOME/notes"' >> ~/.zshrc
```

### Requirements

* macOS/Linux with bash
* `rg` (ripgrep)
* `awk`, `sed`, `iconv`, `python3`
* Optional but recommended:

  * `gcalcli` (Google Calendar → Markdown agenda)
  * `llm` (Simon Willison’s CLI) and optionally `files-to-prompt`
  * `just` (nice task runner)
  * `glow` (Markdown viewer)
  * `direnv` (for per-repo PATH/vars)

Install examples (Homebrew):

```bash
brew install ripgrep just glow python3
brew install gcalcli          # optional
# llm: follow https://github.com/simonw/llm
```

---

## 3) How to use

### Directory conventions (defaults)

This toolkit assumes a private repo like:

```
~/notes/
  journal/YYYY/YYYY-MM/YYYY-MM-DD.md
  meetings/YYYY/YYYY-MM/YYYY-MM-DD-<slug>.md
  ideas/<slug>.md
  reviews/YYYY/YYYY-WW.md
  todo/TODO.md
  people/
  .index/embeddings.db
  .tooling/      # this public repo (cloned here)
  .scripts -> .tooling/bin  # symlink
```

> The scripts autodetect `NOTES_DIR` when the repo lives at `<notes>/.tooling/`. Otherwise set `NOTES_DIR` explicitly.

### Templates

* `templates/journal.md`, `templates/meeting.md`, `templates/idea.md` are used if present.
* Each note begins with a small YAML front-matter (date, type, tags, etc.).

### Typical day

```bash
just daily            # creates/opens today’s journal and appends today’s agenda
# ... take notes in vim ...
just todo             # rebuilds a unified task list from unchecked boxes
just index            # re-embed notes for LLM search
just weekly           # generate a weekly review (links, actions, optional LLM summary)
```

---

## 4) Commands (what each script does)

All scripts live in `bin/`. You can run them directly (`.scripts/<name>`) or via `just` targets shown below.

### Creation / capture

* **`new-journal`** → Create (or open) today’s journal at `journal/YYYY/YYYY-MM/YYYY-MM-DD.md`.

  * Options: `--date YYYY-MM-DD`, `--title "Title"`, `--no-open`
  * `just new` calls this.

* **`new-meeting [NAME]`** → Create a meeting note at `meetings/YYYY/YYYY-MM/YYYY-MM-DD-<slug>.md`.

  * Prompts if `NAME` omitted.
  * Options: `--date YYYY-MM-DD`, `--link` (backlink into that day’s journal), `--no-open`
  * `just meet "Payroll sync"` calls this.

* **`new-idea [TITLE]`** → Create an idea note at `ideas/<slug>.md` (or `YYYY-MM-DD-<slug>.md` with `--dated`).

  * Options: `--project KEY`, `--tags "a,b"`, `--date`, `--no-open`
  * `just idea "Faster onboarding checklist"`

### Calendar & review

* **`agenda-to-md`** → Append today’s Google Calendar to the journal under `## Meetings`.

  * Uses `gcalcli` and writes meeting headings with time/location/attendees.
  * `just agenda` calls this.

* **`weekly-review`** → Build `reviews/YYYY/YYYY-WW.md` for the current ISO week.

  * Links source notes in range (journals + meetings).
  * Extracts **Decisions** sections and **open tasks**.
  * If `llm` (+ `files-to-prompt`) is available, generates a concise weekly summary.
  * Options: `--week YYYY-WW` or `--start YYYY-MM-DD --end YYYY-MM-DD`, `--no-llm`, `--model NAME`.
  * `just weekly`, `just weekly-week 2025-45`, or `just weekly-range 2025-11-03 2025-11-09`.

### Refactoring

* **`promote <FILE.md:START..END> --title "TITLE"`** → Extract a block from any note into a new standalone file and leave a link-back in the source.

  * Destinations: default `notes/YYYY/YYYY-MM/YYYY-MM-DD-<slug>.md`, or `--dest ideas`, `--dest meetings`, `--dest projects/KEY`, or a concrete path.
  * Options: `--date`, `--type note|idea|meeting`, `--no-open`, `--dry-run`.
  * Example:

    ```bash
    .scripts/promote journal/2025/2025-11/2025-11-07.md:42..81 \
      --title "API rollout plan" --dest projects/gep
    ```

### Search / tasks / embeddings

* **`search REGEX [rg-args…]`** → Opinionated `ripgrep` wrapper over `NOTES_DIR` (ignores `.git`, `.index`, `.tooling`, `node_modules`, etc.).

  * Example: `.scripts/search '^tags:.*roadmap'`

* **`todo-refresh`** → Rebuild `todo/TODO.md` from all unchecked `- [ ]` items, linking back to file+line for context.

  * `just todo`

* **`index`** → Build or refresh embeddings to `./.index/embeddings.db` using `llm embed-multi`.

  * Configure model via `LLM_MODEL_EMBED` (defaults to `text-embedding-3-small`).
  * `just index`

* **`open-journal`** → Open today’s journal in `$EDITOR`.

  * `just open`

### Convenience bundles (via `Justfile`)

* **`just new`** → `new-journal`
* **`just meet "NAME"`** → `new-meeting "NAME" --link`
* **`just idea "TITLE"`** → `new-idea`
* **`just agenda`** → `agenda-to-md`
* **`just weekly`** → `weekly-review`
* **`just weekly-week 2025-45`**, **`just weekly-range START END`**
* **`just search 'regex'`**
* **`just todo`**, **`just index`**
* **`just daily`** → create journal, append agenda, open journal

---

## Configuration

Environment variables (all optional):

* `NOTES_DIR` — absolute path to your private notes root.
  Auto-detected if this repo lives at `<notes>/.tooling/`.
* `JOURNAL_DIR`, `MEETINGS_DIR`, `TODO_DIR`, `INDEX_DIR`, `TEMPLATES_DIR` — override subpaths.
* `EDITOR_CMD` — command to open files (defaults to `$EDITOR` or `vim`).
* `LLM_MODEL_EMBED` — embedding model for `index` (default `text-embedding-3-small`).
* `LLM_MODEL_SUMMARY` — model for `weekly-review` summaries (default `o3-mini`).
* `GCAL_ARGS` — extra flags for `gcalcli` agenda (e.g., `--details=... --tsv`).

---

## Updating & pinning

* Keep this public repo versioned with tags (`v0.1.0`, `v0.2.0`, …).
* In your private repo, record the desired version in `.tooling-version` and checkout that tag inside `.tooling/`.
* Re-run your private repo’s `install.sh` or:

  ```bash
  (cd .tooling && git fetch --tags && git checkout $(cat .tooling-version))
  ```

---

## Notes on privacy and backups

* Your private repo should **not** track `.tooling/` (it’s public code). Add `.tooling/` to `.gitignore` if you won’t pin via submodule.
* Consider encrypting sensitive subtrees (`people/`, transcripts) with `age`/`rage` or `git-crypt`.
* For long-term hygiene, archive old months (`journal/YYYY/YYYY-MM/`) into tarballs or exclude from sync if needed.

---

## FAQ (quick hits)

* **It can’t find my notes root.** Set `export NOTES_DIR="/absolute/path/to/notes"` or place this repo at `<notes>/.tooling/`.
* **`weekly-review` is slow or too long.** Use `--no-llm` or ensure `files-to-prompt` is installed; limit prompt size by editing the script’s fallback concat.
* **Calendar import missing details.** Tweak `GCAL_ARGS` (e.g., `--details=location,description,attendees`) and confirm `gcalcli` is authenticated.

---

## License

MIT for the tooling code. Your notes are yours; keep them in a separate, private repository.

---

## Roadmap (nice extras to add later)

* `new-people`, `new-project`
* `export` (Pandoc wrapper to PDF/DOCX)
* `summarize-note` (LLM one-pager)
* Git hooks to auto-index on commit

Happy typing.

