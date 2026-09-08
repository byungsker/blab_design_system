import { createRoot } from "react-dom/client";

import { BLabParityFixture } from "../src/fixture";

const theme = new URLSearchParams(window.location.search).get("theme") === "light" ? "light" : "dark";
document.body.dataset.blabTheme = theme;
document.body.style.background = "var(--blab-surface-scaffold)";
document.body.style.color = "var(--blab-text-primary)";
document.body.style.fontFamily = "var(--blab-font-body)";

const root = document.getElementById("root");
if (!root) {
  throw new Error("Fixture root is missing");
}

createRoot(root).render(<BLabParityFixture theme={theme} />);
