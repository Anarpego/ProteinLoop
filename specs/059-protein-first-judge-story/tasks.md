# Tasks: Protein-First Judge Story

- [x] Define the factual protein-first product position and acceptance contract.
- [x] Add failing tank component tests for biomass, risk, and demo mode.
- [x] Add failing operator tests for purpose, loop, workflow, and recovery receipt.
- [x] Implement the first-viewport purpose and connected protein loop.
- [x] Implement quantified tank stakes and corrected biomass labels.
- [x] Implement the plain-language verified recovery console and receipt.
- [x] Verify producer permissions and responsive styles.
- [x] Run tests, build assets, rebuild Docker, and run live-demo validation.
- [x] Capture deployed desktop and true 390 px mobile browser evidence.
- [x] Publish executable evidence.

## Executable Evidence

- `python3 -m unittest discover -s tests`: 184 tests passed.
- `cd app && mix test`: 132 tests passed.
- `cd app && mix assets.build`: production CSS and JavaScript compiled.
- `DEMO_URL=http://127.0.0.1:4001 SIMULATOR_PUBLIC_URL=http://127.0.0.1:8000 make live-demo-check`: all public route, asset, and simulator checks passed.
- `python3 scripts/docker_smoke_test.py`: simulator recovery, operator route, producer permissions, and bundled visual assets passed.
- `python3 scripts/validate_visual_evidence.py`: deployed operator, producer, and actual full-screen captures passed dimensions and nonblank tank-pixel checks.
- Browser layout inspection at 1440 px and 390 px found zero uncontained overflow.
- Published to `main` in commit `ed9bf0a`.
