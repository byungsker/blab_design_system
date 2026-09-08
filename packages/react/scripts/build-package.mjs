import { execFileSync } from "node:child_process";
import { rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";

rmSync(join(packageRoot, "dist"), { recursive: true, force: true });
execFileSync(npmCommand, ["run", "build"], { cwd: packageRoot, stdio: "inherit" });
