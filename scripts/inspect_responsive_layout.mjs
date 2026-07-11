import fs from "node:fs/promises";

const endpoint = process.argv[2] ?? "http://127.0.0.1:9222/json";
const emulatedWidth = Number(process.argv[3] ?? 390);
const emulatedHeight = Number(process.argv[4] ?? 844);
const screenshotPath = process.argv[5];
const openAdvanced = process.argv.includes("--open-advanced");

const targets = await fetch(endpoint).then((response) => {
  if (!response.ok) throw new Error(`DevTools target request failed: ${response.status}`);
  return response.json();
});

const page = targets.find((target) => target.type === "page");
if (!page?.webSocketDebuggerUrl) throw new Error("No debuggable page target found");

const socket = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

let requestId = 0;
const pending = new Map();

socket.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (!message.id || !pending.has(message.id)) return;
  const { resolve, reject } = pending.get(message.id);
  pending.delete(message.id);
  if (message.error) reject(new Error(message.error.message));
  else resolve(message.result);
});

function command(method, params = {}) {
  const id = ++requestId;
  socket.send(JSON.stringify({ id, method, params }));
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
}

await command("Runtime.enable");
await command("Emulation.setDeviceMetricsOverride", {
  width: emulatedWidth,
  height: emulatedHeight,
  deviceScaleFactor: 1,
  mobile: true,
});
if (openAdvanced) {
  await command("Runtime.evaluate", {
    expression: `document.querySelector("#advanced-evidence")?.setAttribute("open", "")`,
  });
}
const result = await command("Runtime.evaluate", {
  expression: `(() => {
    const viewportWidth = document.documentElement.clientWidth;
    const inspect = (selector) => {
      const element = document.querySelector(selector);
      if (!element) return null;
      const rect = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      return {
        selector,
        left: Math.round(rect.left),
        right: Math.round(rect.right),
        width: Math.round(rect.width),
        scrollWidth: element.scrollWidth,
        minWidth: style.minWidth,
        maxWidth: style.maxWidth,
        overflowX: style.overflowX,
        display: style.display
      };
    };
    const isInsideHorizontalScroller = (element) => {
      let parent = element.parentElement;
      while (parent && parent !== document.body) {
        const style = getComputedStyle(parent);
        if (
          (style.overflowX === "auto" || style.overflowX === "scroll") &&
          parent.scrollWidth > parent.clientWidth + 1
        ) return true;
        parent = parent.parentElement;
      }
      return false;
    };
    const overflowing = [...document.querySelectorAll("body *")]
      .map((element) => {
        const rect = element.getBoundingClientRect();
        return {
          selector: element.id ? "#" + element.id : element.className && typeof element.className === "string" ? "." + element.className.trim().split(/\\s+/).join(".") : element.tagName.toLowerCase(),
          left: Math.round(rect.left),
          right: Math.round(rect.right),
          width: Math.round(rect.width),
          scrollWidth: element.scrollWidth,
          text: (element.textContent || "").trim().replace(/\\s+/g, " ").slice(0, 80)
        };
      })
      .filter((entry) => entry.left < -1 || entry.right > viewportWidth + 1)
      .sort((a, b) => b.right - a.right)
      .slice(0, 30);
    const uncontainedOverflow = [...document.querySelectorAll("body *")]
      .filter((element) => {
        const rect = element.getBoundingClientRect();
        return (
          (rect.left < -1 || rect.right > viewportWidth + 1) &&
          !isInsideHorizontalScroller(element)
        );
      })
      .map((element) => {
        const rect = element.getBoundingClientRect();
        return {
          selector: element.id ? "#" + element.id : element.className && typeof element.className === "string" ? "." + element.className.trim().split(/\\s+/).join(".") : element.tagName.toLowerCase(),
          left: Math.round(rect.left),
          right: Math.round(rect.right),
          width: Math.round(rect.width)
        };
      })
      .sort((a, b) => b.right - a.right)
      .slice(0, 30);

    return {
      url: location.href,
      innerWidth,
      viewportWidth,
      documentScrollWidth: document.documentElement.scrollWidth,
      bodyScrollWidth: document.body.scrollWidth,
      keyLayouts: [
        "main",
        "main > section",
        "main > section > header",
        "#protein-loop-story",
        "#judge-proof-ribbon",
        "#off-grid-continuity",
        "#operator-system-scene",
        "#advanced-evidence",
        ".advanced-evidence__content",
        "#advanced-closed-loop-state",
        ".advanced-state__commands"
      ].map(inspect),
      uncontainedOverflow,
      overflowing
    };
  })()`,
  returnByValue: true,
});

if (screenshotPath) {
  const screenshot = await command("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: false,
  });
  await fs.writeFile(screenshotPath, Buffer.from(screenshot.data, "base64"));
}

const report = result.result.value;
console.log(JSON.stringify(report, null, 2));
if (
  report.documentScrollWidth > report.viewportWidth + 1 ||
  report.bodyScrollWidth > report.viewportWidth + 1 ||
  report.uncontainedOverflow.length > 0
) {
  process.exitCode = 1;
}
socket.close();
