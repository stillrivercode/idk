#!/usr/bin/env node

const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");

const allowedCommands = ["analyze-issue", "create-spec-issue", "roadmap"];

const command = process.argv[2];

if (!command || !allowedCommands.includes(command)) {
  console.error(
    `Invalid command. Available commands: ${allowedCommands.join(", ")}`,
  );
  process.exit(1);
}

const scriptPath = path.join(__dirname, "commands", `${command}.sh`);

// eslint-disable-next-line security/detect-non-literal-fs-filename
if (!fs.existsSync(scriptPath)) {
  console.error(`Command script not found: ${scriptPath}`);
  process.exit(1);
}

const child = spawn(scriptPath, process.argv.slice(3), { stdio: "inherit" });

child.on("error", (err) => {
  console.error(`Failed to start command: ${err.message}`);
  process.exit(1);
});

child.on("close", (code) => {
  process.exit(code);
});
