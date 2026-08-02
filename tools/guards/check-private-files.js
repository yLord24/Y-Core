const { execFileSync } = require("child_process");

// Blocks accidental commits of local-only game sources.

//--//Variables
const blockedPathList = [];
const stagedPathList = execFileSync("git", ["diff", "--cached", "--name-only", "--diff-filter=ACMR"], {
	encoding: "utf8",
})
	.split(/\r?\n/)
	.map((filePath) => filePath.trim().replace(/\\/g, "/"))
	.filter(Boolean);

const blockedPatternList = [
	{
		Test: (filePath) => /^games\/[^/]+\//.test(filePath),
		Reason: "private game source",
	},
	{
		Test: (filePath) => /^builds\//.test(filePath),
		Reason: "local build output",
	},
	{
		Test: (filePath) => /^\.env(\.|$)/.test(filePath),
		Reason: "environment secret",
	},
	{
		Test: (filePath) => /\.(private|secret)\.lua$/i.test(filePath),
		Reason: "private Lua file",
	},
];

//--//Source
for (const stagedPath of stagedPathList) {
	for (const blockedPattern of blockedPatternList) {
		if (blockedPattern.Test(stagedPath)) {
			blockedPathList.push(`${stagedPath} (${blockedPattern.Reason})`);
		}
	}
}

if (blockedPathList.length > 0) {
	console.error("[Y Hub Guard] Refusing to commit private/local files:");
	for (const blockedPath of blockedPathList) {
		console.error(` - ${blockedPath}`);
	}
	console.error("[Y Hub Guard] Remove them from the index with git rm --cached <path>.");
	process.exit(1);
}

console.log("[Y Hub Guard] OK");
