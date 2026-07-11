import fs from "node:fs/promises";
import path from "node:path";

const root = path.resolve(".");
const workspace = path.join(root, "outputs/manual-proteinloop/presentations/submission-deck");
const slidesDir = path.join(workspace, "slides");
const assetDir = path.join(root, "submission/deck-assets");

const data = {
  pythonTests: 184,
  phoenixTests: 132,
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
    "required proof objects: real product UI, verifier workflow, executable metrics, off-grid architecture, producer control, runtime boundary",
    "source assets: submission/cover.png, operator-overview.png, agent-recovery.png, repository evidence artifacts",
    "brand constraints: no invented AMD or Nordic logos; use product typography and verified UI only",
    "QA gates: 16:9, readable at thumbnail scale, attached connector direction, proven-versus-next labels, no unmeasured claims",
    "known boundary: current public inference is CPU llama.cpp; ROCm/vLLM is a portable future path",
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
    `Executable evidence verified July 11, 2026: ${data.pythonTests} Python tests and ${data.phoenixTests} Phoenix tests, zero failures.`,
    "Physical evidence: two nRF9151 boards exchanged matching bidirectional DECT NR+ sequence 100.",
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
    "Avoid: decorative card grids, vague AI-layer labels, current AMD GPU claims, unmeasured solar or sensor claims.",
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
    "07 DECT NR+ keeps the field hop local; edge compute keeps decision-making local.",
    "08 The producer retains control of risky or irreversible actions.",
    "09 One endpoint boundary separates proven CPU inference from the portable AMD path.",
    "10 The market wedge is resilient protein production where connectivity cannot be assumed.",
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

export function node(ctx, s, { x, y, w, h, label, detail, fill = C.white, line = C.teal, number }) {
  ctx.addShape(s, { x, y, w, h, fill, line: ctx.line(line, 2) });
  if (number) {
    ctx.addShape(s, { x: x + 14, y: y + 14, w: 32, h: 32, fill: line, line: ctx.line("#00000000", 0), geometry: "ellipse" });
    ctx.addText(s, { x: x + 14, y: y + 20, w: 32, h: 18, text: number, fontSize: 12, bold: true, color: C.white, align: "center" });
  }
  ctx.addText(s, { x: x + (number ? 58 : 18), y: y + 14, w: w - (number ? 74 : 36), h: 26, text: label, fontSize: 17, bold: true, color: C.ink });
  if (detail) ctx.addText(s, { x: x + 18, y: y + 48, w: w - 36, h: h - 60, text: detail, fontSize: 11, color: C.body });
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
  body(ctx, s, "The deployed operator view connects animal behavior, plain-language chemistry, biomass, and action in one scene.", 46, 120, 970, 44, C.body, 15);
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
  node(ctx, s, { x: 42, y: 218, w: 212, h: 138, label: "Gemma specialists", detail: "Fish, prawns, plants, and feed-loop briefs.", fill: C.mint, line: C.teal, number: "1" });
  connector(ctx, s, 260, 274, 72, C.teal);
  node(ctx, s, { x: 338, y: 218, w: 190, h: 138, label: "Supervisor", detail: "One bounded proposal.", fill: C.blueSoft, line: C.blue, number: "2" });
  connector(ctx, s, 536, 274, 72, C.blue);
  node(ctx, s, { x: 612, y: 198, w: 244, h: 178, label: "Deterministic verifier", detail: "Checks chemistry, feed, water exchange, reserve, and collapse rules.", fill: C.orangeSoft, line: C.orange, number: "3" });
  connector(ctx, s, 864, 274, 72, C.orange);
  node(ctx, s, { x: 942, y: 218, w: 246, h: 138, label: "Simulator mutation", detail: "Only admitted actions change state.", fill: C.greenSoft, line: C.green, number: "4" });
  ctx.addShape(s, { x: 612, y: 430, w: 576, h: 94, fill: C.redSoft, line: ctx.line(C.red, 2) });
  ctx.addText(s, { x: 638, y: 452, w: 136, h: 24, text: "UNSAFE", fontSize: 14, bold: true, color: C.red });
  ctx.addText(s, { x: 782, y: 444, w: 378, h: 42, text: "Rejected before mutation and written to the RLVR trace.", fontSize: 16, color: C.ink });
  ctx.addShape(s, { x: 730, y: 376, w: 3, h: 54, fill: C.red, line: ctx.line("#00000000", 0) });
  ctx.addText(s, { x: 714, y: 398, w: 34, h: 24, text: "v", fontSize: 18, bold: true, color: C.red, align: "center" });
  footer(ctx, s, "verify_ecosystem_safety is the only authority allowed to admit simulator mutation.");
  return s;
}`,

  `import { C, base, title, metric, footer } from "./common.mjs";
export default async function slide06(presentation, ctx) {
  const s = base(presentation, ctx, "Executable evidence", true);
  title(ctx, s, "Safety is demonstrated, not narrated.", { y: 60, h: 76, size: 39, color: C.white });
  ctx.addText(s, { x: 46, y: 140, w: 790, h: 44, text: "The simulator is simultaneously the product demo, the policy evaluator, and the RLVR source of truth.", fontSize: 16, color: "#c2d6dd" });
  metric(ctx, s, { x: 52, y: 224, value: "180", label: "Python tests", note: "simulator, verifier, API, evidence", color: "#63c7f2" });
  metric(ctx, s, { x: 342, y: 224, value: "129", label: "Phoenix tests", note: "Sagents, LiveView, producer control", color: "#76d9ad" });
  metric(ctx, s, { x: 632, y: 224, value: "+463", label: "reward delta", note: "verified policy versus naive average", color: "#f2c94c" });
  metric(ctx, s, { x: 922, y: 224, value: "100%", label: "collapse avoidance", note: "fixed baseline scenarios recovered", color: "#ff8e5c" });
  ctx.addShape(s, { x: 52, y: 446, w: 1130, h: 112, fill: "#173f50", line: ctx.line("#315b6b", 1) });
  ctx.addText(s, { x: 82, y: 468, w: 260, h: 24, text: "ONE-CLICK JUDGE PROOF", fontSize: 12, bold: true, color: "#8ee7d5" });
  ctx.addText(s, { x: 82, y: 506, w: 1030, h: 30, text: "Inject emergency  ->  block unsafe proposal  ->  admit safe recovery  ->  inspect measured chemistry", fontSize: 18, bold: true, color: C.white });
  footer(ctx, s, "Verified July 11, 2026: 184 Python and 132 Phoenix tests, zero failures.", true);
  return s;
}`,

  `import { C, base, title, body, pill, footer } from "./common.mjs";
export default async function slide07(presentation, ctx) {
  const s = base(presentation, ctx, "Off-grid architecture");
  title(ctx, s, "Keep the food-control loop local.", { y: 54, h: 72, size: 38 });
  body(ctx, s, "Three continuity layers separate transport, intelligence, and power claims.", 46, 124, 820, 38, C.body, 15);
  const xs = [74, 330, 588, 846, 1076];
  const labels = [
    ["Tank probes", "next integration", C.orangeSoft, C.orange],
    ["nRF9151 PT", "physical tank radio", C.blueSoft, C.blue],
    ["DECT NR+", "no Wi-Fi / SIM / cloud", C.greenSoft, C.green],
    ["nRF9151 FT", "physical gateway radio", C.blueSoft, C.blue],
    ["Edge computer", "Gemma + verifier", C.mint, C.teal]
  ];
  labels.forEach(([label, note, fill, line], i) => {
    const w = i === 4 ? 158 : 174;
    ctx.addShape(s, { x: xs[i], y: 240, w, h: 106, fill, line: ctx.line(line, 2) });
    ctx.addText(s, { x: xs[i] + 14, y: 258, w: w - 28, h: 26, text: label, fontSize: 16, bold: true, color: C.ink, align: "center" });
    ctx.addText(s, { x: xs[i] + 12, y: 294, w: w - 24, h: 36, text: note, fontSize: 10, color: C.body, align: "center" });
    if (i < 4) ctx.addText(s, { x: xs[i] + w + 10, y: 277, w: 50, h: 28, text: ">", fontSize: 22, bold: true, color: i === 0 ? C.orange : C.teal, align: "center" });
  });
  pill(ctx, s, "NEXT", 108, 204, 100, C.orangeSoft, C.orange);
  pill(ctx, s, "PROVEN", 366, 204, 110, C.greenSoft, C.green);
  pill(ctx, s, "PROVEN", 622, 204, 110, C.greenSoft, C.green);
  pill(ctx, s, "PROVEN", 880, 204, 110, C.greenSoft, C.green);
  pill(ctx, s, "PROVEN", 1098, 204, 110, C.greenSoft, C.green);
  ctx.addShape(s, { x: 74, y: 418, w: 1106, h: 1, fill: C.line, line: ctx.line("#00000000", 0) });
  const claims = [
    ["NO WI-FI", "DECT NR+ carries the tank-to-gateway hop.", C.blue],
    ["NO CLOUD", "Self-hosted Gemma and deterministic rules remain local.", C.teal],
    ["NO GRID", "Solar + battery is the next measured autonomy proof.", C.orange]
  ];
  claims.forEach(([label, note, color], i) => {
    const x = 84 + i * 386;
    ctx.addText(s, { x, y: 458, w: 150, h: 26, text: label, fontSize: 18, bold: true, color });
    ctx.addText(s, { x, y: 496, w: 326, h: 54, text: note, fontSize: 14, color: C.body });
  });
  footer(ctx, s, "Physical chemistry acquisition and measured solar autonomy are future field proofs, not current claims.");
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
  const s = base(presentation, ctx, "Runtime portability", true);
  title(ctx, s, "One endpoint. Two deployment paths.", { y: 62, h: 74, size: 40, color: C.white });
  body(ctx, s, "Agent and verifier code stay unchanged when the inference host changes.", 48, 136, 740, 38, "#c2d6dd", 16);
  ctx.addText(s, { x: 64, y: 214, w: 300, h: 24, text: "PROVEN NOW", fontSize: 12, bold: true, color: "#76d9ad" });
  ctx.addShape(s, { x: 52, y: 252, w: 336, h: 220, fill: "#173f50", line: ctx.line("#4f7887", 1) });
  ctx.addText(s, { x: 82, y: 278, w: 276, h: 36, text: "CPU edge runtime", fontSize: 25, bold: true, color: C.white });
  ctx.addText(s, { x: 82, y: 330, w: 276, h: 100, text: "Gemma 4 E2B\\nllama.cpp QAT Q4\\nprivate 8 GB host\\nseparate Metal evidence", fontSize: 16, color: "#c2d6dd" });
  ctx.addShape(s, { x: 468, y: 292, w: 330, h: 140, fill: C.blueSoft, line: ctx.line(C.blue, 2) });
  ctx.addText(s, { x: 498, y: 314, w: 270, h: 34, text: "GEMMA_ENDPOINT", fontSize: 22, bold: true, color: C.blue, align: "center" });
  ctx.addText(s, { x: 498, y: 360, w: 270, h: 44, text: "OpenAI-compatible model boundary", fontSize: 14, color: C.ink, align: "center" });
  ctx.addText(s, { x: 408, y: 342, w: 48, h: 28, text: ">", fontSize: 24, bold: true, color: "#76d9ad", align: "center" });
  ctx.addText(s, { x: 812, y: 342, w: 48, h: 28, text: ">", fontSize: 24, bold: true, color: C.orange, align: "center" });
  ctx.addText(s, { x: 884, y: 214, w: 300, h: 24, text: "PORTABLE AMD PATH", fontSize: 12, bold: true, color: "#ffad7c" });
  ctx.addShape(s, { x: 872, y: 252, w: 336, h: 220, fill: "#173f50", line: ctx.line(C.orange, 2) });
  ctx.addText(s, { x: 902, y: 278, w: 276, h: 36, text: "GPU promotion profile", fontSize: 25, bold: true, color: C.white });
  ctx.addText(s, { x: 902, y: 330, w: 276, h: 100, text: "AMD ROCm\\nvLLM serving\\nsame endpoint contract\\nGPU evidence not claimed", fontSize: 16, color: "#c2d6dd" });
  ctx.addText(s, { x: 52, y: 530, w: 1134, h: 42, text: "The deterministic verifier remains authoritative on either host.", fontSize: 22, bold: true, color: "#8ee7d5", align: "center" });
  footer(ctx, s, "Current submission proves CPU llama.cpp and local Metal inference; ROCm/vLLM remains a documented promotion path.", true);
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
  ctx.addText(s, { x: 58, y: 642, w: 500, h: 26, text: "proteinloop.dev-vb.lat  |  Best Unicorn", fontSize: 15, bold: true, color: C.orange });
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
