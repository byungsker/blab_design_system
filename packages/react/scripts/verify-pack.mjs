import { execFileSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";

const packageRoot = dirname(fileURLToPath(import.meta.url)).replace(/\/scripts$/, "");
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

  const api = await import(pathToFileURL(join(installedRoot, "dist/index.js")).href);
  for (const name of ["BLabButton", "BLabCard", "BLabTextField", "BLabKeyboardAccessoryBar", "BLabTheme", "BLabColors"]) {
    if (!(name in api)) {
      throw new Error(`Packed public export missing: ${name}`);
    }
  }

  console.log("Packed consumer import passed");
} finally {
  rmSync(consumerRoot, { recursive: true, force: true });
  rmSync(packageFile, { force: true });
}
