import fs from "node:fs/promises";
import path from "node:path";

const root = path.resolve(".");
const workspace = path.resolve(
  root,
  process.env.PRESENTATION_WORKSPACE ??
    "outputs/manual-proteinloop/presentations/submission-deck",
);
const slidesDir = path.join(workspace, "slides");
const assetDir = path.join(root, "submission/deck-assets");

const data = {
  pythonTests: 220,
  phoenixTests: 141,
  rewardDelta: 463,
  collapseAvoidance: "100%",
  animalBiomass: "14.5 kg",
  plantBiomass: "5.0 kg",
};

await fs.mkdir(slidesDir, { recursive: true });
await fs.writeFile(path.join(workspace, "data.json"), `${JSON.stringify(data, null, 2)}\n`);
await fs.writeFile(
  path.join(workspace, "profile-plan.txt"),
  [
    "task mode: targeted-edit",
    "primary deck-profile: engineering-platform",
    "secondary profile gates: startup pitch, food security, product proof",
    "required proof objects: real product UI, verifier workflow, executable metrics, offline AMD edge architecture, producer control, runtime boundary",
    "source assets: submission/cover.png, operator-overview.png, agent-recovery.png, repository evidence artifacts",
    "brand constraints: no invented AMD or Nordic logos; use product typography and verified UI only",
    "QA gates: 16:9, readable at thumbnail scale, contained node text, attached connector direction, proven-versus-next labels, no unmeasured claims",
    "known boundary: AMD ROCm/vLLM is captured experiment evidence; current public inference remains CPU llama.cpp",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "source-notes.txt"),
  [
    "Product captures were provided by the user from the deployed ProteinLoop application.",
    "Cover source: submission/cover.png, generated from the deployed full-screen tank capture.",
    "Operator overview: submission/deck-assets/operator-overview.png.",
    "Agent recovery: submission/deck-assets/agent-recovery.png.",
    `Executable evidence verified July 12, 2026: ${data.pythonTests} Python tests and ${data.phoenixTests} Phoenix tests, zero failures.`,
    "Physical evidence: two nRF9151 boards exchanged matching bidirectional DECT NR+ sequence 100.",
    "AMD deployment basis: https://rocm.docs.amd.com/en/7.13.0-preview/ai-inference/vllm.html documents local vLLM inference and serving on supported AMD GPUs and APUs.",
    "Offline model basis: https://huggingface.co/docs/transformers/installation documents pre-caching model files and HF_HUB_OFFLINE=1 for offline or firewalled operation.",
    "Boundary: the assigned AMD notebook run is captured proof; a farm-installed AMD GPU and measured solar autonomy remain deployment work.",
    "No external identity marks are drawn or approximated.",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "reference-audit.txt"),
  [
    "The previous deck was accurate but visually repetitive: nine slides used similar heading-plus-box compositions.",
    "Preserve: light theme, teal system color, deterministic-verifier language, honest proof boundaries.",
    "Improve: image-led opening, real UI proof, stronger hierarchy, fewer words, distinct slide rhythms, larger metrics.",
    "Avoid: decorative card grids, vague AI-layer labels, live-public AMD claims, unmeasured solar or sensor claims.",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "template-audit.txt"),
  [
    "preserve: ten-slide story, light/dark rhythm, teal/orange/blue system, real UI captures, honest evidence boundaries",
    "improve: slide 05 title/detail containment and slide 07 offline AMD explanation",
    "do not imitate: the previous slide 05 overflow or slide 07 generic five-box pipeline",
    "brand/assets: preserve verified ProteinLoop captures and omit fabricated AMD or Nordic marks",
    "exact clone: slides 01-04, 06, and 08-10 retain their established macro layouts",
    "insertion contract: slides 05 and 07 remain in place and inherit the existing title, footer, palette, and typography grammar",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "template-frame-map.json"),
  `${JSON.stringify(
    {
      mode: "targeted-edit",
      source: "scripts/generate_submission_deck_v2.mjs",
      preserved: [1, 2, 3, 4, 6, 8, 9, 10],
      edited: {
        5: "repair node title/detail geometry and rejection lane",
        7: "replace generic edge box with explicit offline AMD decision boundary",
      },
    },
    null,
    2,
  )}\n`,
);
await fs.writeFile(
  path.join(workspace, "deviation-log.txt"),
  [
    "slide 05: equalized workflow-node geometry and shortened the rejection lane to prevent text collisions",
    "slide 07: changed the proof object from a generic component row to field / on-site AMD / producer boundaries plus optional cloud and power notes",
    "all other slide macro layouts remain unchanged",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "claim-spine.txt"),
  [
    "01 ProteinLoop keeps living protein systems understandable and recoverable at the edge.",
    "02 One shared water loop means one chemistry failure threatens every food output.",
    "03 The deployed product makes the loop visible in one operator view.",
    "04 Four specialists and one supervisor turn live state into a verified recovery.",
    "05 Gemma can recommend, but only deterministic rules can admit mutation.",
    "06 Executable tests and RLVR evidence make the safety claim inspectable.",
    "07 After provisioning, an on-site AMD GPU can keep cached Gemma inference and deterministic decisions local while DECT NR+ carries the field hop.",
    "08 The producer retains control of risky or irreversible actions.",
    "09 Verifier feedback turns 10% first-pass safety into 100% model-safe plans on the captured AMD runtime.",
    "10 The market wedge is resilient protein production where connectivity cannot be assumed.",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "design-system.txt"),
  [
    "slide size: 1280x720, 16:9",
    "backgrounds: cool white for product and architecture; deep ink for executable and AMD evidence",
    "typography: installed title sans plus utilitarian body sans; claim titles 34-42 px; body 14-18 px",
    "palette: ink and cool white base, teal system accent, orange decision accent, blue runtime proof",
    "diagram grammar: left-to-right authority flow with attached semantic connectors and explicit reject branch",
    "container grammar: boxes only for system boundaries, decisions, or evidence groups; square corners",
    "footer grammar: 9 px source or boundary note aligned left at y=682",
    "brand policy: use real ProteinLoop UI captures; do not fabricate AMD or Nordic marks",
    "banned motifs: generic feature-card grids, decorative gradients, floating arrows, unproven hardware claims",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "contact-sheet-plan.txt"),
  [
    "01 immersive product cover",
    "02 editorial shared-risk argument with vertical dependency rail",
    "03 framed deployed-product capture",
    "04 full-bleed live recovery capture with sequence overlay",
    "05 horizontal authority and reject-flow diagram",
    "06 dark executable metric rail",
    "07 field / on-site AMD / producer boundary diagram with optional cloud and explicit power note",
    "08 asymmetric producer-decision composition",
    "09 dark three-column AMD runtime, repair, and execution evidence",
    "10 split closing ask with real product capture",
    "gate: no three consecutive slides share a macro layout; no generic card-grid cadence",
    "",
  ].join("\n"),
);

const common = `
export const C = {
  ink: "#0b1f2a",
  body: "#425466",
  fog: "#f3f7f6",
  white: "#ffffff",
  teal: "#087f75",
  teal2: "#18a999",
  mint: "#dff7ef",
  blue: "#1687c8",
  blueSoft: "#e2f3fb",
  orange: "#ef6c21",
  orangeSoft: "#fff0e5",
  green: "#2f9e66",
  greenSoft: "#e5f7ed",
  red: "#d9485f",
  redSoft: "#fde8ec",
  yellow: "#f2c94c",
  navy: "#102d3c",
  line: "#cbd8dc"
};

export const A = {
  cover: ${JSON.stringify(path.join(root, "submission/cover.png"))},
  overview: ${JSON.stringify(path.join(assetDir, "operator-overview.png"))},
  recovery: ${JSON.stringify(path.join(assetDir, "agent-recovery.png"))}
};

export function base(presentation, ctx, section, dark = false) {
  const s = presentation.slides.add();
  ctx.addShape(s, { x: 0, y: 0, w: ctx.W, h: ctx.H, fill: dark ? C.navy : C.fog });
  ctx.addShape(s, { x: 0, y: 0, w: 14, h: ctx.H, fill: dark ? C.orange : C.teal });
  ctx.addText(s, { x: 42, y: 24, w: 220, h: 24, text: "PROTEINLOOP", fontSize: 13, bold: true, color: dark ? "#8ee7d5" : C.teal });
  ctx.addText(s, { x: 1000, y: 24, w: 220, h: 20, text: section.toUpperCase(), fontSize: 10, bold: true, color: dark ? "#b7cbd3" : C.body, align: "right" });
  return s;
}

export function title(ctx, s, text, options = {}) {
  ctx.addText(s, {
    x: options.x ?? 42,
    y: options.y ?? 64,
    w: options.w ?? 1120,
    h: options.h ?? 92,
    text,
    fontSize: options.size ?? 34,
    bold: true,
    color: options.color ?? C.ink,
    typeface: ctx.fonts.title,
    valign: "mid"
  });
}

export function kicker(ctx, s, text, x, y, color = C.orange) {
  ctx.addText(s, { x, y, w: 240, h: 20, text: text.toUpperCase(), fontSize: 10, bold: true, color });
}

export function body(ctx, s, text, x, y, w, h, color = C.body, size = 16) {
  ctx.addText(s, { x, y, w, h, text, fontSize: size, color, valign: "mid" });
}

export function pill(ctx, s, text, x, y, w, fill, color = C.ink) {
  ctx.addShape(s, { x, y, w, h: 32, fill, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: x + 10, y: y + 7, w: w - 20, h: 18, text, fontSize: 11, bold: true, color, align: "center" });
}

export function node(ctx, s, { x, y, w, h, label, detail, fill = C.white, line = C.teal, number, labelSize = 16, labelHeight = 44, detailY = 72, detailSize = 11 }) {
  ctx.addShape(s, { x, y, w, h, fill, line: ctx.line(line, 2) });
  if (number) {
    ctx.addShape(s, { x: x + 14, y: y + 16, w: 32, h: 32, fill: line, line: ctx.line("#00000000", 0), geometry: "ellipse" });
    ctx.addText(s, { x: x + 14, y: y + 22, w: 32, h: 18, text: number, fontSize: 12, bold: true, color: C.white, align: "center" });
  }
  ctx.addText(s, { x: x + (number ? 58 : 18), y: y + 12, w: w - (number ? 74 : 36), h: labelHeight, text: label, fontSize: labelSize, bold: true, color: C.ink, valign: "mid" });
  if (detail) ctx.addText(s, { x: x + 18, y: y + detailY, w: w - 36, h: h - detailY - 18, text: detail, fontSize: detailSize, color: C.body, valign: "top" });
}

export function connector(ctx, s, x, y, w, color = C.teal) {
  ctx.addShape(s, { x, y: y + 9, w: w - 28, h: 3, fill: color, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: x + w - 30, y, w: 30, h: 24, text: ">", fontSize: 18, bold: true, color, align: "center" });
}

export function metric(ctx, s, { x, y, value, label, note, color }) {
  ctx.addText(s, { x, y, w: 230, h: 62, text: value, fontSize: 42, bold: true, color });
  ctx.addText(s, { x, y: y + 66, w: 230, h: 26, text: label, fontSize: 14, bold: true, color: C.white });
  ctx.addText(s, { x, y: y + 94, w: 230, h: 30, text: note, fontSize: 10, color: "#bad0d8" });
  ctx.addShape(s, { x, y: y + 132, w: 210, h: 4, fill: color, line: ctx.line("#00000000", 0) });
}

export function footer(ctx, s, text, dark = false) {
  ctx.addText(s, { x: 42, y: 682, w: 1130, h: 16, text, fontSize: 9, color: dark ? "#9db6c0" : "#6b7f88" });
}
`;

await fs.writeFile(path.join(slidesDir, "common.mjs"), common);

const slides = [
  `import { A } from "./common.mjs";
export default async function slide01(presentation, ctx) {
  const s = presentation.slides.add();
  await ctx.addImage(s, { path: A.cover, x: 0, y: 0, w: ctx.W, h: ctx.H, fit: "cover", alt: "ProteinLoop tank and Gemma recovery control" });
  return s;
}`,

  `import { C, base, title, body, kicker, footer } from "./common.mjs";
export default async function slide02(presentation, ctx) {
  const s = base(presentation, ctx, "Problem");
  kicker(ctx, s, "One loop, shared risk", 52, 74, C.red);
  title(ctx, s, "A chemistry failure does not stop at the vegetables.", { x: 52, y: 104, w: 650, h: 120, size: 42 });
  body(ctx, s, "Fish and prawns breathe the water. Plants clean it. Duckweed stores feed. Eggs depend on what survives upstream.", 56, 236, 590, 100, C.body, 18);
  ctx.addShape(s, { x: 56, y: 382, w: 590, h: 118, fill: C.redSoft, line: ctx.line(C.red, 0) });
  ctx.addText(s, { x: 80, y: 404, w: 540, h: 42, text: "One ammonia spike", fontSize: 26, bold: true, color: C.red });
  ctx.addText(s, { x: 80, y: 454, w: 540, h: 30, text: "can threaten every protein output in the loop.", fontSize: 17, color: C.ink });
  const items = [
    ["14.5 kg", "fish + prawn stock", C.blue, 102],
    ["5.0 kg", "plants cleaning water", C.teal, 268],
    ["eggs", "downstream protein", C.orange, 434]
  ];
  ctx.addShape(s, { x: 770, y: 118, w: 4, h: 460, fill: C.line, line: ctx.line("#00000000", 0) });
  for (const [value, label, color, y] of items) {
    ctx.addShape(s, { x: 750, y: y + 35, w: 44, h: 44, fill: color, line: ctx.line("#00000000", 0), geometry: "ellipse" });
    ctx.addText(s, { x: 824, y, w: 320, h: 54, text: value, fontSize: 34, bold: true, color: C.ink });
    ctx.addText(s, { x: 824, y: y + 58, w: 320, h: 30, text: label, fontSize: 16, color: C.body });
  }
  footer(ctx, s, "ProteinLoop measures the animal-protein outcome instead of treating it as a hidden side effect.");
  return s;
}`,

  `import { C, A, base, title, body, pill, footer } from "./common.mjs";
export default async function slide03(presentation, ctx) {
  const s = base(presentation, ctx, "Product proof");
  title(ctx, s, "A living system people can understand in seconds.", { y: 54, h: 70, size: 34 });
  body(ctx, s, "The deployed operator view connects animal behavior, plain-language chemistry, biomass, and action in one scene.", 46, 130, 970, 38, C.body, 15);
  ctx.addShape(s, { x: 42, y: 176, w: 1192, h: 428, fill: C.white, line: ctx.line(C.line, 1) });
  await ctx.addImage(s, { path: A.overview, x: 56, y: 188, w: 1164, h: 404, fit: "contain", alt: "ProteinLoop operator overview" });
  pill(ctx, s, "SEE THE ANIMALS", 74, 618, 190, C.blueSoft, C.blue);
  pill(ctx, s, "UNDERSTAND THE WATER", 286, 618, 236, C.mint, C.teal);
  pill(ctx, s, "ACT WITH EVIDENCE", 544, 618, 206, C.orangeSoft, C.orange);
  footer(ctx, s, "Real deployed UI at proteinloop.dev-vb.lat; the tank is rendered live, not a looping video.");
  return s;
}`,

  `import { C, A, title, footer } from "./common.mjs";
export default async function slide04(presentation, ctx) {
  const s = presentation.slides.add();
  await ctx.addImage(s, { path: A.recovery, x: 0, y: 0, w: ctx.W, h: ctx.H, fit: "cover", alt: "Live ProteinLoop recovery mission" });
  ctx.addShape(s, { x: 0, y: 0, w: 1280, h: 116, fill: "#102d3cee", line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 44, y: 20, w: 720, h: 54, text: "The recovery is visible while it happens.", fontSize: 31, bold: true, color: C.white });
  const steps = [["1", "Observe"], ["2", "4 specialists"], ["3", "Supervisor"], ["4", "Verify"], ["5", "Measure"]];
  steps.forEach(([n, label], i) => {
    const x = 48 + i * 238;
    ctx.addText(s, { x, y: 82, w: 28, h: 20, text: n, fontSize: 11, bold: true, color: C.orange });
    ctx.addText(s, { x: x + 28, y: 80, w: 170, h: 22, text: label, fontSize: 13, bold: true, color: C.white });
  });
  footer(ctx, s, "Structured events and tool outcomes are visible; private model chain-of-thought is not presented as evidence.", true);
  return s;
}`,

  `import { C, base, title, body, node, connector, footer } from "./common.mjs";
export default async function slide05(presentation, ctx) {
  const s = base(presentation, ctx, "Safety boundary");
  title(ctx, s, "The model can recommend. It cannot mutate.", { y: 58, h: 74, size: 38 });
  body(ctx, s, "Authority moves left to right. Every connector ends at an explicit decision boundary.", 46, 132, 820, 38, C.body, 15);
  node(ctx, s, { x: 42, y: 220, w: 220, h: 150, label: "Gemma specialists", detail: "Fish, prawns, plants, and feed-loop briefs.", fill: C.mint, line: C.teal, number: "1" });
  connector(ctx, s, 270, 282, 46, C.teal);
  node(ctx, s, { x: 324, y: 220, w: 196, h: 150, label: "Supervisor", detail: "Combines briefs into one bounded proposal.", fill: C.blueSoft, line: C.blue, number: "2" });
  connector(ctx, s, 528, 282, 48, C.blue);
  node(ctx, s, { x: 584, y: 220, w: 272, h: 150, label: "Deterministic verifier", detail: "Checks chemistry, feed, water exchange, reserve, and collapse rules.", fill: C.orangeSoft, line: C.orange, number: "3" });
  connector(ctx, s, 864, 282, 48, C.orange);
  node(ctx, s, { x: 920, y: 220, w: 268, h: 150, label: "Simulator mutation", detail: "Only admitted actions can change ecosystem state.", fill: C.greenSoft, line: C.green, number: "4" });
  ctx.addShape(s, { x: 584, y: 438, w: 604, h: 78, fill: C.redSoft, line: ctx.line(C.red, 2) });
  ctx.addText(s, { x: 610, y: 465, w: 112, h: 24, text: "BLOCKED", fontSize: 14, bold: true, color: C.red });
  ctx.addText(s, { x: 742, y: 451, w: 418, h: 48, text: "Rejected before state change, logged to the RLVR trace, and returned as verifier feedback.", fontSize: 15, color: C.ink, valign: "mid" });
  ctx.addShape(s, { x: 718, y: 370, w: 3, h: 68, fill: C.red, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 702, y: 407, w: 34, h: 24, text: "v", fontSize: 18, bold: true, color: C.red, align: "center" });
  footer(ctx, s, "verify_ecosystem_safety is the only authority allowed to admit simulator mutation.");
  return s;
}`,

  `import { C, base, title, metric, footer } from "./common.mjs";
export default async function slide06(presentation, ctx) {
  const s = base(presentation, ctx, "Executable evidence", true);
  title(ctx, s, "Safety is demonstrated, not narrated.", { y: 60, h: 76, size: 39, color: C.white });
  ctx.addText(s, { x: 46, y: 140, w: 790, h: 44, text: "The simulator is simultaneously the product demo, the policy evaluator, and the RLVR source of truth.", fontSize: 16, color: "#c2d6dd" });
  metric(ctx, s, { x: 52, y: 224, value: "${data.pythonTests}", label: "Python tests", note: "simulator, verifier, API, evidence", color: "#63c7f2" });
  metric(ctx, s, { x: 342, y: 224, value: "${data.phoenixTests}", label: "Phoenix tests", note: "Sagents, LiveView, producer control", color: "#76d9ad" });
  metric(ctx, s, { x: 632, y: 224, value: "+463", label: "reward delta", note: "verified policy versus naive average", color: "#f2c94c" });
  metric(ctx, s, { x: 922, y: 224, value: "100%", label: "collapse avoidance", note: "fixed baseline scenarios recovered", color: "#ff8e5c" });
  ctx.addShape(s, { x: 52, y: 446, w: 1130, h: 112, fill: "#173f50", line: ctx.line("#315b6b", 1) });
  ctx.addText(s, { x: 82, y: 468, w: 260, h: 24, text: "ONE-CLICK JUDGE PROOF", fontSize: 12, bold: true, color: "#8ee7d5" });
  ctx.addText(s, { x: 82, y: 506, w: 1030, h: 30, text: "Inject emergency  ->  block unsafe proposal  ->  admit safe recovery  ->  inspect measured chemistry", fontSize: 18, bold: true, color: C.white });
  footer(ctx, s, "Verified July 12, 2026: ${data.pythonTests} Python and ${data.phoenixTests} Phoenix tests, zero failures.", true);
  return s;
}`,

  `import { C, base, title, body, footer } from "./common.mjs";
export default async function slide07(presentation, ctx) {
  const s = base(presentation, ctx, "Off-grid architecture");
  title(ctx, s, "An on-site AMD GPU can keep the decision loop local.", { y: 52, h: 72, size: 36 });
  body(ctx, s, "After the application and Gemma weights are provisioned, farm decisions do not require an internet API.", 46, 132, 900, 32, C.body, 15);

  ctx.addShape(s, { x: 42, y: 204, w: 410, h: 246, fill: C.white, line: ctx.line(C.green, 2) });
  ctx.addText(s, { x: 64, y: 222, w: 300, h: 22, text: "FIELD LINK · PHYSICALLY PROVEN", fontSize: 11, bold: true, color: C.green });
  const fieldNodes = [
    { x: 64, w: 126, label: "nRF9151 PT", note: "tank radio" },
    { x: 210, w: 84, label: "DECT NR+", note: "private hop" },
    { x: 314, w: 116, label: "nRF9151 FT", note: "gateway" }
  ];
  fieldNodes.forEach(({ x, w, label, note }, index) => {
    ctx.addShape(s, { x, y: 270, w, h: 94, fill: index === 1 ? C.greenSoft : C.blueSoft, line: ctx.line(index === 1 ? C.green : C.blue, 2) });
    ctx.addText(s, { x: x + 8, y: 288, w: w - 16, h: 26, text: label, fontSize: index === 1 ? 13 : 14, bold: true, color: C.ink, align: "center" });
    ctx.addText(s, { x: x + 8, y: 326, w: w - 16, h: 20, text: note, fontSize: 10, color: C.body, align: "center" });
    if (index < 2) ctx.addText(s, { x: x + w + 2, y: 302, w: 18, h: 24, text: ">", fontSize: 17, bold: true, color: C.teal, align: "center" });
  });
  ctx.addText(s, { x: 64, y: 390, w: 344, h: 34, text: "Two physical boards exchanged the same bidirectional sequence 100.", fontSize: 12, color: C.body });

  ctx.addText(s, { x: 462, y: 302, w: 30, h: 28, text: ">", fontSize: 22, bold: true, color: C.teal, align: "center" });
  ctx.addShape(s, { x: 502, y: 186, w: 438, h: 284, fill: C.blueSoft, line: ctx.line(C.blue, 3) });
  ctx.addText(s, { x: 526, y: 204, w: 380, h: 22, text: "ON-SITE AMD GPU · DEPLOYMENT OPTION", fontSize: 11, bold: true, color: C.blue });
  ctx.addText(s, { x: 526, y: 238, w: 380, h: 34, text: "Gemma stays at the farm", fontSize: 24, bold: true, color: C.ink });
  const amdRows = [
    ["Cached model", "Gemma 4 E2B weights"],
    ["ROCm + vLLM", "local OpenAI-compatible endpoint"],
    ["Python verifier", "blocks unsafe actions"],
    ["Simulator + UI", "state, receipts, and producer control"]
  ];
  amdRows.forEach(([label, note], index) => {
    const y = 286 + index * 34;
    ctx.addShape(s, { x: 526, y: y + 4, w: 5, h: 22, fill: index < 2 ? C.blue : C.teal, line: ctx.line("#00000000", 0) });
    ctx.addText(s, { x: 544, y, w: 128, h: 26, text: label, fontSize: 12, bold: true, color: C.ink });
    ctx.addText(s, { x: 678, y, w: 228, h: 26, text: note, fontSize: 12, color: C.body });
  });
  ctx.addShape(s, { x: 526, y: 426, w: 380, h: 28, fill: C.mint, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 536, y: 433, w: 360, h: 16, text: "No remote API in the action path", fontSize: 11, bold: true, color: C.teal, align: "center" });

  ctx.addText(s, { x: 950, y: 302, w: 30, h: 28, text: ">", fontSize: 22, bold: true, color: C.orange, align: "center" });
  ctx.addShape(s, { x: 990, y: 252, w: 220, h: 136, fill: C.orangeSoft, line: ctx.line(C.orange, 2) });
  ctx.addText(s, { x: 1012, y: 270, w: 174, h: 20, text: "LOCAL LAN", fontSize: 10, bold: true, color: C.orange, align: "center" });
  ctx.addText(s, { x: 1012, y: 302, w: 174, h: 30, text: "Producer control", fontSize: 18, bold: true, color: C.ink, align: "center" });
  ctx.addText(s, { x: 1012, y: 342, w: 174, h: 28, text: "Approve risky actions and inspect receipts.", fontSize: 11, color: C.body, align: "center" });

  ctx.addShape(s, { x: 502, y: 500, w: 708, h: 70, fill: C.white, line: ctx.line(C.line, 1) });
  ctx.addText(s, { x: 524, y: 518, w: 150, h: 22, text: "OPTIONAL CLOUD", fontSize: 11, bold: true, color: C.orange });
  ctx.addText(s, { x: 684, y: 512, w: 502, h: 34, text: "Sync evidence and model updates when connectivity returns; never required to verify or execute.", fontSize: 13, color: C.body, valign: "mid" });

  ctx.addShape(s, { x: 42, y: 604, w: 1168, h: 50, fill: C.orangeSoft, line: ctx.line(C.orange, 1) });
  ctx.addText(s, { x: 64, y: 619, w: 180, h: 22, text: "POWER BOUNDARY", fontSize: 11, bold: true, color: C.orange });
  ctx.addText(s, { x: 248, y: 613, w: 930, h: 28, text: "AMD compute still needs electricity; solar + battery autonomy is the next measured field proof.", fontSize: 13, color: C.ink, valign: "mid" });
  footer(ctx, s, "AMD inference is proven on the assigned notebook; a farm-installed AMD GPU remains the next hardware deployment step.");
  return s;
}`,

  `import { C, base, title, body, footer } from "./common.mjs";
export default async function slide08(presentation, ctx) {
  const s = base(presentation, ctx, "Producer control");
  title(ctx, s, "Risky actions stop for a human decision.", { x: 52, y: 78, w: 600, h: 110, size: 42 });
  body(ctx, s, "The producer sees the proposed change, safety result, and current chemistry before choosing what happens next.", 56, 210, 540, 94, C.body, 18);
  ctx.addText(s, { x: 56, y: 348, w: 520, h: 88, text: "No irreversible action\\nruns silently.", fontSize: 34, bold: true, color: C.orange });
  ctx.addShape(s, { x: 690, y: 112, w: 462, h: 108, fill: C.greenSoft, line: ctx.line(C.green, 2) });
  ctx.addText(s, { x: 722, y: 134, w: 132, h: 32, text: "APPROVE", fontSize: 18, bold: true, color: C.green });
  ctx.addText(s, { x: 868, y: 132, w: 250, h: 48, text: "Execute the verified proposal exactly once.", fontSize: 14, color: C.ink });
  ctx.addShape(s, { x: 690, y: 252, w: 462, h: 108, fill: C.orangeSoft, line: ctx.line(C.orange, 2) });
  ctx.addText(s, { x: 722, y: 274, w: 132, h: 32, text: "APPLY HALF", fontSize: 18, bold: true, color: C.orange });
  ctx.addText(s, { x: 868, y: 272, w: 250, h: 48, text: "Reduce the action, then verify the edited amount again.", fontSize: 14, color: C.ink });
  ctx.addShape(s, { x: 690, y: 392, w: 462, h: 108, fill: C.redSoft, line: ctx.line(C.red, 2) });
  ctx.addText(s, { x: 722, y: 414, w: 132, h: 32, text: "REJECT", fontSize: 18, bold: true, color: C.red });
  ctx.addText(s, { x: 868, y: 412, w: 250, h: 48, text: "Resume the workflow with zero simulator mutation.", fontSize: 14, color: C.ink });
  ctx.addShape(s, { x: 918, y: 220, w: 3, h: 32, fill: C.line, line: ctx.line("#00000000", 0) });
  ctx.addShape(s, { x: 918, y: 360, w: 3, h: 32, fill: C.line, line: ctx.line("#00000000", 0) });
  footer(ctx, s, "Producer decisions are replaced in place by a receipt containing mutation status, chemistry, and verifier reward.");
  return s;
}`,

  `import { C, base, title, body, footer } from "./common.mjs";
export default async function slide09(presentation, ctx) {
  const s = base(presentation, ctx, "AMD Gemma proof", true);
  title(ctx, s, "Verifier feedback turns 10% first-pass safety into 100%.", { y: 62, h: 82, size: 37, color: C.white });
  body(ctx, s, "Exact verifier failures return as bounded feedback; every revision is parsed and verified again.", 48, 152, 920, 32, "#c2d6dd", 16);
  const columns = [
    { x: 52, label: "CAPTURED AMD RUNTIME", color: C.blue, heading: "Gemma 4 E2B", lines: ["PyTorch 2.10 · ROCm 7.2", "vLLM 0.20.2 · gfx1100", "47.98 GiB AMD GPU memory"] },
    { x: 450, label: "20-EMERGENCY REPAIR", color: C.teal2, heading: "18 repairs · zero fallback", lines: ["2/20 first answers safe", "17 repaired once · 1 twice", "20/20 model-safe · no weight update"] },
    { x: 848, label: "MEASURED EXECUTION", color: C.orange, heading: "139 requests", lines: ["60,385 observed tokens", "99.793 completion tokens/s", "p50 latency · 655.522 ms"] }
  ];
  columns.forEach(({ x, label, color, heading, lines }) => {
    ctx.addText(s, { x: x + 12, y: 214, w: 320, h: 24, text: label, fontSize: 11, bold: true, color });
    ctx.addShape(s, { x, y: 252, w: 350, h: 246, fill: "#173f50", line: ctx.line(color, 2) });
    ctx.addText(s, { x: x + 24, y: 276, w: 302, h: 48, text: heading, fontSize: 21, bold: true, color: C.white });
    lines.forEach((line, index) => {
      ctx.addShape(s, { x: x + 30, y: 344 + index * 42, w: 5, h: 24, fill: color, line: ctx.line("#00000000", 0) });
      ctx.addText(s, { x: x + 48, y: 344 + index * 42, w: 270, h: 27, text: line, fontSize: 14, color: "#c2d6dd" });
    });
  });
  ctx.addText(s, { x: 52, y: 532, w: 1146, h: 54, text: "420.648 kg aggregate scenario biomass · +221.7244 mean reward vs naive", fontSize: 21, bold: true, color: "#8ee7d5", align: "center" });
  footer(ctx, s, "Captured inference-time repair experiment; the public URL remains on its private 8 GB host and CPU fallback.", true);
  return s;
}`,

  `import { C, A, title, body } from "./common.mjs";
export default async function slide10(presentation, ctx) {
  const s = presentation.slides.add();
  ctx.addShape(s, { x: 0, y: 0, w: 1280, h: 720, fill: C.fog });
  ctx.addShape(s, { x: 0, y: 0, w: 18, h: 720, fill: C.orange });
  ctx.addText(s, { x: 54, y: 42, w: 240, h: 24, text: "PROTEINLOOP", fontSize: 14, bold: true, color: C.teal });
  ctx.addText(s, { x: 54, y: 92, w: 510, h: 190, text: "Protect protein production where connectivity cannot be assumed.", fontSize: 38, bold: true, color: C.ink, typeface: ctx.fonts.title });
  body(ctx, s, "A verifier-gated, producer-controlled platform for rural farms, cooperatives, and food-security programs.", 58, 304, 490, 82, C.body, 17);
  const proofs = [
    ["PRIVATE FIELD LINK", "Two physical nRF9151 radios"],
    ["LOCAL INTELLIGENCE", "Self-hosted Gemma 4"],
    ["EXECUTABLE SAFETY", "Deterministic verifier + RLVR"]
  ];
  proofs.forEach(([label, note], i) => {
    const y = 426 + i * 64;
    ctx.addShape(s, { x: 58, y: y + 3, w: 6, h: 42, fill: i === 0 ? C.blue : i === 1 ? C.teal : C.orange, line: ctx.line("#00000000", 0) });
    ctx.addText(s, { x: 82, y, w: 220, h: 20, text: label, fontSize: 11, bold: true, color: C.ink });
    ctx.addText(s, { x: 304, y, w: 244, h: 24, text: note, fontSize: 13, color: C.body });
  });
  ctx.addText(s, { x: 58, y: 626, w: 500, h: 22, text: "proteinloop.dev-vb.lat  |  Best Unicorn", fontSize: 14, bold: true, color: C.orange });
  ctx.addText(s, { x: 58, y: 654, w: 500, h: 20, text: "github.com/Anarpego/ProteinLoop", fontSize: 12, bold: true, color: C.teal });
  ctx.addShape(s, { x: 610, y: 0, w: 670, h: 720, fill: C.white, line: ctx.line("#00000000", 0) });
  await ctx.addImage(s, { path: A.recovery, x: 610, y: 0, w: 670, h: 720, fit: "cover", alt: "ProteinLoop living tank" });
  ctx.addShape(s, { x: 610, y: 622, w: 670, h: 98, fill: "#102d3ccc", line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 646, y: 646, w: 590, h: 34, text: "ASK: BEST UNICORN", fontSize: 23, bold: true, color: C.white, align: "center" });
  return s;
}`
];

for (const [index, source] of slides.entries()) {
  await fs.writeFile(path.join(slidesDir, `slide-${String(index + 1).padStart(2, "0")}.mjs`), source);
}

console.log(JSON.stringify({ workspace, slidesDir, slideCount: slides.length }, null, 2));
