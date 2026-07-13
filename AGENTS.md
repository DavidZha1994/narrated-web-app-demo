# narrated-web-app-demo — agent instructions

Portable entry point for coding agents that read `AGENTS.md` (OpenAI Codex CLI,
and any tool that follows the [agents.md](https://agents.md) convention). The
skill itself is a **shell-driven workflow** around the `ndemo` Node CLI — it does
not depend on any Claude-specific runtime, so it works from any agent that can
run shell commands and read/write files.

## Read this first

The full workflow lives in **[`SKILL.md`](SKILL.md)** — read it top to bottom.
Everything there applies unchanged. This file only notes the differences that
matter outside Claude Code.

## Tool mapping

`SKILL.md` was authored for Claude Code, whose tool names appear in its
frontmatter (`allowed-tools: [Bash, Read, Write, Edit, Glob, Grep]`). Other
agents ignore that frontmatter — use your own equivalents:

| SKILL.md (Claude) | Codex / Gemini / generic |
|---|---|
| `Bash`            | your `shell` / exec tool |
| `Read`            | file read |
| `Write` / `Edit`  | file write / `apply_patch` |
| `Glob` / `Grep`   | shell `find` / `rg` |

The workflow body only ever issues plain `$NDEMO …` shell commands, so it is
already portable — no Claude tool call is required to run it.

## Install path

`scripts/install.sh` defaults its install target to `~/.claude/skills/ndemo`,
but the path is **not** Claude-specific — it is just where the `ndemo` binary is
placed. Override it with a positional arg if you keep tooling elsewhere:

```bash
bash scripts/install.sh ~/.local/share/ndemo      # any path you like
export NDEMO=~/.local/share/ndemo/ndemo           # then use $NDEMO throughout
```

Set `OPENAI_API_KEY` and/or `MINIMAX_API_KEY` in your environment for TTS.
Verify with `$NDEMO doctor`.

## Everything else

Playbook authoring, authenticated-app capture, per-segment iteration, rendering,
and the polish block are identical across agents — follow **[`SKILL.md`](SKILL.md)**
and **[`references/`](references/)**.
