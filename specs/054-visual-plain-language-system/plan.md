# Implementation Plan: Visual Plain-Language System

1. Add failing component and LiveView tests for the visual scene and English producer workflow.
2. Create a reusable system-scene component and a light technical illustration asset.
3. Place the visual scene near the top of the operator route and simplify chemistry labels.
4. Rebuild the producer route around the compact scene and direct decisions.
5. Translate producer messages, offline rules, queue defaults, scripts, and generated demo copy to English.
6. Force the root theme to light.
7. Run full tests, rebuild Docker, validate the live routes, regenerate submission artifacts, and publish.

## Guardrails

- Keep deterministic thresholds and safety behavior unchanged.
- Explain domain meaning without hiding technical values.
- Do not imply the stock DECT example measures water chemistry.
- Use one shared visual component to keep operator and producer meaning aligned.
- Keep controls dense, responsive, and operational rather than marketing-oriented.
