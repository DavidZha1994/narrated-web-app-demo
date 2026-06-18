# narrated-web-app-demo

A [Claude Code](https://claude.com/claude-code) **skill** for producing
narrated, voice-over screen-recording demo videos of web applications —
including apps behind **SSO / login**.

You describe the tour as a YAML *playbook* (segments = narration + browser
actions). A headless Chromium is driven through it with an animated cursor and
button highlights, per-segment text-to-speech narration is synthesized, and the
result is merged into a **4K MP4 with subtitles**.

Built on top of the excellent **[`ndemo`](https://github.com/splitbrain/ndemo)**
toolkit by [splitbrain](https://github.com/splitbrain), with an enhancement
patch that adds what real product demos need.

## What the patch adds

| Capability | Why |
|---|---|
| **Authenticated apps** (`capture-auth` + render injection) | Log in once, replay the session into every headless render — no re-login. Reads cookies **and** `localStorage` (JWT) and restores both. |
| **`upload` action** | Attach real files via the hidden `<input type=file>` to demo upload / RAG (no OS file-chooser in headless). |
| **MiniMax TTS provider** | High-quality non-English voices (e.g. German) alongside upstream OpenAI / ElevenLabs. |
| **Retina-correct window** | Interactive window fits the screen at native DPR instead of an oversized 1× window. |
| **Popup suppression** | No translate bar / save-password bubble / notifications in the recording. |
| **`exact` role matching** | Disambiguate `high` vs `xhigh`, `Default` vs `Set as default`. |
| **Non-destructive `close`** | Graceful shutdown that flushes & **preserves** the profile + `auth.json` (upstream wiped them). |
| **Polish: zoom / framing / music / outro** | Optional cinematic zoom toward the active element, window framing (padded background + shadow), ducked music bed, and an end card — via a `polish` block. |
| **Non-fatal `done`** | A timed-out readiness check logs and continues instead of crashing the render — makes smart `done: { stable }` waits safe (no guessed fixed waits, no dead time). |

## Install

```bash
bash scripts/install.sh                 # → ~/.claude/skills/ndemo
export OPENAI_API_KEY=...                # and/or MINIMAX_API_KEY
~/.claude/skills/ndemo/ndemo doctor
```

The script clones `splitbrain/ndemo`, applies
[`patches/ndemo-enhancements.patch`](patches/ndemo-enhancements.patch), builds,
and installs the Playwright browser. The upstream tool is **not** vendored here.

## Quick start

```bash
NDEMO=~/.claude/skills/ndemo/ndemo
cp assets/templates/webapp-demo.template.yaml demo/tour/tour.yaml   # edit it
$NDEMO open demo/tour/tour.yaml          # visible window — log in if needed
$NDEMO capture-auth                       # save session for the render
# author each segment: page-state → write actions → play --segment
$NDEMO close
$NDEMO render demo/tour/tour.yaml --output demo/tour/tour.mp4
```

See **[`SKILL.md`](SKILL.md)** for the full workflow and
**[`references/`](references/)** for the authenticated-app guide and the list of
gotchas (voice-over sync, render-crash avoidance, native `<select>` handling,
file upload, …).

## Security

This repo contains **no credentials, sessions, or rendered media** — see
[`.gitignore`](.gitignore). Keep login helpers in `*.local.yaml` (ignored) and
TTS keys in environment variables. Never commit `auth.json`, `.env`, or
`.ndemo/`.

## License & credit

Original content here (skill, templates, references, scripts, patch) is
[MIT](LICENSE). The underlying **ndemo** engine is by splitbrain and governed by
its own terms: https://github.com/splitbrain/ndemo
