# Deployed Browser Evidence

Source: `https://proteinloop.dev-vb.lat`

The captures use Chrome device-metric emulation rather than a cropped 500 px headless window. The
layout inspector verified `documentScrollWidth == viewportWidth` and found zero uncontained
overflow at 1440 px desktop and 390 px mobile widths. Wide RLVR tables remain intentionally inside
their own horizontal scroll containers.

- `operator-desktop.png`: first operator viewport with the live WebGL tank and Gemma control.
- `operator-mobile.png`: true 390x844 first viewport with wrapped protein outcomes.
- `producer-desktop.png`: producer decision workspace and read-only live tank.
- `producer-mobile.png`: stacked producer decision controls at 390x844.
- `tank-fullscreen-desktop.png`: actual Fullscreen API view with full agent network and HUD.
- `tank-fullscreen-mobile.png`: actual Fullscreen API view with compact AI control, complete tank,
  and stacked HUD.
- `report.json`: dimensions, SHA-256 checksums, and nonblank tank-region pixel variance.

Re-run the pixel gate after replacing any capture:

```sh
python3 scripts/validate_visual_evidence.py
```
