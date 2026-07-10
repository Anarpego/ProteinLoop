import fs from "node:fs/promises";
import path from "node:path";

const root = path.resolve(".");
const workspace = path.join(root, "outputs/manual-proteinloop/presentations/submission-deck");
const slidesDir = path.join(workspace, "slides");
const evidence = {
  python_tests: 155,
  phoenix_tests: 101,
  reward_delta: 463,
  collapse_avoidance: "100%",
};

await fs.mkdir(slidesDir, { recursive: true });
await fs.writeFile(path.join(workspace, "data.json"), `${JSON.stringify(evidence, null, 2)}\n`);
await fs.writeFile(
  path.join(workspace, "profile-plan.txt"),
  [
    "task mode: create",
    "primary deck-profile: engineering-platform",
    "secondary gates: startup pitch, food security, hackathon submission",
    "proof objects: system map, verifier pipeline, demo evidence, local Gemma runtime",
    "source assets: submission/slides.md, submission/lablab-submission.md, submission/cover.svg",
    "QA gates: readable labels, explicit architecture, metrics tied to system, physical DECT claims separated from sample telemetry",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "source-notes.txt"),
  [
    "ProteinLoop deck generated from repo-local submission sources.",
    `Test counts: make test (${evidence.python_tests}) and app mix test (${evidence.phoenix_tests}), verified July 10, 2026.`,
    "No third-party logos or identity assets are embedded.",
    "Gemma/llama.cpp/Metal are named as proven runtime references; ROCm/vLLM is labeled optional.",
    "Physical hardware proof: nRF9151 FT 1051223739 and PT 1051239227 show matching DECT NR+ sequences in both directions.",
    "",
  ].join("\n"),
);
await fs.writeFile(
  path.join(workspace, "claim-spine.txt"),
  [
    "slide 1: ProteinLoop closes the food-protein cycle through a verifier-gated agentic loop.",
    "slide 2: Aquaponics does not solve resilient protein production by itself.",
    "slide 3: The biological loop maps to a coordinated actor system.",
    "slide 4: Deterministic physics, not the model, controls every mutation.",
    `slide 5: ${evidence.python_tests} Python and ${evidence.phoenix_tests} Phoenix tests plus RLVR evidence make the demo executable.`,
    "slide 6: The simulator is both anomaly forecaster and RLVR verifier.",
    "slide 7: Real Sagents/Horde evidence proves state-preserving failover; two physical nRF9151 DKs prove bidirectional DECT NR+.",
    "slide 8: Spanish HITL is resumable control flow with approve, edit, and reject decisions.",
    "slide 9: Real Sagents and local Gemma 4 E2B run through the same portable endpoint contract.",
    "slide 10: The startup ask is backed by code, Docker, evidence, and a platform path.",
    "",
  ].join("\n"),
);

const common = `
export const colors = {
  ink: "#0f172a",
  muted: "#475569",
  bg: "#f8fafc",
  panel: "#ffffff",
  teal: "#0f766e",
  tealSoft: "#ccfbf1",
  blue: "#0369a1",
  blueSoft: "#e0f2fe",
  green: "#15803d",
  greenSoft: "#dcfce7",
  amber: "#b45309",
  amberSoft: "#fef3c7",
  red: "#b91c1c",
  redSoft: "#fee2e2",
  slate: "#334155"
};

export function slideBase(presentation, ctx, section = "") {
  const slide = presentation.slides.add();
  ctx.addShape(slide, { x: 0, y: 0, w: ctx.W, h: ctx.H, fill: colors.bg });
  ctx.addShape(slide, { x: 0, y: 0, w: ctx.W, h: 18, fill: colors.teal });
  ctx.addText(slide, { x: 54, y: 34, w: 260, h: 28, text: "ProteinLoop", fontSize: 18, bold: true, color: colors.teal });
  if (section) ctx.addText(slide, { x: 1010, y: 34, w: 210, h: 24, text: section, fontSize: 13, color: colors.muted, align: "right" });
  return slide;
}

export function h1(ctx, slide, text, y = 70) {
  ctx.addText(slide, { x: 54, y, w: 920, h: 104, text, fontSize: 34, bold: true, color: colors.ink, typeface: ctx.fonts.title });
}

export function sub(ctx, slide, text, y = 176) {
  ctx.addText(slide, { x: 58, y, w: 820, h: 48, text, fontSize: 16, color: colors.muted });
}

export function box(ctx, slide, { x, y, w, h, title, body, fill = colors.panel, line = colors.teal, titleColor = colors.ink }) {
  ctx.addShape(slide, { x, y, w, h, fill, line: ctx.line(line, 2) });
  ctx.addText(slide, { x: x + 18, y: y + 14, w: w - 36, h: 30, text: title, fontSize: 18, bold: true, color: titleColor });
  if (body) ctx.addText(slide, { x: x + 18, y: y + 50, w: w - 36, h: h - 68, text: body, fontSize: 12, color: colors.slate });
}

export function metric(ctx, slide, { x, y, label, value, note, fill = colors.blueSoft }) {
  ctx.addShape(slide, { x, y, w: 220, h: 112, fill, line: ctx.line("#00000000", 0) });
  ctx.addText(slide, { x: x + 16, y: y + 14, w: 188, h: 22, text: label, fontSize: 12, color: colors.muted });
  ctx.addText(slide, { x: x + 16, y: y + 38, w: 188, h: 38, text: value, fontSize: 28, bold: true, color: colors.ink });
  ctx.addText(slide, { x: x + 16, y: y + 78, w: 188, h: 22, text: note, fontSize: 11, color: colors.muted });
}

export function arrowText(ctx, slide, x, y, text = "->") {
  ctx.addText(slide, { x, y, w: 48, h: 28, text, fontSize: 22, bold: true, color: colors.teal, align: "center" });
}

export function footer(ctx, slide, num) {
  ctx.addText(slide, { x: 54, y: 682, w: 760, h: 18, text: "Deterministic verifier gates every model or producer action before simulator mutation.", fontSize: 10, color: colors.muted });
  ctx.addText(slide, { x: 1160, y: 682, w: 60, h: 18, text: String(num).padStart(2, "0"), fontSize: 10, color: colors.muted, align: "right" });
}
`;

await fs.writeFile(path.join(slidesDir, "common.mjs"), common);

const slides = [
  `import { colors, slideBase, h1, sub, metric, footer } from "./common.mjs";
export default async function slide01(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Unicorn Track");
  ctx.addShape(s, { x: 54, y: 112, w: 1172, h: 452, fill: "#0b1220" });
  ctx.addText(s, { x: 98, y: 154, w: 760, h: 88, text: "ProteinLoop", fontSize: 60, bold: true, color: "#ffffff", typeface: ctx.fonts.title });
  ctx.addText(s, { x: 104, y: 252, w: 680, h: 52, text: "An agentic loop that closes the protein cycle.", fontSize: 26, color: "#ccfbf1" });
  metric(ctx, s, { x: 104, y: 360, label: "core claim", value: "Verifier", note: "physics before mutation", fill: colors.tealSoft });
  metric(ctx, s, { x: 352, y: 360, label: "demo proof", value: "Recovery", note: "collapse avoided", fill: colors.greenSoft });
  metric(ctx, s, { x: 600, y: 360, label: "model proof", value: "E2B", note: "llama.cpp + Metal", fill: colors.amberSoft });
  ctx.addText(s, { x: 934, y: 166, w: 210, h: 250, text: "fish\\nprawns\\nduckweed\\nplants\\neggs", fontSize: 28, bold: true, color: "#ffffff", align: "center", valign: "mid" });
  footer(ctx, s, 1);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, footer } from "./common.mjs";
export default async function slide02(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Problem");
  h1(ctx, s, "Aquaponics is incomplete when protein is the real need");
  sub(ctx, s, "Vegetables are useful, but rural families need resilient daily protein and a system they can operate safely.");
  box(ctx, s, { x: 70, y: 238, w: 330, h: 240, title: "Current aquaponics", body: "Often optimized around greens and water loops. Protein production is secondary and fragile.", fill: colors.redSoft, line: colors.red });
  box(ctx, s, { x: 476, y: 238, w: 330, h: 240, title: "Operational barrier", body: "Feed, ammonia, oxygen, nitrate, harvest timing, and mortality cascades interact every day.", fill: colors.amberSoft, line: colors.amber });
  box(ctx, s, { x: 882, y: 238, w: 330, h: 240, title: "ProteinLoop answer", body: "A closed protein cycle controlled by a verifier-gated agentic loop and Spanish producer approvals.", fill: colors.greenSoft, line: colors.green });
  footer(ctx, s, 2);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, arrowText, footer } from "./common.mjs";
export default async function slide03(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Closed loop");
  h1(ctx, s, "The food system is also an actor system");
  sub(ctx, s, "Each organism is a resource participant; the agent loop coordinates the whole protein cycle.");
  box(ctx, s, { x: 90, y: 246, w: 190, h: 104, title: "Duckweed", body: "Fast protein biomass", fill: colors.greenSoft, line: colors.green });
  arrowText(ctx, s, 298, 286);
  box(ctx, s, { x: 360, y: 246, w: 190, h: 104, title: "Fish + prawns", body: "Protein plus nutrients", fill: colors.blueSoft, line: colors.blue });
  arrowText(ctx, s, 568, 286);
  box(ctx, s, { x: 630, y: 246, w: 190, h: 104, title: "Plants", body: "Nitrate uptake", fill: colors.tealSoft, line: colors.teal });
  arrowText(ctx, s, 838, 286);
  box(ctx, s, { x: 900, y: 246, w: 190, h: 104, title: "Chickens", body: "Daily eggs", fill: colors.amberSoft, line: colors.amber });
  box(ctx, s, { x: 360, y: 426, w: 460, h: 112, title: "Agent supervisor", body: "Balances feed, oxygen, water exchange, harvest, and risk across subsystem agents.", fill: "#ffffff", line: colors.teal });
  footer(ctx, s, 3);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, arrowText, footer } from "./common.mjs";
export default async function slide04(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Harness");
  h1(ctx, s, "The simulator is the safety boundary");
  sub(ctx, s, "Models and humans can propose actions, but deterministic physics decides whether state can mutate.");
  box(ctx, s, { x: 80, y: 248, w: 210, h: 136, title: "call_llm", body: "Four Gemma subagents report to a Sagents supervisor.", fill: colors.blueSoft, line: colors.blue });
  arrowText(ctx, s, 312, 296);
  box(ctx, s, { x: 360, y: 248, w: 260, h: 136, title: "verify_ecosystem_safety", body: "Checks feed, oxygen, water exchange, duckweed reserve, and collapse state.", fill: colors.redSoft, line: colors.red });
  arrowText(ctx, s, 642, 296);
  box(ctx, s, { x: 690, y: 248, w: 210, h: 136, title: "execute_tools", body: "Only accepted actions mutate simulator state.", fill: colors.greenSoft, line: colors.green });
  arrowText(ctx, s, 922, 296);
  box(ctx, s, { x: 950, y: 248, w: 230, h: 136, title: "until_tool_success", body: "Stops only on an accepted close_cycle result.", fill: colors.tealSoft, line: colors.teal });
  box(ctx, s, { x: 240, y: 452, w: 760, h: 84, title: "Proof in repo", body: "Unsafe overfeeding is rejected before mutation; accepted recovery appends verifier evidence to the RLVR trace artifact.", fill: "#ffffff", line: colors.slate });
  footer(ctx, s, 4);
  return s;
}`,
  `import { colors, slideBase, h1, sub, metric, box, footer } from "./common.mjs";
export default async function slide05(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Demo evidence");
  h1(ctx, s, "The local demo proves collapse versus recovery");
  sub(ctx, s, "One button runs reset, ammonia spike, unsafe rejection, safe recovery, and trace recording.");
  metric(ctx, s, { x: 92, y: 250, label: "Python tests", value: "${evidence.python_tests}", note: "sim/API/evidence/deploy", fill: colors.blueSoft });
  metric(ctx, s, { x: 350, y: 250, label: "Phoenix tests", value: "${evidence.phoenix_tests}", note: "Sagents + LiveView + HITL", fill: colors.greenSoft });
  metric(ctx, s, { x: 608, y: 250, label: "Reward delta", value: "${evidence.reward_delta}", note: "safety vs naive avg", fill: colors.tealSoft });
  metric(ctx, s, { x: 866, y: 250, label: "Avoidance", value: "${evidence.collapse_avoidance}", note: "baseline collapses recovered", fill: colors.amberSoft });
  box(ctx, s, { x: 160, y: 430, w: 860, h: 92, title: "Judge path", body: "Run demo cascade -> inspect RLVR evidence -> run four real Sagents/Gemma agents -> verify close_cycle.", fill: "#ffffff", line: colors.teal });
  footer(ctx, s, 5);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, metric, footer } from "./common.mjs";
export default async function slide06(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Prediction");
  h1(ctx, s, "RLVR and anomaly forecasting turn the sim into an evaluator");
  sub(ctx, s, "The same deterministic physics scores policies and forecasts near-term ammonia/oxygen risk without mutating live state.");
  box(ctx, s, { x: 84, y: 238, w: 330, h: 250, title: "RLVR verifier", body: "Naive and safety policies run across fixed scenarios. Reward combines survival, biomass, water quality, and mortality.", fill: colors.tealSoft, line: colors.teal });
  box(ctx, s, { x: 476, y: 238, w: 330, h: 250, title: "Anomaly forecast", body: "GET /forecast/anomaly projects routine operation and reports stable, warning, or critical risk.", fill: colors.blueSoft, line: colors.blue });
  box(ctx, s, { x: 868, y: 238, w: 330, h: 250, title: "Operator action", body: "Forecast recommendations trigger safer feed, aeration, and verified water-exchange behavior before mortality.", fill: colors.greenSoft, line: colors.green });
  footer(ctx, s, 6);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, arrowText, footer } from "./common.mjs";
export default async function slide07(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Self-healing");
  h1(ctx, s, "Real failover and real field radio have executable proof");
  sub(ctx, s, "Horde preserves managed agent state across owner loss; two physical nRF9151 DKs prove the DECT NR+ link.");
  box(ctx, s, { x: 104, y: 240, w: 270, h: 122, title: "proteinloop_web@web", body: "Initial owner persists the completed Gemma probe.", fill: colors.redSoft, line: colors.red });
  arrowText(ctx, s, 392, 286, "stop");
  box(ctx, s, { x: 468, y: 240, w: 270, h: 122, title: "Horde 0.10.0", body: "Participation membership transfers managed ownership.", fill: colors.tealSoft, line: colors.teal });
  arrowText(ctx, s, 756, 286);
  box(ctx, s, { x: 832, y: 240, w: 300, h: 122, title: "proteinloop_peer@peer", body: "Survivor restores the same Sagents AgentServer state.", fill: colors.greenSoft, line: colors.green });
  box(ctx, s, { x: 104, y: 424, w: 520, h: 116, title: "Horde proof", body: "Identity, state token, and fingerprint stay unchanged; restore_count increases on the peer and both nodes rejoin.", fill: "#ffffff", line: colors.teal });
  box(ctx, s, { x: 656, y: 424, w: 520, h: 116, title: "Physical DECT NR+ proof", body: "FT 1051223739 and PT 1051239227 show matching sequences in both directions. Read-only capture; no flash/reset; simulated: false.", fill: colors.greenSoft, line: colors.green });
  footer(ctx, s, 7);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, footer } from "./common.mjs";
export default async function slide08(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Producer UX");
  h1(ctx, s, "Spanish HITL is control flow, not decoration");
  sub(ctx, s, "Risky water and harvest actions pause for the producer, while offline rules keep emergency guidance available.");
  box(ctx, s, { x: 90, y: 246, w: 330, h: 230, title: "Approve", body: "Agent.resume executes the interrupted Sagents tool exactly once after producer approval.", fill: colors.greenSoft, line: colors.green });
  box(ctx, s, { x: 474, y: 246, w: 330, h: 230, title: "Edit / Reject", body: "Solo mitad is re-verified; rejection resumes with zero simulator mutation.", fill: colors.amberSoft, line: colors.amber });
  box(ctx, s, { x: 858, y: 246, w: 330, h: 230, title: "Offline fallback", body: "Respaldo offline gives deterministic Spanish emergency instructions without model or cloud access.", fill: colors.blueSoft, line: colors.blue });
  footer(ctx, s, 8);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, arrowText, footer } from "./common.mjs";
export default async function slide09(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Gemma runtime");
  h1(ctx, s, "Local Gemma 4 already powers the real Sagents runtime");
  sub(ctx, s, "E2B proves the loop offline through the same portable GEMMA_ENDPOINT contract.");
  box(ctx, s, { x: 80, y: 256, w: 250, h: 142, title: "Sagents 0.9.0", body: "Five agents, custom safety mode, until_tool_success, and resumable HITL.", fill: colors.tealSoft, line: colors.teal });
  arrowText(ctx, s, 350, 306);
  box(ctx, s, { x: 420, y: 260, w: 280, h: 128, title: "GEMMA_ENDPOINT", body: "/v1/models and /v1/chat/completions; no code change for Fireworks or vLLM.", fill: colors.blueSoft, line: colors.blue });
  arrowText(ctx, s, 720, 306);
  box(ctx, s, { x: 790, y: 260, w: 330, h: 128, title: "llama.cpp + Metal", body: "The smallest Gemma 4 instruction model runs locally and offline after installation.", fill: colors.amberSoft, line: colors.amber });
  box(ctx, s, { x: 220, y: 454, w: 780, h: 102, title: "Verifier remains in front", body: "Local Gemma proposals cannot mutate state without passing deterministic simulator safety rules.", fill: "#ffffff", line: colors.teal });
  footer(ctx, s, 9);
  return s;
}`,
  `import { colors, slideBase, h1, sub, box, metric, footer } from "./common.mjs";
export default async function slide10(presentation, ctx) {
  const s = slideBase(presentation, ctx, "Submission ask");
  h1(ctx, s, "ProteinLoop is a startup pitch with executable proof");
  sub(ctx, s, "A food-security product built as a verifier-gated, human-aware, fault-tolerant agentic system.");
  box(ctx, s, { x: 78, y: 238, w: 345, h: 230, title: "Market wedge", body: "Rural families and cooperatives that need low-cost, resilient protein production.", fill: colors.greenSoft, line: colors.green });
  box(ctx, s, { x: 468, y: 238, w: 345, h: 230, title: "Technical moat", body: "Real Sagents/Horde failover, physical DECT NR+ proof, physics verifier, RLVR scoring, resumable HITL, and offline Gemma 4.", fill: colors.tealSoft, line: colors.teal });
  box(ctx, s, { x: 858, y: 238, w: 345, h: 230, title: "What judges can run", body: "Docker app, local Gemma E2B, five-agent loop, producer approval, and validated software plus hardware evidence packets.", fill: colors.blueSoft, line: colors.blue });
  ctx.addText(s, { x: 162, y: 552, w: 900, h: 44, text: "Ask: Best Unicorn", fontSize: 30, bold: true, color: colors.ink, align: "center" });
  footer(ctx, s, 10);
  return s;
}`
];

for (const [index, source] of slides.entries()) {
  await fs.writeFile(path.join(slidesDir, `slide-${String(index + 1).padStart(2, "0")}.mjs`), source);
}

console.log(JSON.stringify({ workspace, slidesDir, slideCount: slides.length }, null, 2));
