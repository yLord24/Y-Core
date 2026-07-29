const http = require("http");
const fs = require("fs");
const path = require("path");

const rootIndex = process.argv.indexOf("--root");
const portIndex = process.argv.indexOf("--port");
const root = rootIndex >= 0 ? process.argv[rootIndex + 1] : path.resolve(__dirname, "..");
const port = portIndex >= 0 ? Number(process.argv[portIndex + 1]) : 8124;

const contentTypes = {
  ".lua": "text/plain; charset=utf-8",
  ".luau": "text/plain; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".md": "text/markdown; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
};

function discoverGames() {
  const gamesRoot = path.join(root, "games");
  if (!fs.existsSync(gamesRoot)) {
    return [];
  }

  return fs
    .readdirSync(gamesRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => {
      const gameId = entry.name;
      const gameRoot = path.join(gamesRoot, gameId);
      return {
        id: gameId,
        entryPath: path.join(gameRoot, "init.lua"),
        testPath: path.join(gameRoot, "test.lua"),
      };
    })
    .filter((game) => fs.existsSync(game.entryPath))
    .sort((a, b) => a.id.localeCompare(b.id));
}

function send(res, status, body, type = "text/plain; charset=utf-8") {
  res.writeHead(status, {
    "Content-Type": type,
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "*",
    "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
  });
  res.end(body);
}

const server = http.createServer((req, res) => {
  if (req.method === "OPTIONS") {
    return send(res, 204, "");
  }

  const parsed = new URL(req.url || "/", `http://${req.headers.host || "127.0.0.1"}`);
  const pathname = decodeURIComponent(parsed.pathname || "/");
  console.log(`[YCore Local] ${req.method} ${pathname}`);

  if (req.method !== "GET") {
    return send(res, 405, "Method not allowed");
  }

  const normalized = path.normalize(pathname).replace(/^([/\\])+/, "");
  const filePath = path.resolve(root, normalized || "loader.lua");
  if (!filePath.startsWith(path.resolve(root))) {
    return send(res, 403, "Forbidden");
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      return send(res, 404, `Not found: ${pathname}`);
    }

    const type = contentTypes[path.extname(filePath).toLowerCase()] || "application/octet-stream";
    send(res, 200, data, type);
  });
});

server.listen(port, "127.0.0.1", () => {
  console.log(`[YCore Local] Serving ${root}`);
  console.log(`[YCore Local] Root Loader http://127.0.0.1:${port}/loader.lua`);

  const games = discoverGames();
  if (games.length === 0) {
    console.log("[YCore Local] No local game sources found under /games");
    return;
  }

  for (const game of games) {
    console.log(`[YCore Local] ${game.id} Source http://127.0.0.1:${port}/games/${game.id}/init.lua`);
    if (fs.existsSync(game.testPath)) {
      console.log(`[YCore Local] ${game.id} Test   http://127.0.0.1:${port}/games/${game.id}/test.lua`);
    }
  }
});
