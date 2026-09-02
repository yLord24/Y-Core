const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

// Y Hub dev listener.
// Serves local source files and hosts executor agents on the same localhost port.

//--//Variables
const argumentList = process.argv.slice(2);
const projectRoot = path.resolve(readArgumentValue("--root", path.resolve(__dirname, "../..")));
const port = Number(readArgumentValue("--port", "8124")) || 8124;
const host = readArgumentValue("--host", "127.0.0.1");
const agentRoot = path.join(projectRoot, ".ycore-dev");

const directoryMap = {
	Commands: path.join(agentRoot, "commands"),
	Results: path.join(agentRoot, "results"),
	Logs: path.join(agentRoot, "logs"),
};

const contentTypes = {
	".lua": "text/plain; charset=utf-8",
	".luau": "text/plain; charset=utf-8",
	".json": "application/json; charset=utf-8",
	".md": "text/markdown; charset=utf-8",
	".txt": "text/plain; charset=utf-8",
	".js": "text/plain; charset=utf-8",
};

const activeCommandMap = new Map();
const clientMap = new Map();

//--//Source
function readArgumentValue(argumentName, fallbackValue) {
	const argumentIndex = argumentList.indexOf(argumentName);

	if (argumentIndex < 0 || argumentIndex + 1 >= argumentList.length) {
		return fallbackValue;
	}

	return argumentList[argumentIndex + 1];
}

function nowIso() {
	return new Date().toISOString();
}

function ensureDirectories() {
	for (const directoryPath of Object.values(directoryMap)) {
		fs.mkdirSync(directoryPath, { recursive: true });
	}
}

function resetRunningCommands() {
	const runningCommandList = listFiles(directoryMap.Commands, ".running.json");

	for (const runningCommand of runningCommandList) {
		const restoredName = runningCommand.name.replace(/\.running\.json$/i, ".json");
		const restoredPath = path.join(directoryMap.Commands, restoredName);

		try {
			fs.renameSync(runningCommand.file, restoredPath);
			appendLog(`[restore-running] ${runningCommand.name}`);
		} catch (error) {
			appendLog(`[restore-running-failed] ${runningCommand.name} ${error.message}`);
		}
	}
}

function send(res, status, body, type = "text/plain; charset=utf-8") {
	res.writeHead(status, {
		"Content-Type": type,
		"Access-Control-Allow-Origin": "*",
		"Access-Control-Allow-Methods": "GET, POST, OPTIONS",
		"Access-Control-Allow-Headers": "*",
		"Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
	});
	res.end(body);
}

function sendJson(res, status, value) {
	send(res, status, JSON.stringify(value, null, 2), "application/json; charset=utf-8");
}

function readBody(req, maxBytes = 20 * 1024 * 1024) {
	return new Promise((resolve, reject) => {
		let body = "";

		req.on("data", (chunk) => {
			body += chunk;

			if (body.length > maxBytes) {
				req.destroy();
				reject(new Error("Request body too large"));
			}
		});

		req.on("end", () => resolve(body));
		req.on("error", reject);
	});
}

function appendLog(line) {
	fs.appendFileSync(path.join(directoryMap.Logs, "dev-listener.log"), `${nowIso()} ${line}\n`);
}

function createCommandId(label) {
	const cleanLabel = String(label || "cmd")
		.replace(/[^a-z0-9_-]+/gi, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 42) || "cmd";

	return `${Date.now()}-${cleanLabel}-${crypto.randomBytes(3).toString("hex")}`;
}

function listFiles(directoryPath, suffix) {
	if (!fs.existsSync(directoryPath)) {
		return [];
	}

	return fs
		.readdirSync(directoryPath)
		.filter((name) => name.endsWith(suffix))
		.map((name) => {
			const file = path.join(directoryPath, name);
			return {
				name,
				file,
				stat: fs.statSync(file),
			};
		})
		.sort((left, right) => left.stat.birthtimeMs - right.stat.birthtimeMs || left.name.localeCompare(right.name));
}

function listPendingCommands() {
	return listFiles(directoryMap.Commands, ".json").filter(
		(commandFile) => !commandFile.name.endsWith(".running.json"),
	);
}

function enqueueCommand(code, label, options = {}) {
	if (typeof code !== "string" || !code.trim()) {
		throw new Error("Missing command code");
	}

	const requestedTimeout = Number(options.timeout);
	const timeout = Number.isFinite(requestedTimeout)
		? Math.min(Math.max(requestedTimeout, 5), 600)
		: 120;
	const policy = options.policy === "read_only" ? "read_only" : "standard";
	const targetClient = typeof options.targetClient === "string" && options.targetClient.trim()
		? options.targetClient.trim()
		: null;

	const id = createCommandId(label);
	const command = {
		id,
		label: label || "command",
		code,
		policy,
		targetClient,
		timeout: policy === "read_only" ? Math.min(timeout, 30) : timeout,
		createdAt: nowIso(),
	};

	fs.writeFileSync(path.join(directoryMap.Commands, `${id}.json`), JSON.stringify(command, null, 2), "utf8");
	appendLog(`[enqueue] ${id} ${command.label} target=${targetClient || "any"}`);

	return command;
}

function claimNextCommand(clientName) {
	const commandFileList = listPendingCommands();

	for (const commandFile of commandFileList) {
		let command;

		try {
			command = JSON.parse(fs.readFileSync(commandFile.file, "utf8"));
		} catch (error) {
			const badPath = path.join(directoryMap.Commands, `${commandFile.name}.bad`);
			fs.renameSync(commandFile.file, badPath);
			appendLog(`[bad-command] ${commandFile.name} ${error.message}`);
			continue;
		}

		if (!command || !command.id || typeof command.code !== "string") {
			const badPath = path.join(directoryMap.Commands, `${commandFile.name}.bad`);
			fs.renameSync(commandFile.file, badPath);
			appendLog(`[bad-command] ${commandFile.name} invalid-shape`);
			continue;
		}

		if (command.targetClient && command.targetClient !== clientName) {
			continue;
		}

		const runningPath = path.join(directoryMap.Commands, `${command.id}.running.json`);

		try {
			fs.renameSync(commandFile.file, runningPath);
		} catch {
			continue;
		}

		command.claimedAt = nowIso();
		command.client = clientName || "unknown";
		activeCommandMap.set(command.id, {
			Command: command,
			RunningPath: runningPath,
		});
		appendLog(`[claim] ${command.id} by=${command.client}`);

		return command;
	}

	return null;
}

function writeResult(payload) {
	const id = String(payload && payload.id ? payload.id : createCommandId("anonymous-result"));
	const result = {
		id,
		receivedAt: nowIso(),
		...payload,
	};

	const resultPath = path.join(directoryMap.Results, `${id}.json`);
	const latestPath = path.join(directoryMap.Results, "latest.json");

	fs.writeFileSync(resultPath, JSON.stringify(result, null, 2), "utf8");
	fs.writeFileSync(latestPath, JSON.stringify(result, null, 2), "utf8");

	const activeCommand = activeCommandMap.get(id);

	if (activeCommand) {
		try {
			fs.unlinkSync(activeCommand.RunningPath);
		} catch {
			// The result is still useful even if the running marker is already gone.
		}

		activeCommandMap.delete(id);
	}

	appendLog(`[result] ${id} ok=${Boolean(payload && payload.ok)} ${payload && payload.result ? String(payload.result).slice(0, 240) : ""}`);
	return result;
}

function readAgentSource() {
	const agentPath = path.join(__dirname, "executor-agent.lua");
	let agentSource = fs.readFileSync(agentPath, "utf8");
	const baseUrl = `http://${host}:${port}`;

	agentSource = agentSource.replace(/__YCORE_DEV_BASE_URL__/g, baseUrl);

	return agentSource;
}

function getHealth() {
	const latestPath = path.join(directoryMap.Results, "latest.json");
	let latest = null;

	if (fs.existsSync(latestPath)) {
		try {
			const latestData = JSON.parse(fs.readFileSync(latestPath, "utf8"));
			latest = {
				id: latestData.id,
				ok: latestData.ok,
				label: latestData.label,
				player: latestData.player,
				receivedAt: latestData.receivedAt,
				result: latestData.result,
			};
		} catch {
			latest = {
				error: "latest result could not be parsed",
			};
		}
	}

	return {
		ok: true,
		name: "Y Hub Dev Listener",
		port,
		host,
		root: projectRoot,
		loader: `http://${host}:${port}/loader.lua`,
		agent: `http://${host}:${port}/agent.lua`,
		pending: listPendingCommands().length,
		running: listFiles(directoryMap.Commands, ".running.json").length,
		active: activeCommandMap.size,
		clients: Object.fromEntries(clientMap),
		latest,
	};
}

function serveStatic(pathname, res) {
	const normalizedPath = path.normalize(pathname).replace(/^([/\\])+/, "");
	const selectedPath = normalizedPath || "loader.lua";
	const absoluteFilePath = path.resolve(projectRoot, selectedPath);
	const relativePath = path.relative(projectRoot, absoluteFilePath);

	if (relativePath.startsWith("..") || path.isAbsolute(relativePath)) {
		return sendJson(res, 403, {
			ok: false,
			error: "Forbidden",
		});
	}

	fs.readFile(absoluteFilePath, (error, data) => {
		if (error) {
			return sendJson(res, 404, {
				ok: false,
				error: `Not found: ${pathname}`,
			});
		}

		const contentType = contentTypes[path.extname(absoluteFilePath).toLowerCase()] || "application/octet-stream";
		send(res, 200, data, contentType);
	});
}

async function handleApi(req, res, route, parsedUrl) {
	if (req.method === "GET" && route === "/agent.lua") {
		return send(res, 200, readAgentSource(), "text/plain; charset=utf-8");
	}

	if (req.method === "GET" && route === "/health") {
		return sendJson(res, 200, getHealth());
	}

	if (req.method === "GET" && route === "/latest") {
		const latestPath = path.join(directoryMap.Results, "latest.json");

		if (!fs.existsSync(latestPath)) {
			return sendJson(res, 404, {
				ok: false,
				error: "No result yet",
			});
		}

		return send(res, 200, fs.readFileSync(latestPath), "application/json; charset=utf-8");
	}

	if (req.method === "GET" && (route === "/next" || route === "/agent/next")) {
		const clientName = parsedUrl.searchParams.get("client") || "unknown";
		clientMap.set(clientName, nowIso());

		const command = claimNextCommand(clientName);

		if (!command) {
			return sendJson(res, 200, {
				id: null,
			});
		}

		return sendJson(res, 200, command);
	}

	if (req.method === "POST" && (route === "/enqueue" || route === "/agent/enqueue")) {
		const body = await readBody(req);
		const payload = JSON.parse(body || "{}");
		const command = enqueueCommand(payload.code, payload.label, {
			policy: payload.policy,
			timeout: payload.timeout,
			targetClient: payload.targetClient,
		});

		return sendJson(res, 200, {
			ok: true,
			id: command.id,
			label: command.label,
			policy: command.policy,
			targetClient: command.targetClient,
			timeout: command.timeout,
		});
	}

	if (req.method === "POST" && (route === "/result" || route === "/agent/result")) {
		const body = await readBody(req);
		const payload = JSON.parse(body || "{}");
		const result = writeResult(payload);

		return sendJson(res, 200, {
			ok: true,
			id: result.id,
		});
	}

	if (req.method === "POST" && (route === "/log" || route === "/agent/log")) {
		const body = await readBody(req);
		const payload = JSON.parse(body || "{}");

		appendLog(`[agent-log] ${payload.client || "unknown"} ${payload.line || ""}`);

		return sendJson(res, 200, {
			ok: true,
		});
	}

	return null;
}

function printStartup() {
	console.log(`[Y Hub Dev] Serving ${projectRoot}`);
	console.log(`[Y Hub Dev] Loader http://${host}:${port}/loader.lua`);
	console.log(`[Y Hub Dev] Agent  http://${host}:${port}/agent.lua`);
	console.log(`[Y Hub Dev] Health http://${host}:${port}/health`);
	console.log("");
	console.log("[Y Hub Dev] Executor agent:");
	console.log(`loadstring(game:HttpGet("http://${host}:${port}/agent.lua"))()`);
}

//--> Boot
ensureDirectories();
resetRunningCommands();

const server = http.createServer(async (req, res) => {
	if (req.method === "OPTIONS") {
		return send(res, 204, "");
	}

	const parsedUrl = new URL(req.url || "/", `http://${req.headers.host || `${host}:${port}`}`);
	const route = decodeURIComponent(parsedUrl.pathname || "/");

	try {
		const apiResult = await handleApi(req, res, route, parsedUrl);

		if (apiResult !== null) {
			return apiResult;
		}

		if (req.method !== "GET") {
			return sendJson(res, 405, {
				ok: false,
				error: "Method not allowed",
			});
		}

		return serveStatic(route, res);
	} catch (error) {
		appendLog(`[server-error] ${route} ${error.stack || error.message}`);

		return sendJson(res, 500, {
			ok: false,
			error: error.message,
		});
	}
});

server.listen(port, host, () => {
	appendLog(`[start] port=${port} root=${projectRoot}`);
	printStartup();
});
