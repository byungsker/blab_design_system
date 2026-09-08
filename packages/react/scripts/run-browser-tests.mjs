import { createServer } from "node:net";
import { spawn } from "node:child_process";

const findAvailablePort = () => new Promise((resolve, reject) => {
  const server = createServer();
  server.once("error", reject);
  server.listen(0, "127.0.0.1", () => {
    const address = server.address();
    if (!address || typeof address === "string") {
      server.close();
      reject(new Error("Could not determine an available loopback port"));
      return;
    }

    const port = address.port;
    server.close((error) => error ? reject(error) : resolve(port));
  });
});

const port = process.env.PLAYWRIGHT_PORT ?? String(await findAvailablePort());
const npmCommand = process.platform === "win32" ? "npx.cmd" : "npx";
const child = spawn(npmCommand, ["playwright", "test", "--project=chromium", ...process.argv.slice(2)], {
  env: { ...process.env, PLAYWRIGHT_PORT: port },
  stdio: "inherit",
});

child.on("error", (error) => {
  console.error(error);
  process.exitCode = 1;
});

child.on("exit", (code, signal) => {
  process.exitCode = code ?? (signal ? 1 : 0);
});
