---
name: "open-slide-decks"
description: "Author slide decks / presentations with open-slide (agent-native React slide framework), and understand how it is packaged on this machine."
version: 1
created: "2026-09-27"
updated: "2026-09-27"
---
## When to Use
Use when the user asks to build, edit, or export a slide deck / presentation / deck in this environment, mentions open-slide, open-slide.dev, or wants a "簡報 / slides / 投影片" delivered as code. Do not use it for repos that already have a different deck toolchain (reveal.js, marp, Slidev) unless the user asks to switch.

## Procedure
1. Scaffold a workspace with the system-wide binary: `open-slide init <deck-dir>`. Useful flags: `--use-pnpm` (default), `--use-npm`, `--use-yarn`, `--use-bun`, `--no-install`, `--no-git`, `-n/--name <pkg-name>`, `-f/--force` (overwrite a non-empty dir).
2. Install the deck's own deps: `cd <deck-dir> && pnpm install` (or `npm install`). This pulls @open-slide/core + React; it is what provides `dev`/`build`/`preview`.
3. Read the scaffolded authoring reference BEFORE writing any page: `.agents/skills/slide-authoring/SKILL.md` (Claude Code mirror: `.claude/skills/slide-authoring/SKILL.md`) covers the 1920x1080 canvas, type scale, palette and layout rules; `.agents/skills/create-slide/SKILL.md` covers the end-to-end flow and its four scoping questions (topic/aesthetic, page count, text density, motion vs static).
4. Author each page as an arbitrary React component at `slides/<id>/index.tsx` on the fixed 1920x1080 canvas — never a constrained DSL. Register deck folders/order in `slides/.folders.json`; assets (images, video, fonts) live in `assets/` and can be managed via the built-in assets panel.
5. Preview with `pnpm dev`. The dev server has a click-to-comment inspector that persists comments as `@slide-comment` markers in source; after making edits, run the `/apply-comments` skill flow so every pending marker is applied and cleared.
6. Export with `pnpm build` (self-contained static HTML), plus PDF and PPTX from the same CLI. PPTX export runs entirely in the browser and emits native text boxes, shapes and images. Deploy the static build to Vercel / Cloudflare Pages / Netlify / Zeabur / any static host.
7. If the user wants the whole deck built rather than one page edited, just follow the `/create-slide` flow from the scaffolded workspace instead of improvising a structure.

## Pitfalls
- Never exec the CLI straight out of the nix store path. The store canonicalises permissions to 0444/0555, and the scaffolder copies its bundled `template/` verbatim and then rewrites the copied `package.json` — so `init` dies with `EACCES: permission denied, open '<dir>/package.json'` and silently leaves the template default name (`playground`) behind. The PATH wrapper seeds a writable per-version copy at `${XDG_CACHE_HOME:-$HOME/.cache}/open-slide/<version>/lib`, chmods it u+w, and runs from there. Always call `open-slide`, never the store path.
- The system-wide nix package is only `@open-slide/cli` (the scaffolder). `open-slide dev/build/preview` come from the deck's own `@open-slide/core` after install, so they do not exist until `pnpm install` has run.
- Node requirement is `^20.19.0 || >=22.12.0`. On this machine `pnpm` may be absent — enable it with `corepack enable pnpm`, or pass `--use-npm`.
- First invocation copies ~10MB into the cache; concurrent first runs are harmless (same content).
- On this machine the package is defined in the nix-conf repo at modules/open-slide.nix (flake.modules.generic.base → environment.systemPackages). It pins `@open-slide/cli` 2.0.0 in an npm fixed-output derivation, so bumping the tool requires updating BOTH `version` and `outputHash` in that file (build once with `lib.fakeHash` to read the new hash).

## Verification
1. `open-slide --version` prints 2.0.0 (proves the wrapper resolved the cache and node).
2. `open-slide init tmp-deck --no-install --no-git` exits 0, and `tmp-deck/package.json` has `"name": "tmp-deck"` — the EACCES bug would instead leave the template default `playground` and exit non-zero.
3. `test -w tmp-deck/package.json` succeeds, so later edits and `/apply-comments` can write to the scaffolded files.
4. After `pnpm install && pnpm dev`, the dev server serves the deck and `slides/<id>/index.tsx` renders inside the 1920x1080 canvas.