# Demoing authenticated apps (SSO / login)

The render runs in a **headless** Chromium. If the app is behind a login, the
headless render must already be authenticated, or it lands on the login page
and every action times out. The approach: log in **once** in the visible
daemon window, capture the session, and replay it into the render.

## Capture once, reuse forever

```bash
NDEMO=~/.claude/skills/ndemo/ndemo
$NDEMO open demo/<name>/<name>.yaml     # visible window
# → log in by hand (or scripted, see below), land on the app's main screen
$NDEMO capture-auth                      # writes .ndemo/auth.json
```

`capture-auth` reads cookies **and** `localStorage` from the live page (many
apps — e.g. OpenWebUI — keep their JWT in `localStorage.token`). The render
restores both: cookies via `addCookies`, localStorage via an init script that
runs before the app boots, then a reload. `auth.json` is git-ignored.

> **Why read localStorage directly?** Playwright's `storageState()` over a CDP
> connection frequently returns 0 localStorage entries. The patched
> `capture-auth` falls back to `page.evaluate(() => localStorage)`.

## The two pitfalls that cost the most time

1. **Profile lock.** The daemon and the render both use
   `.ndemo/browser-profile`. Chromium refuses two processes on one profile
   ("Failed to create a ProcessSingleton"). **Always `$NDEMO close` before
   `render`.**

2. **`close` used to wipe everything.** Upstream `close` did
   `rm -rf .ndemo` (profile + auth) **and** `SIGKILL`ed Chromium (losing
   unflushed `localStorage`). The patch makes `close`:
   - `SIGTERM` first (graceful — flushes localStorage/cookies to disk),
     `SIGKILL` only as a fallback;
   - remove **only** `browser.json`, preserving `browser-profile` and
     `auth.json`.
   So login survives daemon restarts and renders.

## Scripting the login (optional)

`play` always rewinds to `app.url` first, so a login segment must run the whole
chain from the app's login page in one segment. Example (Microsoft SSO):

```yaml
# login-helper.local.yaml  — *.local.yaml is git-ignored; keep credentials here
segments:
  - id: login
    narration: "login"
    intent: auto login
    timing: after
    actions:
      - { type: click,  target: { role: button, name: "Continue with Microsoft" } }
      - { type: wait,   duration: 4500 }
      - { type: type,   target: { selector: "input[type=email]" }, text: "you@example.com", delay: 25 }
      - { type: click,  target: { role: button, name: "Next" } }
      - { type: wait,   duration: 4500 }
      - { type: type,   target: { selector: "input[type=password]" }, text: "<password>", delay: 25 }
      - { type: click,  target: { role: button, name: "Sign in" } }
      - { type: wait,   duration: 5000 }
      - { type: click,  target: { role: button, name: "Yes" } }   # "Stay signed in?"
      - { type: wait,   duration: 6000 }
```

> **Never commit credentials.** Keep login helpers in a `*.local.yaml` file
> (git-ignored) or fill them from env at runtime. MFA cannot be automated —
> complete it by hand in the visible window, then `capture-auth`.

## Recording the login screen in the video

The render reuses `auth.json`, so it starts already logged in (no login shown).
To open the final video with the login screen:

1. Render a short **logged-out** intro while auth is moved aside:
   ```bash
   mv .ndemo/browser-profile .ndemo/browser-profile.bak
   mv .ndemo/auth.json       .ndemo/auth.json.bak
   $NDEMO render demo/<name>/login-intro.yaml --output demo/<name>/login-intro.mp4
   rm -rf .ndemo/browser-profile; mv .ndemo/browser-profile.bak .ndemo/browser-profile
   mv .ndemo/auth.json.bak .ndemo/auth.json
   ```
   The intro just shows the login page and hovers the SSO button (no click, no
   credentials filmed).
2. Concatenate intro + main demo (normalize audio sample rate first):
   ```bash
   ffmpeg -y -i login-intro.mp4 -c:v copy -c:a aac -ar 44100 -ac 1 /tmp/intro.mp4
   printf "file '%s'\nfile '%s'\n" /tmp/intro.mp4 "$PWD/demo/<name>/<name>.mp4" > /tmp/list.txt
   ffmpeg -y -f concat -safe 0 -i /tmp/list.txt -c copy demo/<name>/final.mp4
   ```
