# Justfile
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Helpers
bin := "bin"

# --- Creation / capture ---
new:
	@{{bin}}/new-journal

open:
	@{{bin}}/open-journal

meet NAME?:
	@{{bin}}/new-meeting {{NAME | default("")}} --link

idea TITLE?:
	@{{bin}}/new-idea {{TITLE | default("")}}

promote SRC_RANGE TITLE:
	@{{bin}}/promote {{SRC_RANGE}} --title "{{TITLE}}"

# --- Calendar & review ---
agenda:
	@{{bin}}/agenda-to-md

weekly:
	@{{bin}}/weekly-review

weekly-week WEEK:
	@{{bin}}/weekly-review --week {{WEEK}}

weekly-range START END:
	@{{bin}}/weekly-review --start {{START}} --end {{END}}

# --- Search / tasks / index ---
search QUERY +ARGS='':
	@{{bin}}/search {{QUERY}} {{ARGS}}

todo:
	@{{bin}}/todo-refresh

index:
	@{{bin}}/index

# --- Convenience bundles ---
daily:
	@{{bin}}/new-journal --no-open
	@{{bin}}/agenda-to-md
	@{{bin}}/open-journal

# --- Testing ---
test:
    @bats -r tests
