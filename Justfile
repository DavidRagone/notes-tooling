# Justfile
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Scripts are exposed via .scripts when installed into a private repo
bin := ".scripts"

# --- CI / tests ---
test:
	@bats -r tests

# --- Creation / capture ---
new:
	@{{bin}}/new-journal

# Optional meeting name: pass if provided, omit if empty
meet NAME='':
	@if [ -n "{{NAME}}" ]; then {{bin}}/new-meeting "{{NAME}}" --link; else {{bin}}/new-meeting --link; fi

idea TITLE='':
	@if [ -n "{{TITLE}}" ]; then {{bin}}/new-idea "{{TITLE}}"; else {{bin}}/new-idea; fi

promote SRC_RANGE TITLE:
	@{{bin}}/promote {{SRC_RANGE}} --title "{{TITLE}}"

# --- Calendar & review ---
agenda:
	@{{bin}}/agenda

weekly:
	@{{bin}}/weekly-review

weekly-week WEEK:
	@{{bin}}/weekly-review --week {{WEEK}}

weekly-range START END:
	@{{bin}}/weekly-review --start {{START}} --end {{END}}

# --- Search / tasks / index ---
search QUERY +ARGS:
	@{{bin}}/search {{QUERY}} {{ARGS}}

todo:
	@{{bin}}/todo-refresh

index:
	@{{bin}}/index

archive-done:
  @{{bin}}/archive-done

# --- Convenience bundle ---
daily:
	@{{bin}}/new-journal --no-open
	@{{bin}}/agenda

