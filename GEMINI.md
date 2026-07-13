# narrated-web-app-demo — Gemini CLI context

This project is a **shell-driven workflow** around the `ndemo` Node CLI for
producing narrated demo videos of web apps. It has no Claude- or Gemini-specific
runtime dependency: any agent that can run shell commands and read/write files
can drive it.

The complete workflow is imported below. Read it in full, then follow it — the
`$NDEMO …` commands are plain shell and run unchanged under Gemini CLI.

@SKILL.md

## Gemini-specific notes

- **Tool names**: `SKILL.md`'s frontmatter (`allowed-tools: [Bash, Read, …]`) is
  Claude Code syntax — Gemini ignores it. Use your shell tool for the `Bash`
  steps and your file tools for `Read`/`Write`/`Edit`.
- **Install path**: `scripts/install.sh` defaults to `~/.claude/skills/ndemo`,
  but that path is arbitrary. Override it and point `$NDEMO` at your choice:

  ```bash
  bash scripts/install.sh ~/.local/share/ndemo
  export NDEMO=~/.local/share/ndemo/ndemo
  ```

- Set `OPENAI_API_KEY` and/or `MINIMAX_API_KEY` for TTS; verify with `$NDEMO doctor`.

See also **@AGENTS.md** and **references/** for the authenticated-app guide and gotchas.
