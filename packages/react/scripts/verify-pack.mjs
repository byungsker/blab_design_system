import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";
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
const consumerRoot = mkdtempSync(join(tmpdir(), "blab-package-consumer-"));

try {
  execFileSync(
    npmCommand,
    ["install", "--prefix", consumerRoot, "--no-save", packageFile, "react@19.2.3", "react-dom@19.2.3"],
    { cwd: packageRoot, stdio: "inherit" },
  );

  const installedRoot = join(consumerRoot, "node_modules", "@byungsker", "blab-design-system");
  const packageJson = JSON.parse(readFileSync(join(installedRoot, "package.json"), "utf8"));
  if (packageJson.private !== true || packageJson.license !== "UNLICENSED") {
    throw new Error("Packed package release policy metadata mismatch");
  }
  const entrySource = readFileSync(join(installedRoot, "dist/index.js"), "utf8");
  if (!entrySource.startsWith('"use client";')) {
    throw new Error("Packed public entry is missing the Next.js client boundary");
  }
  for (const component of [
    "blab-bottom-bar",
    "blab-button",
    "blab-card",
    "blab-keyboard-accessory-bar",
    "blab-pressable-wrapper",
    "blab-segmented-control",
    "blab-snackbar",
    "blab-states",
    "blab-tab-bar",
    "blab-text-field",
  ]) {
    const source = readFileSync(join(installedRoot, "dist/components", `${component}.js`), "utf8");
    if (!source.startsWith('"use client";')) {
      throw new Error(`Packed component is missing the Next.js client boundary: ${component}`);
    }
  }

  const consumerScript = [
    'const api = await import("@byungsker/blab-design-system");',
    'for (const name of ["BLabButton", "BLabCard", "BLabTextField", "BLabKeyboardAccessoryBar", "BLabTheme", "BLabColors"]) {',
    '  if (!(name in api)) throw new Error(`Packed public export missing: ${name}`);',
    '}',
    'const cssEntry = await import.meta.resolve("@byungsker/blab-design-system/styles.css");',
    'if (!cssEntry.endsWith("/src/styles.css")) throw new Error(`Unexpected CSS export: ${cssEntry}`);',
  ].join("\n");
  execFileSync(process.execPath, ["--input-type=module", "-e", consumerScript], {
    cwd: consumerRoot,
    stdio: "inherit",
  });

  console.log("Packed consumer import passed");
} finally {
  rmSync(consumerRoot, { recursive: true, force: true });
  rmSync(packageFile, { force: true });
}
