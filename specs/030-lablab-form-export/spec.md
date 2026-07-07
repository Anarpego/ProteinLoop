# Feature Spec: lablab Form Export

## Goal

Export the lablab submission markdown into a structured JSON form packet with artifact paths and TODO status.

## User Value

The team can transfer submission fields into lablab without manually hunting through markdown, while still clearly seeing which required external fields are unresolved.

## Functional Requirements

1. The repo shall include a stdlib-only lablab form exporter.
2. The exporter shall parse title, short description, long description, tags, repository URL, demo platform, application URL, key demo path, and judging notes.
3. The exporter shall include artifact paths for cover image, video, slide deck, bundle, and README.
4. The exporter shall mark repository and application URLs as unresolved when they are `TODO`.
5. The submission artifact validator shall require the generated JSON export.
6. The Make render target shall generate the JSON export.

## Acceptance Criteria

1. `make submission-form` writes `submission/lablab-form.json`.
2. `make submission-check` validates the JSON export contains required fields and artifacts.
3. Unit tests cover section parsing and TODO detection.
