import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";
const nextCommand = process.platform === "win32" ? "next.cmd" : "next";
const packOutput = execFileSync(npmCommand, ["pack", "--silent"], {
  cwd: packageRoot,
  encoding: "utf8",
});
const packageFileName = packOutput
  .split(/\r?\n/)
  .map((line) => line.trim())
  .find((line) => line.endsWith(".tgz"));

if (!packageFileName) {
  throw new Error("npm pack did not return a tarball filename");
}

const packageFile = join(packageRoot, packageFileName);
const consumerRoot = mkdtempSync(join(tmpdir(), "blab-next-consumer-"));

try {
  writeFileSync(join(consumerRoot, "package.json"), JSON.stringify({
    name: "blab-next-consumer",
    private: true,
    scripts: { build: "next build" },
  }, null, 2));
  writeFileSync(join(consumerRoot, "next.config.mjs"), "export default {};\n");
  mkdirSync(join(consumerRoot, "app"));
  writeFileSync(join(consumerRoot, "app", "layout.tsx"), `import "@byungsker/blab-design-system/styles.css";
import type { ReactNode } from "react";

export default function RootLayout({ children }: { children: ReactNode }) {
  return <html lang="en"><body>{children}</body></html>;
}
`);
  writeFileSync(join(consumerRoot, "app", "page.tsx"), `"use client";

import { BLabTextField } from "@byungsker/blab-design-system";

export default function Page() {
  return <BLabTextField label="Title" value="" onChange={() => undefined} />;
}
`);
  execFileSync(
    npmCommand,
    [
      "install",
      "--prefix",
      consumerRoot,
      "--no-save",
      "--no-audit",
      packageFile,
      "next@15.5.25",
      "react@19.2.3",
      "react-dom@19.2.3",
      "typescript@5.9.3",
      "@types/node@24.0.0",
      "@types/react@19.0.0",
      "@types/react-dom@19.0.0",
    ],
    { cwd: packageRoot, stdio: "inherit" },
  );
  execFileSync(
    join(consumerRoot, "node_modules", ".bin", nextCommand),
    ["build"],
    { cwd: consumerRoot, env: { ...process.env, CI: "1" }, stdio: "inherit" },
  );
  console.log("Packed Next.js App Router consumer build passed");
} finally {
  rmSync(consumerRoot, { recursive: true, force: true });
  rmSync(packageFile, { force: true });
}
