# Gotchas & hard-won lessons

Every item here cost real debugging time. Read before authoring.

## Voice-over sync: use `timing: parallel`

`ndemo` segment timing:

- `after` (upstream default) — plays the **entire** narration first, with the
  screen frozen on the *previous* segment's last frame, **then** runs the
  actions. Result: the voice describes an action that hasn't happened yet, over
  the wrong shot. Also adds the full narration length as dead time.
- `parallel` — actions run **while** narration plays. The voice matches what's
  on screen. Use this for essentially every segment.

If actions finish before narration, the last frame holds until audio ends. If
narration finishes first, the remaining actions play out (e.g. a streaming
answer appearing) silently — usually fine.

## Render crash on long/streaming waits: avoid `done: {text: ...}`

A `done: { text: { selector: "button", has: "View source" }, timeout: 120000 }`
polls a text locator repeatedly. On a page that streams content for 60–90s
(web search, long generations) this reliably **closes/crashes the headless
browser** ("Target page, context or browser has been closed").

Fix: use a **fixed `wait`** sized to the observed response time, or a smart
`done: { stable: 1500, timeout: 30000 }` / `done: { networkIdle: true }` which
ends as soon as the page settles. A 45–55s fixed wait records fine; the crash
was the polling locator, not the duration. Frames are captured on-change, so a
static post-response screen adds few frames.

`done` is **non-fatal** in this patch: if a condition times out or errors, the
action logs `(done not met, continuing: …)` and the render proceeds, instead of
aborting. So smart waits are safe to use — worst case they fall through to the
segment's own fixed-wait bound. (`stable`/`networkIdle` are still preferred over
`text` on long-streaming pages.)

## Keep single-column layout centered

If the app supports multi-model / split views, an accidental "Add model" leaves
a 2-column comparison that looks off-center. Keep one model selected (a `setup`
step that selects the base model gives every run a clean, centered start).

## Interactive window must be Retina-correct

Upstream daemon forced `--window-size=1920,1080` + `--force-device-scale-factor=1`,
which on a Retina Mac renders an oversized, non-crisp window. The patch uses
`--start-maximized` + `viewport: null` so the window fits the screen at the
display's native DPR. (The render keeps its own high-res 4K viewport — these are
independent.)

## Suppress browser popups in recordings

Chrome's translate bar / save-password bubble / notifications can appear in the
recording. Both daemon and renderer launch with:
`--disable-translate --disable-notifications --disable-save-password-bubble`
and `--disable-features=Translate,TranslateUI,PasswordManagerOnboarding,...`.

## Setup steps fail on the login page → daemon self-kills

The daemon runs `app.setup` after navigation. If `setup` clicks an app element
(e.g. the model selector) but you're not logged in yet, it times out and the
daemon process exits. **Open with a setup-less playbook for the login phase**,
or only add `setup` once auth is captured.

## Element targeting

- Role-name matching is **substring + case-insensitive**. `name: "high"` also
  matches `xhigh`; `name: "Default"` also matches `Set as default`. Add
  `exact: true` (patched in) to pin it.
- Composite/duplicated buttons (a button wrapping a button) cause strict-mode
  violations — the error message lists every match **with a usable selector**;
  copy the stable one (often an `#id` or a class combo).
- Native `<select>` shows as `combobox` in the a11y tree; options aren't
  clickable as elements. Use the `select` action (`selectOption`), not a click.

## File upload

There is no OS file-chooser in headless. The patched `upload` action sets files
directly on the hidden input:
`{ type: upload, target: { selector: "input[type=file][multiple]" }, files: ["/abs/path"] }`.
Target `[multiple]` to avoid matching a separate camera/image input.

## Iterate fast with a scratch playbook

`play` always rewinds (re-runs prior segments). To probe one interaction
without re-running an expensive prefix, make a tiny single-segment
`scratch.yaml` and `play --segment` it — the daemon is shared, so it acts on the
same live browser.
