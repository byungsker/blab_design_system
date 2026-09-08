import { createServer } from "node:http";
import { createReadStream, statSync } from "node:fs";
import { extname, join, relative, resolve } from "node:path";

const port = Number(process.argv[2] ?? 4173);
const root = resolve(process.cwd());
const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
};

const isWithinRoot = (filePath) => {
  const relativePath = relative(root, filePath);
  return relativePath === "" || (!relativePath.startsWith("..") && !relativePath.includes(".."));
};

const server = createServer((request, response) => {
  try {
    const requestPath = decodeURIComponent(new URL(request.url ?? "/", "http://127.0.0.1").pathname);
    let filePath = resolve(root, `.${requestPath}`);

    if (!isWithinRoot(filePath)) {
      response.writeHead(403);
      response.end();
      return;
    }

    if (statSync(filePath).isDirectory()) {
      filePath = join(filePath, "index.html");
    }

    if (!isWithinRoot(filePath)) {
      response.writeHead(403);
      response.end();
      return;
    }

    response.writeHead(200, {
      "Content-Type": contentTypes[extname(filePath)] ?? "application/octet-stream",
    });
    createReadStream(filePath).on("error", () => {
      if (!response.headersSent) {
        response.writeHead(404);
      }
      response.end();
    }).pipe(response);
  } catch {
    response.writeHead(404);
    response.end();
  }
});

server.listen(port, "127.0.0.1");
