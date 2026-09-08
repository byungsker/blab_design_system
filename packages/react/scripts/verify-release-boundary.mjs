import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";
const result = spawnSync(npmCommand, ["publish", "--dry-run"], {
  cwd: packageRoot,
  encoding: "utf8",
});
const output = `${result.stdout ?? ""}\n${result.stderr ?? ""}`;

if (result.status === 0) {
  throw new Error("The private package must reject npm publish --dry-run");
}

if (!output.includes("Public publishing is disabled")) {
  throw new Error("The publish guard did not run before npm publish --dry-run");
}

console.log("Publish guard rejected npm publish --dry-run");
