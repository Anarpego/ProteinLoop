# Tasks: Judge-Winning Experience

- [x] Define the judge-facing product, proof, accessibility, and AMD-claim contract.
- [x] Add failing dynamic-story, proof-ribbon, and verifier-proof tests.
- [x] Implement phase-driven impact and animated whole-loop communication.
- [x] Implement the first-viewport executable proof ribbon.
- [x] Implement and test the one-click verifier proof timeline.
- [x] Harden live regions, reduced motion, keyboard behavior, and mobile targets.
- [x] Update README, submission path, executable validators, and the rendered deck.
- [x] Run all tests, assets, Docker, live-demo, smoke, and submission evidence.
- [ ] Capture browser evidence when a backend is available.
- [x] Publish the implementation and evidence.

## Executable Evidence

- `python3 -m unittest discover -s tests`: 156 tests passed.
- `cd app && mix test`: 119 tests passed.
- `cd app && mix assets.build`: production assets compiled with the responsive and reduced-motion styles.
- `DEMO_URL=http://127.0.0.1:4001 SIMULATOR_PUBLIC_URL=http://127.0.0.1:8000 make live-demo-check`: operator, producer, assets, and simulator checks passed.
- `python3 scripts/docker_smoke_test.py`: simulator recovery, producer isolation, operator markers, and visual assets passed.
- `make submission-check`: submission artifacts passed; the refreshed deck contains 10 slides.
- `mix format --check-formatted` and `make ci-check`: formatting and CI workflow contracts passed.
- The light 108-frame demo video and 10-slide deck were regenerated; representative frames and the deck contact sheet were visually inspected.
- Browser discovery returned no available backend, so application screenshots remain explicitly pending.
- Published to `main` in commit `51a530f`.
