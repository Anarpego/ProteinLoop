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
  pythonTests: 222,
  phoenixTests: 141,
  totalTests: 363,
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
    "task mode: create",
    "primary deck-profile: engineering-platform",
    "secondary profile gates: startup pitch, food security, product proof",
    "required proof objects: real product UI, authority flow, sourced market wedge, buyer and revenue model, local-farm containment architecture, producer decision surface, AMD repair bridge",
    "source assets: operator-overview.png, agent-recovery.png, repository evidence artifacts",
    "brand constraints: no invented AMD or Nordic logos; use verified ProteinLoop product captures and typography only",
    "QA gates: 16:9, five or more macro-layout families, no generic card cadence, attached directional flow, honest proven-versus-next boundaries",
    "known boundary: AMD ROCm/vLLM is captured experiment evidence; current public inference remains CPU llama.cpp",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "source-notes.txt"),
  [
    "Product captures were provided by the user from the deployed ProteinLoop application.",
    "Operator overview: submission/deck-assets/operator-overview.png.",
    "Agent recovery and cover image: submission/deck-assets/agent-recovery.png.",
    `Executable evidence verified July 12, 2026: ${data.pythonTests} Python tests and ${data.phoenixTests} Phoenix tests, zero failures.`,
    "Physical evidence: two nRF9151 boards exchanged matching bidirectional DECT NR+ sequence 100.",
    "AMD deployment basis: https://rocm.docs.amd.com/en/7.13.0-preview/ai-inference/vllm.html documents local vLLM inference and serving on supported AMD GPUs and APUs.",
    "Offline model basis: https://huggingface.co/docs/transformers/installation documents pre-caching model files and HF_HUB_OFFLINE=1 for offline or firewalled operation.",
    "Market evidence: https://www.fao.org/newsroom/detail/sofia-2026--global-fisheries-and-aquaculture-production-reaches-new-highs/en reports 103 million tonnes of aquaculture aquatic-animal production in 2024, valued at $371 billion at farm gate.",
    "Boundary: the assigned AMD notebook run is captured proof; a farm-installed AMD GPU and measured solar autonomy remain deployment work.",
    "No external identity marks are drawn or approximated.",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "reference-audit.txt"),
  [
    "The source deck was accurate and clean but several slides still read like formatted documentation.",
    "Preserve: verified product captures, light/dark rhythm, teal/orange/blue semantics, deterministic-verifier language, honest proof boundaries.",
    "Improve: editorial typography, image-led proof, fewer outlines, stronger whitespace, explicit containment, and data-led evidence bridges.",
    "Avoid: generic equal-weight cards, decorative gradients, vague AI labels, live-public AMD claims, and unmeasured solar or sensor claims.",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "claim-spine.txt"),
  [
    "01 ProteinLoop keeps living protein systems understandable and recoverable at the edge.",
    "02 One shared water loop means one chemistry failure threatens every food output.",
    "03 The deployed product makes animal behavior, chemistry, biomass, and action visible together.",
    "04 Four specialists and one supervisor turn live state into a visible recovery mission.",
    "05 Gemma can recommend, but only deterministic rules can admit mutation.",
    "06 A $371B aquaculture economy creates a large market for a local resilience layer; ProteinLoop starts with hard-to-connect fish and prawn operators.",
    "07 An on-site AMD GPU can keep the decision loop local while DECT NR+ carries the field hop.",
    "08 The workflow pauses at the only irreversible boundary for a producer decision.",
    "09 Verifier feedback turns 10% first-pass safety into 100% model-safe plans on the captured AMD runtime.",
    "10 ProteinLoop lands at one tank, earns through deployment and recurring site software, then expands through farms and cooperative networks.",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "design-system.txt"),
  [
    "slide size: 1280x720, 16:9",
    "backgrounds: warm paper, pure white, and deep ocean ink in a deliberate light/dark rhythm",
    "typography: Avenir Next for titles and body; claim titles 38-52 px; body 15-19 px; compact evidence labels 10-12 px",
    "palette: ocean ink base, ProteinLoop teal, water blue, safety orange, and restrained red/green states",
    "chart grammar: direct labels, one dominant bridge or metric, no legends, no decorative axes",
    "diagram grammar: explicit local-farm containment, left-to-right authority, and a separate downward rejection branch",
    "connector grammar: thin attached rails with consistent direction and no crossings",
    "container grammar: fill-only zones for real system boundaries or decision surfaces; outlines are secondary",
    "footer grammar: quiet 9 px evidence note above a hairline rule; slide marker at top right",
    "title/kicker grammar: named marker and label pair, then a conclusion-sized claim",
    "brand policy: use real ProteinLoop UI captures; do not fabricate AMD or Nordic marks",
    "allowed layout families: immersive cover, dependency editorial, product annotation, full-bleed sequence, authority flow, metric composition, containment architecture, decision surface, evidence bridge, immersive close",
    "banned motifs: generic feature-card grids, decorative gradients, floating arrows, oversized pills, and unproven hardware claims",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "contact-sheet-plan.txt"),
  [
    "01 immersive product cover with dark editorial veil",
    "02 asymmetric shared-risk argument with branching output spine",
    "03 annotated deployed-product capture",
    "04 full-bleed live recovery capture with five-step sequence rail",
    "05 horizontal authority flow with emphasized verifier gate and rejection lane",
    "06 dark market-and-business composition with sourced scale, buyer, revenue, and expansion path",
    "07 local-farm containment architecture with external cloud and power boundaries",
    "08 single producer decision surface with live chemistry context",
    "09 dark first-pass-to-model-safe data bridge with runtime proof rail",
    "10 immersive startup close with beachhead, revenue, expansion, and dual-prize ask",
    "gate: no three consecutive slides share a macro layout; no generic card-grid cadence",
    "",
  ].join("\n"),
);

const common = `
export const C = {
  ink: "#082531",
  navy: "#0b2f3f",
  navy2: "#123d4d",
  paper: "#f5f7f3",
  white: "#ffffff",
  body: "#4e646d",
  muted: "#71858c",
  line: "#cbd8d5",
  lineDark: "#315665",
  teal: "#0a887c",
  teal2: "#3fc1aa",
  mint: "#dff4ed",
  blue: "#367fd0",
  blueSoft: "#e2effa",
  orange: "#ef6b32",
  orangeSoft: "#fff0e7",
  green: "#2f9c68",
  greenSoft: "#e2f3e9",
  red: "#d94b60",
  redSoft: "#fae7eb",
  yellow: "#f0c95a"
};

export const TYPE = {
  title: "Avenir Next",
  body: "Avenir Next",
  condensed: "Avenir Next Condensed"
};

export const A = {
  cover: ${JSON.stringify(path.join(root, "submission/cover.png"))},
  overview: ${JSON.stringify(path.join(assetDir, "operator-overview.png"))},
  recovery: ${JSON.stringify(path.join(assetDir, "agent-recovery.png"))}
};

export function base(presentation, ctx, section, page, dark = false) {
  const s = presentation.slides.add();
  ctx.addShape(s, { x: 0, y: 0, w: ctx.W, h: ctx.H, fill: dark ? C.navy : C.paper });
  ctx.addShape(s, { x: 42, y: 52, w: 1196, h: 1, fill: dark ? C.lineDark : C.line, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 42, y: 20, w: 220, h: 22, text: "PROTEINLOOP", fontSize: 12, bold: true, color: dark ? C.teal2 : C.teal, typeface: TYPE.body, valign: "mid" });
  ctx.addText(s, { x: 950, y: 20, w: 240, h: 22, text: section.toUpperCase(), fontSize: 9, bold: true, color: dark ? "#9fb8c1" : C.muted, typeface: TYPE.body, align: "right", valign: "mid" });
  ctx.addText(s, { x: 1200, y: 20, w: 38, h: 22, text: String(page).padStart(2, "0"), fontSize: 10, bold: true, color: dark ? C.orange : C.ink, typeface: TYPE.body, align: "right", valign: "mid" });
  return s;
}

export function kicker(ctx, s, text, x, y, color = C.orange) {
  ctx.addShape(s, { name: "kicker-marker", x, y: y + 7, w: 8, h: 8, fill: color, line: ctx.line("#00000000", 0), geometry: "ellipse" });
  ctx.addText(s, { name: "kicker-label", x: x + 18, y, w: 280, h: 22, text: text.toUpperCase(), fontSize: 10, bold: true, color, typeface: TYPE.body, valign: "mid" });
}

export function title(ctx, s, text, options = {}) {
  ctx.addText(s, {
    x: options.x ?? 42,
    y: options.y ?? 74,
    w: options.w ?? 1120,
    h: options.h ?? 98,
    text,
    fontSize: options.size ?? 40,
    bold: true,
    color: options.color ?? C.ink,
    typeface: TYPE.title,
    valign: options.valign ?? "mid"
  });
}

export function body(ctx, s, text, x, y, w, h, color = C.body, size = 16, options = {}) {
  ctx.addText(s, { x, y, w, h, text, fontSize: size, color, typeface: TYPE.body, valign: options.valign ?? "mid", align: options.align ?? "left" });
}

export function label(ctx, s, text, x, y, w, color = C.muted, options = {}) {
  ctx.addText(s, { x, y, w, h: options.h ?? 22, text: text.toUpperCase(), fontSize: options.size ?? 10, bold: true, color, typeface: TYPE.body, align: options.align ?? "left", valign: "mid" });
}

export function footer(ctx, s, text, dark = false) {
  ctx.addShape(s, { x: 42, y: 666, w: 1196, h: 1, fill: dark ? C.lineDark : C.line, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 42, y: 676, w: 1160, h: 16, text, fontSize: 8.5, color: dark ? "#8faab4" : C.muted, typeface: TYPE.body });
}

export function flowArrow(ctx, s, x, y, w, color = C.teal) {
  ctx.addShape(s, { x, y: y + 11, w: w - 22, h: 2, fill: color, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: x + w - 24, y, w: 24, h: 24, text: ">", fontSize: 17, bold: true, color, typeface: TYPE.body, align: "center", valign: "mid" });
}

export function node(ctx, s, { x, y, w, h, label: nodeLabel, detail, fill = C.white, line = C.teal, number, labelSize = 16, labelHeight = 44, detailY = 72, detailSize = 11, lineWidth = 0, textColor = C.ink }) {
  ctx.addShape(s, { x, y, w, h, fill, line: ctx.line(line, lineWidth) });
  if (number) {
    ctx.addText(s, { x: x + 16, y: y + 14, w: 34, h: 28, text: number, fontSize: 23, bold: true, color: line, typeface: TYPE.title, valign: "mid" });
  }
  ctx.addText(s, { x: x + (number ? 58 : 18), y: y + 12, w: w - (number ? 74 : 36), h: labelHeight, text: nodeLabel, fontSize: labelSize, bold: true, color: textColor, typeface: TYPE.title, valign: "mid" });
  if (detail) ctx.addText(s, { x: x + 18, y: y + detailY, w: w - 36, h: h - detailY - 18, text: detail, fontSize: detailSize, color: textColor === C.white ? "#dce8ec" : C.body, typeface: TYPE.body, valign: "top" });
}
`;

await fs.writeFile(path.join(slidesDir, "common.mjs"), common);

const slides = [
  `import { C, TYPE, A, label } from "./common.mjs";
export default async function slide01(presentation, ctx) {
  const s = presentation.slides.add();
  await ctx.addImage(s, { path: A.recovery, x: 0, y: 0, w: ctx.W, h: ctx.H, fit: "cover", alt: "ProteinLoop living tank and verified recovery control" });
  ctx.addShape(s, { x: 0, y: 0, w: 616, h: 720, fill: "#082531f8", line: ctx.line("#00000000", 0) });
  ctx.addShape(s, { x: 48, y: 54, w: 6, h: 48, fill: C.teal2, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 70, y: 54, w: 420, h: 22, text: "PROTEINLOOP", fontSize: 14, bold: true, color: C.teal2, typeface: TYPE.body, valign: "mid" });
  ctx.addText(s, { x: 70, y: 81, w: 460, h: 20, text: "AMD DEVELOPER HACKATHON · ACT II", fontSize: 9.5, bold: true, color: "#b8cbd2", typeface: TYPE.body, valign: "mid" });
  ctx.addText(s, { x: 64, y: 150, w: 500, h: 190, text: "Local AI for living protein systems.", fontSize: 52, bold: true, color: C.white, typeface: TYPE.title, valign: "mid" });
  ctx.addText(s, { x: 68, y: 352, w: 455, h: 72, text: "Keep fish, prawns, plants, duckweed, and eggs recoverable when cloud access disappears.", fontSize: 19, color: "#d5e3e7", typeface: TYPE.body, valign: "mid" });
  ctx.addShape(s, { x: 68, y: 470, w: 470, h: 1, fill: C.lineDark, line: ctx.line("#00000000", 0) });
  const proofs = [
    ["GEMMA 4 E2B", "local planning"],
    ["DECT NR+", "private field link"],
    ["RULES", "deterministic safety"]
  ];
  proofs.forEach(([name, note], index) => {
    const x = 68 + index * 160;
    ctx.addShape(s, { x, y: 494, w: 4, h: 46, fill: index === 0 ? C.teal2 : index === 1 ? C.blue : C.orange, line: ctx.line("#00000000", 0) });
    ctx.addText(s, { x: x + 14, y: 492, w: 132, h: 22, text: name, fontSize: 11, bold: true, color: C.white, typeface: TYPE.body, valign: "mid" });
    ctx.addText(s, { x: x + 14, y: 518, w: 132, h: 20, text: note, fontSize: 9.5, color: "#9fb8c1", typeface: TYPE.body, valign: "mid" });
  });
  label(ctx, s, "BEST UNICORN", 68, 622, 160, C.orange, { size: 10 });
  ctx.addText(s, { x: 68, y: 650, w: 450, h: 20, text: "proteinloop.dev-vb.lat", fontSize: 13, bold: true, color: C.white, typeface: TYPE.body });
  return s;
}`,

  `import { C, TYPE, base, kicker, title, body, label, footer } from "./common.mjs";
export default async function slide02(presentation, ctx) {
  const s = base(presentation, ctx, "Shared risk", 2);
  kicker(ctx, s, "one loop · shared failure", 52, 78, C.red);
  title(ctx, s, "One ammonia spike threatens every protein output.", { x: 52, y: 104, w: 650, h: 118, size: 44 });
  body(ctx, s, "Aquaponics is usually framed as vegetables. ProteinLoop measures what the same water failure means for animals and downstream food.", 56, 236, 570, 92, C.body, 17);
  ctx.addShape(s, { x: 56, y: 374, w: 558, h: 1, fill: C.line, line: ctx.line("#00000000", 0) });
  label(ctx, s, "ANIMAL PROTEIN AT RISK", 56, 402, 260, C.red);
  ctx.addText(s, { x: 54, y: 430, w: 300, h: 74, text: "14.5 kg", fontSize: 54, bold: true, color: C.ink, typeface: TYPE.title, valign: "mid" });
  body(ctx, s, "fish + prawn stock breathing the same water", 58, 508, 430, 48, C.body, 15);

  ctx.addShape(s, { x: 770, y: 168, w: 3, h: 378, fill: C.red, line: ctx.line("#00000000", 0) });
  ctx.addShape(s, { x: 724, y: 320, w: 96, h: 96, fill: C.red, line: ctx.line("#00000000", 0), geometry: "ellipse" });
  ctx.addText(s, { x: 734, y: 340, w: 76, h: 28, text: "NH3", fontSize: 22, bold: true, color: C.white, typeface: TYPE.title, align: "center", valign: "mid" });
  ctx.addText(s, { x: 734, y: 371, w: 76, h: 18, text: "spike", fontSize: 10, bold: true, color: C.white, typeface: TYPE.body, align: "center", valign: "mid" });
  const outputs = [
    { y: 174, value: "14.5 kg", name: "fish + prawns", note: "breathing risk", color: C.blue },
    { y: 326, value: "5.0 kg", name: "plants", note: "filtration loss", color: C.teal },
    { y: 478, value: "eggs", name: "downstream protein", note: "feed-loop impact", color: C.orange }
  ];
  outputs.forEach(({ y, value, name, note, color }) => {
    ctx.addShape(s, { x: 770, y: y + 34, w: 76, h: 2, fill: color, line: ctx.line("#00000000", 0) });
    ctx.addShape(s, { x: 840, y: y + 27, w: 16, h: 16, fill: color, line: ctx.line("#00000000", 0), geometry: "ellipse" });
    ctx.addText(s, { x: 882, y, w: 300, h: 42, text: value, fontSize: 30, bold: true, color: C.ink, typeface: TYPE.title, valign: "mid" });
    ctx.addText(s, { x: 884, y: y + 45, w: 190, h: 24, text: name, fontSize: 13, bold: true, color: C.ink, typeface: TYPE.body, valign: "mid" });
    ctx.addText(s, { x: 1080, y: y + 45, w: 130, h: 24, text: note, fontSize: 11, color: C.muted, typeface: TYPE.body, align: "right", valign: "mid" });
  });
  footer(ctx, s, "ProteinLoop makes animal protein a first-class operational outcome, not a hidden side effect.");
  return s;
}`,

  `import { C, TYPE, A, base, kicker, title, body, label, footer } from "./common.mjs";
export default async function slide03(presentation, ctx) {
  const s = base(presentation, ctx, "Product proof", 3);
  kicker(ctx, s, "deployed operator view", 52, 78, C.teal);
  title(ctx, s, "A living system people can understand in seconds.", { x: 52, y: 104, w: 850, h: 96, size: 39 });
  body(ctx, s, "The tank, chemistry, biomass, and recovery controls share one visual language.", 56, 206, 760, 30, C.body, 15);

  const notes = [
    ["01", "ANIMALS", "Movement changes with water stress."],
    ["02", "WATER", "Ammonia is waste; oxygen is breathable air."],
    ["03", "ACTION", "Verified recovery stays in the same scene."]
  ];
  notes.forEach(([number, name, note], index) => {
    const y = 276 + index * 108;
    ctx.addText(s, { x: 54, y, w: 50, h: 32, text: number, fontSize: 20, bold: true, color: index === 0 ? C.blue : index === 1 ? C.teal : C.orange, typeface: TYPE.title, valign: "mid" });
    label(ctx, s, name, 116, y + 2, 150, C.ink, { size: 10 });
    body(ctx, s, note, 116, y + 30, 200, 48, C.body, 13, { valign: "top" });
    if (index < notes.length - 1) ctx.addShape(s, { x: 54, y: y + 91, w: 260, h: 1, fill: C.line, line: ctx.line("#00000000", 0) });
  });
  ctx.addShape(s, { x: 348, y: 246, w: 870, h: 388, fill: C.white, line: ctx.line(C.line, 1) });
  await ctx.addImage(s, { path: A.overview, x: 362, y: 260, w: 842, h: 360, fit: "cover", alt: "ProteinLoop deployed operator overview" });
  ctx.addShape(s, { x: 348, y: 246, w: 6, h: 388, fill: C.teal, line: ctx.line("#00000000", 0) });
  ctx.addShape(s, { x: 968, y: 230, w: 214, h: 34, fill: C.navy, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 980, y: 237, w: 190, h: 20, text: "LIVE DEPLOYED PRODUCT", fontSize: 10, bold: true, color: C.white, typeface: TYPE.body, align: "center", valign: "mid" });
  footer(ctx, s, "Real deployed UI at proteinloop.dev-vb.lat; the tank is rendered live, not a looping video.");
  return s;
}`,

  `import { C, TYPE, A } from "./common.mjs";
export default async function slide04(presentation, ctx) {
  const s = presentation.slides.add();
  await ctx.addImage(s, { path: A.recovery, x: 0, y: 0, w: ctx.W, h: ctx.H, fit: "cover", alt: "Live ProteinLoop recovery mission" });
  ctx.addShape(s, { x: 0, y: 0, w: 1280, h: 132, fill: "#082531ec", line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 46, y: 22, w: 820, h: 48, text: "The recovery is visible while it happens.", fontSize: 34, bold: true, color: C.white, typeface: TYPE.title, valign: "mid" });
  ctx.addText(s, { x: 48, y: 78, w: 860, h: 28, text: "Every specialist, verifier outcome, and producer boundary appears as a structured event.", fontSize: 14, color: "#c4d5da", typeface: TYPE.body, valign: "mid" });
  ctx.addShape(s, { x: 0, y: 618, w: 1280, h: 102, fill: "#082531ee", line: ctx.line("#00000000", 0) });
  const steps = [["1", "Observe"], ["2", "Specialists"], ["3", "Supervisor"], ["4", "Verify"], ["5", "Measure"]];
  steps.forEach(([number, step], index) => {
    const x = 48 + index * 238;
    ctx.addShape(s, { x, y: 644, w: 28, h: 28, fill: index === 3 ? C.orange : C.teal, line: ctx.line("#00000000", 0), geometry: "ellipse" });
    ctx.addText(s, { x, y: 649, w: 28, h: 18, text: number, fontSize: 10, bold: true, color: C.white, typeface: TYPE.body, align: "center", valign: "mid" });
    ctx.addText(s, { x: x + 40, y: 642, w: 154, h: 22, text: step, fontSize: 13, bold: true, color: C.white, typeface: TYPE.body, valign: "mid" });
    if (index < steps.length - 1) ctx.addShape(s, { x: x + 40, y: 674, w: 158, h: 2, fill: C.lineDark, line: ctx.line("#00000000", 0) });
  });
  ctx.addText(s, { x: 48, y: 694, w: 1140, h: 14, text: "Structured events and tool outcomes are visible; private model chain-of-thought is not presented as evidence.", fontSize: 8.5, color: "#8faab4", typeface: TYPE.body });
  return s;
}`,

  `import { C, TYPE, base, kicker, title, body, label, node, flowArrow, footer } from "./common.mjs";
export default async function slide05(presentation, ctx) {
  const s = base(presentation, ctx, "Safety boundary", 5);
  kicker(ctx, s, "authority, not autonomy", 52, 78, C.orange);
  title(ctx, s, "Gemma can recommend. It cannot mutate.", { x: 52, y: 104, w: 940, h: 70, size: 42 });
  body(ctx, s, "Only the deterministic verifier can admit an action into ecosystem state.", 56, 180, 780, 34, C.body, 15);

  const stages = [
    { x: 52, w: 240, stage: "PROPOSE", number: "1", name: "Gemma specialists", detail: "Fish, prawn, plant, and feed-loop briefs.", fill: C.mint, color: C.teal },
    { x: 350, w: 188, stage: "SYNTHESIZE", number: "2", name: "Supervisor", detail: "One bounded recovery proposal.", fill: C.blueSoft, color: C.blue },
    { x: 596, w: 276, stage: "GATE", number: "3", name: "Deterministic verifier", detail: "Chemistry, feed, exchange, reserve, and collapse rules.", fill: C.orangeSoft, color: C.orange },
    { x: 930, w: 252, stage: "MUTATE", number: "4", name: "Simulator state", detail: "Only admitted actions can change the living system.", fill: C.greenSoft, color: C.green }
  ];
  stages.forEach(({ x, w, stage, number, name, detail, fill, color }, index) => {
    label(ctx, s, stage, x, 246, w, color, { align: "center", size: 9 });
    node(ctx, s, { x, y: 278, w, h: 176, label: name, detail, fill, line: color, number, labelSize: index === 2 ? 15 : 16, labelHeight: 44, detailY: 72, detailSize: 11, lineWidth: index === 2 ? 2 : 0 });
  });
  flowArrow(ctx, s, 300, 354, 42, C.teal);
  flowArrow(ctx, s, 546, 354, 42, C.blue);
  flowArrow(ctx, s, 880, 354, 42, C.orange);

  ctx.addShape(s, { x: 732, y: 454, w: 3, h: 62, fill: C.red, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 720, y: 486, w: 28, h: 22, text: "v", fontSize: 16, bold: true, color: C.red, typeface: TYPE.body, align: "center" });
  ctx.addShape(s, { x: 596, y: 516, w: 586, h: 78, fill: C.redSoft, line: ctx.line("#00000000", 0) });
  label(ctx, s, "BLOCKED", 618, 536, 100, C.red, { size: 10 });
  body(ctx, s, "Rejected before state change, written to the RLVR trace, then returned as verifier feedback.", 744, 528, 410, 42, C.ink, 14);
  ctx.addText(s, { x: 52, y: 538, w: 480, h: 38, text: "Gemma proposes. Rules decide.", fontSize: 24, bold: true, color: C.ink, typeface: TYPE.title, valign: "mid" });
  footer(ctx, s, "verify_ecosystem_safety is the only authority allowed to admit simulator mutation.");
  return s;
}`,

  `import { C, TYPE, base, kicker, title, body, label, footer } from "./common.mjs";
export default async function slide06(presentation, ctx) {
  const s = base(presentation, ctx, "Business case", 6, true);
  kicker(ctx, s, "unicorn market wedge", 52, 78, C.teal2);
  title(ctx, s, "A $371B aquaculture economy needs a resilience layer.", { x: 52, y: 102, w: 1050, h: 92, size: 39, color: C.white });
  body(ctx, s, "FAO reports 103M tonnes of farmed aquatic animals in 2024. ProteinLoop starts where cloud-first control is a poor fit.", 56, 200, 1010, 34, "#bcd0d7", 15);

  ctx.addText(s, { x: 52, y: 262, w: 292, h: 76, text: "$371B", fontSize: 62, bold: true, color: C.yellow, typeface: TYPE.title, valign: "mid" });
  label(ctx, s, "2024 FARM-GATE VALUE", 58, 344, 252, C.white, { size: 10 });
  ctx.addText(s, { x: 52, y: 382, w: 292, h: 58, text: "103M t", fontSize: 45, bold: true, color: C.teal2, typeface: TYPE.title, valign: "mid" });
  body(ctx, s, "aquaculture aquatic-animal production", 58, 444, 278, 42, "#9fb8c1", 11.5, { valign: "top" });

  ctx.addShape(s, { x: 390, y: 264, w: 1, h: 224, fill: C.lineDark, line: ctx.line("#00000000", 0) });
  label(ctx, s, "WHO PAYS", 442, 266, 220, C.orange, { size: 10 });
  const buyers = ["Fish + prawn farms", "Producer cooperatives", "Food-security programs"];
  buyers.forEach((item, index) => {
    const y = 308 + index * 46;
    ctx.addShape(s, { x: 442, y: y + 5, w: 8, h: 8, fill: C.orange, line: ctx.line("#00000000", 0), geometry: "ellipse" });
    ctx.addText(s, { x: 466, y, w: 250, h: 22, text: item, fontSize: 13, bold: true, color: C.white, typeface: TYPE.body, valign: "mid" });
  });
  body(ctx, s, "The buyer is the operator accountable for biomass survival and production continuity.", 442, 452, 292, 50, "#9fb8c1", 11.5, { valign: "top" });

  label(ctx, s, "HOW IT EARNS", 796, 266, 220, C.blue, { size: 10 });
  const revenue = [
    ["DEPLOY", "Edge commissioning + radio gateway"],
    ["SUBSCRIBE", "Annual site software + support"],
    ["EXPAND", "Optional fleet and evidence service"]
  ];
  revenue.forEach(([name, note], index) => {
    const y = 306 + index * 58;
    ctx.addText(s, { x: 796, y, w: 112, h: 22, text: name, fontSize: 10, bold: true, color: index === 0 ? C.orange : index === 1 ? C.teal2 : C.blue, typeface: TYPE.body, valign: "mid" });
    ctx.addText(s, { x: 918, y, w: 286, h: 34, text: note, fontSize: 12.5, color: C.white, typeface: TYPE.body, valign: "top" });
    if (index < revenue.length - 1) ctx.addShape(s, { x: 796, y: y + 42, w: 408, h: 1, fill: C.lineDark, line: ctx.line("#00000000", 0) });
  });

  ctx.addShape(s, { x: 52, y: 536, w: 1152, h: 80, fill: C.navy2, line: ctx.line("#00000000", 0) });
  label(ctx, s, "LAND AND EXPAND", 76, 554, 200, C.teal2, { size: 9 });
  ctx.addText(s, { x: 300, y: 548, w: 860, h: 34, text: "TANK  >  SITE  >  COOPERATIVE NETWORK", fontSize: 21, bold: true, color: C.white, typeface: TYPE.title, align: "center", valign: "mid" });
  body(ctx, s, "Revenue grows with protected production capacity, not user screen time.", 300, 582, 860, 18, "#9fb8c1", 10.5, { align: "center" });
  footer(ctx, s, "Source: FAO SOFIA 2026 (2024 production): 103M tonnes and $371B farm-gate value.", true);
  return s;
}`,

  `import { C, TYPE, base, kicker, title, body, label, flowArrow, footer } from "./common.mjs";
export default async function slide07(presentation, ctx) {
  const s = base(presentation, ctx, "Off-grid architecture", 7);
  kicker(ctx, s, "local by design", 52, 78, C.teal);
  title(ctx, s, "An on-site AMD GPU can keep the decision loop local.", { x: 52, y: 106, w: 1120, h: 58, size: 35 });
  body(ctx, s, "After provisioning, cached Gemma inference and deterministic decisions do not require an internet API.", 56, 170, 960, 32, C.body, 15);

  ctx.addShape(s, { x: 52, y: 240, w: 1176, h: 298, fill: C.white, line: ctx.line(C.teal, 2) });
  ctx.addShape(s, { x: 52, y: 240, w: 1176, h: 34, fill: C.mint, line: ctx.line("#00000000", 0) });
  label(ctx, s, "LOCAL FARM BOUNDARY", 72, 246, 320, C.teal, { size: 10 });
  ctx.addText(s, { x: 948, y: 246, w: 258, h: 20, text: "No remote API in the action path", fontSize: 10, bold: true, color: C.teal, typeface: TYPE.body, align: "right", valign: "mid" });

  ctx.addShape(s, { x: 394, y: 292, w: 1, h: 222, fill: C.line, line: ctx.line("#00000000", 0) });
  ctx.addShape(s, { x: 922, y: 292, w: 1, h: 222, fill: C.line, line: ctx.line("#00000000", 0) });

  label(ctx, s, "PRIVATE FIELD LINK · PROVEN", 76, 298, 280, C.green, { size: 9 });
  const radios = [
    { x: 76, w: 88, name: "nRF9151 PT", note: "tank" },
    { x: 198, w: 84, name: "DECT NR+", note: "private" },
    { x: 316, w: 68, name: "nRF9151 FT", note: "gateway" }
  ];
  radios.forEach(({ x, w, name, note }, index) => {
    ctx.addShape(s, { x, y: 352, w, h: 84, fill: index === 1 ? C.greenSoft : C.blueSoft, line: ctx.line("#00000000", 0) });
    ctx.addText(s, { x: x + 6, y: 370, w: w - 12, h: 24, text: name, fontSize: index === 2 ? 9.5 : 11, bold: true, color: C.ink, typeface: TYPE.body, align: "center", valign: "mid" });
    ctx.addText(s, { x: x + 6, y: 402, w: w - 12, h: 18, text: note, fontSize: 9, color: C.muted, typeface: TYPE.body, align: "center", valign: "mid" });
    if (index < radios.length - 1) flowArrow(ctx, s, x + w + 6, 382, 26, C.teal);
  });
  body(ctx, s, "Two physical boards exchanged bidirectional sequence 100.", 76, 458, 292, 42, C.body, 11.5, { valign: "top" });

  ctx.addShape(s, { x: 426, y: 296, w: 466, h: 214, fill: C.navy, line: ctx.line("#00000000", 0) });
  label(ctx, s, "ON-SITE AMD GPU · DEPLOYMENT OPTION", 452, 314, 390, C.orange, { size: 9 });
  ctx.addText(s, { x: 452, y: 344, w: 390, h: 38, text: "Gemma stays at the farm.", fontSize: 25, bold: true, color: C.white, typeface: TYPE.title, valign: "mid" });
  const stack = [
    ["Cached Gemma 4 E2B", "model weights"],
    ["ROCm + vLLM", "local endpoint"],
    ["Python verifier", "safety gate"],
    ["Simulator + Phoenix", "state and UI"]
  ];
  stack.forEach(([name, note], index) => {
    const x = 452 + (index % 2) * 204;
    const y = 400 + Math.floor(index / 2) * 48;
    ctx.addShape(s, { x, y: y + 4, w: 4, h: 30, fill: index < 2 ? C.blue : C.teal2, line: ctx.line("#00000000", 0) });
    ctx.addText(s, { x: x + 14, y, w: 178, h: 20, text: name, fontSize: 11, bold: true, color: C.white, typeface: TYPE.body, valign: "mid" });
    ctx.addText(s, { x: x + 14, y: y + 21, w: 178, h: 16, text: note, fontSize: 9, color: "#9fb8c1", typeface: TYPE.body, valign: "mid" });
  });

  label(ctx, s, "LOCAL LAN · PRODUCER AUTHORITY", 950, 298, 250, C.orange, { size: 9 });
  ctx.addText(s, { x: 950, y: 348, w: 248, h: 56, text: "Approve risky actions.", fontSize: 22, bold: true, color: C.ink, typeface: TYPE.title, valign: "mid" });
  body(ctx, s, "Inspect chemistry, verifier result, and execution receipts without leaving the farm.", 952, 410, 228, 78, C.body, 13, { valign: "top" });

  ctx.addShape(s, { x: 52, y: 566, w: 548, h: 76, fill: C.orangeSoft, line: ctx.line("#00000000", 0) });
  label(ctx, s, "POWER · ALWAYS REQUIRED", 72, 584, 220, C.orange, { size: 9 });
  body(ctx, s, "AMD compute needs electricity; solar + battery autonomy is the next measured field proof.", 300, 578, 276, 48, C.ink, 11.5);
  ctx.addShape(s, { x: 626, y: 566, w: 602, h: 76, fill: C.blueSoft, line: ctx.line("#00000000", 0) });
  label(ctx, s, "CLOUD · OPTIONAL", 646, 584, 170, C.blue, { size: 9 });
  body(ctx, s, "Sync evidence and model updates when connectivity returns; never required to verify or execute.", 822, 578, 382, 48, C.ink, 11.5);
  footer(ctx, s, "AMD inference is proven on the assigned notebook; a farm-installed AMD GPU remains the next hardware deployment step.");
  return s;
}`,

  `import { C, TYPE, base, kicker, title, body, label, footer } from "./common.mjs";
export default async function slide08(presentation, ctx) {
  const s = base(presentation, ctx, "Producer control", 8);
  kicker(ctx, s, "human in the loop", 52, 78, C.orange);
  title(ctx, s, "The workflow pauses at the only irreversible boundary.", { x: 52, y: 104, w: 1080, h: 88, size: 36 });
  body(ctx, s, "The producer sees current chemistry, the proposed action, and the verifier result before anything changes.", 56, 198, 880, 30, C.body, 15);

  ctx.addShape(s, { x: 52, y: 258, w: 336, h: 322, fill: C.navy, line: ctx.line("#00000000", 0) });
  label(ctx, s, "LIVE CONTEXT", 78, 282, 180, C.teal2, { size: 9 });
  ctx.addText(s, { x: 78, y: 322, w: 132, h: 48, text: "2.75", fontSize: 39, bold: true, color: C.orange, typeface: TYPE.title, valign: "mid" });
  ctx.addText(s, { x: 210, y: 336, w: 100, h: 24, text: "mg/L NH3", fontSize: 11, bold: true, color: C.white, typeface: TYPE.body, valign: "mid" });
  ctx.addText(s, { x: 78, y: 390, w: 132, h: 48, text: "9.2", fontSize: 39, bold: true, color: C.blue, typeface: TYPE.title, valign: "mid" });
  ctx.addText(s, { x: 210, y: 404, w: 100, h: 24, text: "mg/L O2", fontSize: 11, bold: true, color: C.white, typeface: TYPE.body, valign: "mid" });
  ctx.addShape(s, { x: 78, y: 462, w: 258, h: 1, fill: C.lineDark, line: ctx.line("#00000000", 0) });
  label(ctx, s, "VERIFIED PLAN", 78, 482, 180, C.orange, { size: 9 });
  body(ctx, s, "Increase aeration. Reduce feed. Monitor the next reading.", 78, 510, 244, 52, C.white, 13, { valign: "top" });

  ctx.addShape(s, { x: 430, y: 258, w: 752, h: 322, fill: C.white, line: ctx.line(C.line, 1) });
  label(ctx, s, "PRODUCER DECISION REQUIRED", 460, 282, 330, C.orange, { size: 10 });
  ctx.addText(s, { x: 460, y: 318, w: 670, h: 38, text: "Protect the protein loop", fontSize: 26, bold: true, color: C.ink, typeface: TYPE.title, valign: "mid" });
  ctx.addShape(s, { x: 460, y: 378, w: 692, h: 1, fill: C.line, line: ctx.line("#00000000", 0) });
  const choices = [
    { y: 392, action: "APPROVE", note: "Execute the verified proposal exactly once.", color: C.green, fill: C.greenSoft },
    { y: 452, action: "APPLY HALF", note: "Reduce the amount, then verify the edit again.", color: C.orange, fill: C.orangeSoft },
    { y: 512, action: "REJECT", note: "Resume with zero simulator mutation.", color: C.red, fill: C.redSoft }
  ];
  choices.forEach(({ y, action, note, color, fill }) => {
    ctx.addShape(s, { x: 460, y, w: 692, h: 50, fill, line: ctx.line("#00000000", 0) });
    ctx.addText(s, { x: 478, y: y + 14, w: 140, h: 22, text: action, fontSize: 11, bold: true, color, typeface: TYPE.body, valign: "mid" });
    ctx.addText(s, { x: 632, y: y + 13, w: 494, h: 24, text: note, fontSize: 12.5, color: C.ink, typeface: TYPE.body, valign: "mid" });
  });
  ctx.addText(s, { x: 430, y: 608, w: 752, h: 28, text: "Every choice becomes a receipt: mutation status, chemistry, and verifier reward.", fontSize: 13, bold: true, color: C.teal, typeface: TYPE.body, align: "center", valign: "mid" });
  footer(ctx, s, "No risky or irreversible action runs silently.");
  return s;
}`,

  `import { C, TYPE, base, kicker, title, body, label, footer } from "./common.mjs";
export default async function slide09(presentation, ctx) {
  const s = base(presentation, ctx, "AMD Gemma proof", 9, true);
  kicker(ctx, s, "captured inference-time evidence", 52, 78, C.teal2);
  title(ctx, s, "Verifier feedback turns 10% first-pass safety into 100% model-safe plans.", { x: 52, y: 104, w: 1120, h: 98, size: 36, color: C.white });
  body(ctx, s, "Exact rule failures return as bounded feedback; each revision is parsed and verified again.", 56, 208, 930, 28, "#bcd0d7", 15);

  label(ctx, s, "FIRST PASS", 66, 264, 220, C.orange, { size: 10 });
  ctx.addText(s, { x: 62, y: 292, w: 228, h: 92, text: "10%", fontSize: 70, bold: true, color: C.white, typeface: TYPE.title, valign: "mid" });
  body(ctx, s, "2 / 20 safe", 68, 388, 180, 28, "#9fb8c1", 13);

  ctx.addShape(s, { x: 300, y: 338, w: 600, h: 8, fill: C.lineDark, line: ctx.line("#00000000", 0) });
  ctx.addShape(s, { x: 300, y: 338, w: 600, h: 8, fill: C.teal2, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 884, y: 320, w: 30, h: 38, text: ">", fontSize: 28, bold: true, color: C.teal2, typeface: TYPE.body, align: "center", valign: "mid" });
  ctx.addShape(s, { x: 544, y: 284, w: 194, h: 58, fill: C.orange, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 560, y: 296, w: 162, h: 30, text: "VERIFIER FEEDBACK", fontSize: 10, bold: true, color: C.white, typeface: TYPE.body, align: "center", valign: "mid" });
  ctx.addText(s, { x: 430, y: 374, w: 416, h: 34, text: "18 unsafe answers repaired", fontSize: 19, bold: true, color: C.white, typeface: TYPE.title, align: "center", valign: "mid" });
  body(ctx, s, "17 in one revision · 1 in two revisions", 430, 410, 416, 24, "#9fb8c1", 11.5, { align: "center" });

  label(ctx, s, "MODEL SAFE", 966, 264, 220, C.teal2, { size: 10, align: "right" });
  ctx.addText(s, { x: 946, y: 292, w: 240, h: 92, text: "100%", fontSize: 68, bold: true, color: C.teal2, typeface: TYPE.title, align: "right", valign: "mid" });
  body(ctx, s, "20 / 20 · zero fallback", 946, 388, 240, 28, "#9fb8c1", 13, { align: "right" });

  ctx.addShape(s, { x: 52, y: 474, w: 1136, h: 110, fill: C.navy2, line: ctx.line("#00000000", 0) });
  const proofBlocks = [
    { x: 76, label: "MODEL", heading: "Gemma 4 E2B", notes: ["ROCm 7.2 · vLLM 0.20.2", "gfx1100 · 47.98 GiB"], color: C.blue },
    { x: 356, label: "EXECUTION", heading: "139 requests", notes: ["60,385 observed tokens", "99.793 tok/s · p50 655.522 ms"], color: C.orange },
    { x: 708, label: "COMPLETENESS", heading: "363 executable checks", notes: ["222 Python + 141 Phoenix", "zero failures · no weight update"], color: C.teal2 }
  ];
  proofBlocks.forEach(({ x, label: blockLabel, heading, notes, color }, index) => {
    if (index > 0) ctx.addShape(s, { x: x - 26, y: 492, w: 1, h: 72, fill: C.lineDark, line: ctx.line("#00000000", 0) });
    label(ctx, s, blockLabel, x, 490, 220, color, { size: 8.5 });
    ctx.addText(s, { x, y: 516, w: index === 2 ? 420 : 250, h: 26, text: heading, fontSize: 16, bold: true, color: C.white, typeface: TYPE.title, valign: "mid" });
    ctx.addText(s, { x, y: 548, w: index === 0 ? 230 : index === 1 ? 300 : 420, h: 18, text: notes.join("  ·  "), fontSize: 9.5, color: "#b8cbd2", typeface: TYPE.body, valign: "mid" });
  });
  ctx.addText(s, { x: 52, y: 610, w: 1136, h: 28, text: "420.648 kg aggregate scenario biomass · +221.7244 mean reward vs naive", fontSize: 13, bold: true, color: C.yellow, typeface: TYPE.body, align: "center", valign: "mid" });
  footer(ctx, s, "Captured AMD notebook experiment; the public URL remains on its private 8 GB host and CPU fallback.", true);
  return s;
}`,

  `import { C, TYPE, A, label } from "./common.mjs";
export default async function slide10(presentation, ctx) {
  const s = presentation.slides.add();
  await ctx.addImage(s, { path: A.recovery, x: 0, y: 0, w: 1280, h: 720, fit: "cover", alt: "ProteinLoop living tank" });
  ctx.addShape(s, { x: 0, y: 0, w: 720, h: 720, fill: "#082531f6", line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 56, y: 48, w: 300, h: 24, text: "PROTEINLOOP", fontSize: 14, bold: true, color: C.teal2, typeface: TYPE.body, valign: "mid" });
  ctx.addText(s, { x: 56, y: 108, w: 584, h: 190, text: "From one tank to the operating layer for resilient aquatic food.", fontSize: 43, bold: true, color: C.white, typeface: TYPE.title, valign: "mid" });
  ctx.addText(s, { x: 60, y: 310, w: 540, h: 70, text: "Start with hard-to-connect fish and prawn farms. Expand site by site through cooperatives and food-security programs.", fontSize: 16.5, color: "#d5e3e7", typeface: TYPE.body, valign: "mid" });
  const proofs = [
    ["BEACHHEAD", "Off-grid fish + prawn farms", C.blue],
    ["REVENUE", "Deployment + annual software/support", C.teal2],
    ["SCALE", "Tank > site > cooperative network", C.orange]
  ];
  proofs.forEach(([name, note, color], index) => {
    const y = 420 + index * 56;
    ctx.addShape(s, { x: 60, y: y + 5, w: 5, h: 34, fill: color, line: ctx.line("#00000000", 0) });
    label(ctx, s, name, 82, y, 210, C.white, { size: 9 });
    ctx.addText(s, { x: 296, y, w: 310, h: 24, text: note, fontSize: 12.5, color: "#b8cbd2", typeface: TYPE.body, valign: "mid" });
  });
  ctx.addShape(s, { x: 60, y: 604, w: 552, h: 1, fill: C.lineDark, line: ctx.line("#00000000", 0) });
  label(ctx, s, "ASK · BEST UNICORN + BEST AMD-HOSTED GEMMA", 60, 624, 440, C.orange, { size: 10.5 });
  ctx.addText(s, { x: 60, y: 652, w: 500, h: 20, text: "proteinloop.dev-vb.lat  ·  github.com/Anarpego/ProteinLoop", fontSize: 11.5, bold: true, color: C.white, typeface: TYPE.body });
  return s;
}`
];

for (const [index, source] of slides.entries()) {
  await fs.writeFile(path.join(slidesDir, `slide-${String(index + 1).padStart(2, "0")}.mjs`), source);
}

console.log(JSON.stringify({ workspace, slidesDir, slideCount: slides.length }, null, 2));
