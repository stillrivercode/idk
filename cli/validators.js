const validateNpmName = require("validate-npm-package-name");
const fs = require("fs-extra");
const path = require("path");

// Sanitize path to prevent directory traversal
function sanitizePath(userPath) {
  // Remove any path traversal attempts
  const normalized = path.normalize(userPath).replace(/^(\.\.(\/|\\|$))+/, "");
  // Ensure the path doesn't contain any remaining traversal patterns
  if (normalized.includes("..")) {
    throw new Error("Invalid path: Path traversal detected");
  }
  return normalized;
}

/**
 * Validate project name
 */
function validateProjectName(name) {
  if (!name || typeof name !== "string") {
    throw new Error("Project name is required");
  }

  const trimmed = name.trim();

  if (trimmed.length === 0) {
    throw new Error("Project name cannot be empty");
  }

  if (trimmed.length > 214) {
    throw new Error("Project name must be less than 214 characters");
  }

  if (trimmed !== trimmed.toLowerCase()) {
    throw new Error("Project name must be lowercase");
  }

  if (!/^[a-z0-9-_]+$/.test(trimmed)) {
    throw new Error(
      "Project name can only contain lowercase letters, numbers, hyphens, and underscores",
    );
  }

  if (trimmed.startsWith("-") || trimmed.endsWith("-")) {
    throw new Error("Project name cannot start or end with a hyphen");
  }

  // Check for reserved names
  const reservedNames = ["node", "npm", "core", "console", "global", "process"];
  if (reservedNames.includes(trimmed)) {
    throw new Error(`Project name "${trimmed}" is reserved and cannot be used`);
  }

  // Check against npm name validation
  const npmValidation = validateNpmName(trimmed);
  if (!npmValidation.validForNewPackages) {
    const errors = npmValidation.errors || [];
    const warnings = npmValidation.warnings || [];
    const issues = [...errors, ...warnings];
    throw new Error(`Invalid project name: ${issues.join(", ")}`);
  }

  return true;
}

/**
 * Validate OpenRouter API key
 */
function validateApiKey(key) {
  if (!key || typeof key !== "string") {
    return "API key is required";
  }

  const trimmed = key.trim();

  if (trimmed.length === 0) {
    return "API key cannot be empty";
  }

  // OpenRouter API keys typically start with 'sk-or-'
  if (!trimmed.startsWith("sk-or-")) {
    return 'OpenRouter API key should start with "sk-or-"';
  }

  if (trimmed.length < 20) {
    return "API key appears to be too short";
  }

  if (trimmed.length > 200) {
    return "API key appears to be too long";
  }

  // Check for valid characters (base64-like)
  if (!/^[a-zA-Z0-9-_]+$/.test(trimmed)) {
    return "API key contains invalid characters";
  }

  return true;
}

/**
 * Validate system requirements
 */
async function validateSystem() {
  console.log("🔍 Checking system requirements...");

  // Skip system checks in CI environment
  if (process.env.CI || process.env.NODE_ENV === "test") {
    console.log("✅ Skipping system requirements check in CI/test environment");
    return;
  }

  // Check Node.js version
  const nodeVersion = process.version;
  const majorVersion = parseInt(nodeVersion.slice(1).split(".")[0]);

  if (majorVersion < 18) {
    throw new Error(
      `Node.js 18.0.0 or higher is required. Current version: ${nodeVersion}`,
    );
  }

  // Check npm
  try {
    const { execSync } = require("child_process");
    const npmVersion = execSync("npm --version", { encoding: "utf8" }).trim();
    const npmMajor = parseInt(npmVersion.split(".")[0]);

    if (npmMajor < 8) {
      throw new Error(
        `npm 8.0.0 or higher is required. Current version: ${npmVersion}`,
      );
    }
  } catch (_error) {
    throw new Error("npm is not installed or not accessible");
  }

  // Check git (optional but recommended)
  try {
    const { execSync } = require("child_process");
    execSync("git --version", { encoding: "utf8" });
  } catch (_error) {
    console.warn(
      "⚠️  Git is not installed. Some features may not work properly.",
    );
  }

  // Check network connectivity (basic check)
  try {
    const https = require("https");
    await new Promise((resolve, reject) => {
      const req = https.request(
        "https://api.github.com",
        { method: "HEAD", timeout: 5000 },
        (_res) => {
          resolve();
        },
      );
      req.on("error", reject);
      req.on("timeout", () => reject(new Error("Network timeout")));
      req.end();
    });
  } catch (_error) {
    console.warn(
      "⚠️  Network connectivity check failed. GitHub API may not be accessible.",
    );
  }

  console.log("✅ System requirements validated");
}

/**
 * Validate GitHub organization/username
 */
function validateGitHubOrg(org) {
  if (!org || typeof org !== "string") {
    return "GitHub organization/username is required";
  }

  const trimmed = org.trim();

  if (trimmed.length === 0) {
    return "GitHub organization/username cannot be empty";
  }

  if (trimmed.length > 39) {
    return "GitHub organization/username must be 39 characters or fewer";
  }

  if (!/^[a-zA-Z0-9-]+$/.test(trimmed)) {
    return "GitHub organization/username can only contain alphanumeric characters and hyphens";
  }

  if (trimmed.startsWith("-") || trimmed.endsWith("-")) {
    return "GitHub organization/username cannot start or end with a hyphen";
  }

  if (trimmed.includes("--")) {
    return "GitHub organization/username cannot contain consecutive hyphens";
  }

  return true;
}

/**
 * Validate directory write permissions
 */
async function validateWritePermissions(dirPath) {
  try {
    const testFile = path.join(sanitizePath(dirPath), ".write-test");
    // eslint-disable-next-line security/detect-non-literal-fs-filename
    await fs.writeFile(testFile, "test");
    await fs.remove(testFile);
    return true;
  } catch (_error) {
    throw new Error(`No write permission for directory: ${dirPath}`);
  }
}

module.exports = {
  validateProjectName,
  validateApiKey,
  validateSystem,
  validateGitHubOrg,
  validateWritePermissions,
};
