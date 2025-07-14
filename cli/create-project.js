const fs = require("fs-extra");
const path = require("path");
const chalk = require("chalk");
const { spawn } = require("child_process");
const {
  validateAndGetProjectName,
  handleDirectoryConflict,
  validateTemplate,
  validateNonInteractiveOptions,
  validateGitHubOrgIfProvided,
} = require("./project-validation");
const { collectConfiguration } = require("./configuration-manager");
// Removed setupSecrets - replaced with sample env creation
const {
  copyTemplateFiles,
  getDistributionStats,
} = require("./file-distribution");

// Sanitize path to prevent directory traversal
function sanitizePath(userPath) {
  // Remove any path traversal attempts
  const normalized = path.normalize(userPath).replace(/^(\.\.(\/|\\|$))+/, "");
  // Ensure the path doesn't contain any remaining traversal patterns
  if (normalized.includes("..")) {
    throw new Error("Invalid path: Path traversal detected");
  }
  // Additional checks for absolute paths and null bytes
  if (path.isAbsolute(normalized) || normalized.includes("\0")) {
    throw new Error("Invalid path: Absolute paths and null bytes not allowed");
  }
  return normalized;
}

// Find package root directory (works for both local dev and npx)
function findPackageRoot(startDir) {
  let currentDir = startDir;
  while (currentDir !== path.dirname(currentDir)) {
    const packageJsonPath = path.join(currentDir, "package.json");
    // eslint-disable-next-line security/detect-non-literal-fs-filename
    if (fs.existsSync(packageJsonPath)) {
      try {
        const pkg = fs.readJsonSync(packageJsonPath);
        // Verify this is the correct package
        if (pkg.name === "@stillrivercode/agentic-workflow-template") {
          // Validate essential template files exist
          const essentialFiles = ["cli/", "scripts/", "package.json"];
          const missingFiles = essentialFiles.filter(
            (file) =>
              // eslint-disable-next-line security/detect-non-literal-fs-filename
              !fs.existsSync(path.join(currentDir, file)),
          );

          if (missingFiles.length === 0) {
            return currentDir;
          }
          // Continue searching if essential files are missing
        }
      } catch (_e) {
        // Continue searching if can't read package.json
      }
    }
    currentDir = path.dirname(currentDir);
  }

  // Fallback: try to resolve via require (works in npm global installs)
  try {
    const packageJsonPath = require.resolve(
      "@stillrivercode/agentic-workflow-template/package.json",
    );
    const packageDir = path.dirname(packageJsonPath);

    // Validate essential template files exist in resolved package
    const essentialFiles = ["cli/", "scripts/", "package.json"];
    const missingFiles = essentialFiles.filter(
      (file) =>
        // eslint-disable-next-line security/detect-non-literal-fs-filename
        !fs.existsSync(path.join(packageDir, file)),
    );

    if (missingFiles.length === 0) {
      return packageDir;
    }
  } catch (_e) {
    // Fall through to final fallback
  }

  // If all else fails, return the parent directory (original behavior)
  return path.join(startDir, "..");
}

/**
 * Creates a new project with AI-powered workflow automation
 * @param {string} projectName - Name of the project to create
 * @param {Object} options - Configuration options
 * @param {boolean} options.force - Force overwrite existing directory
 * @param {boolean} options.nonInteractive - Run without prompts
 * @param {string} options.githubOrg - GitHub organization
 * @param {string} options.repoName - Repository name
 * @param {string} options.description - Project description
 * @param {string} options.template - Template type
 * @param {string} options.features - Comma-separated features
 * @param {boolean} options.gitInit - Initialize git repository
 * @returns {Promise<void>}
 */
async function createProject(projectName, options = {}) {
  // Validate inputs
  validateTemplate(options.template);
  validateNonInteractiveOptions(options);
  validateGitHubOrgIfProvided(options.githubOrg);

  // Get and validate project name
  const validatedProjectName = await validateAndGetProjectName(
    projectName,
    options,
  );

  const config = {
    projectName: validatedProjectName,
    projectPath: path.resolve(
      process.cwd(),
      sanitizePath(validatedProjectName),
    ),
  };

  // Handle directory conflicts
  await handleDirectoryConflict(
    config.projectPath,
    validatedProjectName,
    options,
  );

  // Collect configuration
  await collectConfiguration(config, options);

  // Create project structure
  await createProjectStructure(config, options);

  // Secrets setup removed - users configure manually

  // Initialize git if requested
  if (options.gitInit) {
    await initializeGit(config);
  }

  console.log(chalk.green(`\n📁 Project created at: ${config.projectPath}`));
}

// Configuration collection is now handled by configuration-manager.js

async function createProjectStructure(config, _options) {
  console.log(chalk.blue("\n🏗️  Creating project structure..."));

  // Find the package root directory (works for both local dev and npx)
  const templateDir = findPackageRoot(__dirname);
  if (!templateDir) {
    throw new Error(
      "Unable to locate template files. Please ensure the package is installed correctly.",
    );
  }

  const targetDir = config.projectPath;

  // Create target directory
  await fs.ensureDir(targetDir);

  // Show distribution statistics
  const stats = getDistributionStats(config.template);
  console.log(
    chalk.gray(
      `  📊 Distributing ${stats.totalFiles} files for ${stats.templateType} template`,
    ),
  );

  // Debug logging for troubleshooting npx issues
  if (process.env.DEBUG) {
    console.log(chalk.gray(`  📍 Template directory: ${templateDir}`));
    console.log(chalk.gray(`  📍 Target directory: ${targetDir}`));
  }

  // Copy template files using centralized configuration
  const result = await copyTemplateFiles(
    templateDir,
    targetDir,
    config.template,
  );

  if (!result.success) {
    console.error(chalk.red("\n❌ Failed to copy template files"));
    console.error(chalk.red(`Template directory: ${templateDir}`));
    console.error(chalk.red(`Errors: ${result.errors.join(", ")}`));
    throw new Error(
      `Failed to create project structure: ${result.errors.join(", ")}`,
    );
  }

  // Log copy results
  if (result.copied.length > 0) {
    console.log(
      chalk.green(`  ✅ Copied ${result.copied.length} files successfully`),
    );
  }

  if (result.skipped.length > 0) {
    console.log(
      chalk.yellow(`  ⚠️  Skipped ${result.skipped.length} missing files`),
    );
  }

  if (result.errors.length > 0) {
    console.log(chalk.red(`  ❌ Errors: ${result.errors.join(", ")}`));
  }

  // Generate configuration files
  await generateConfigFiles(config);

  console.log(chalk.green("  ✅ Project structure created"));
}

async function generateConfigFiles(config) {
  const configDir = path.join(config.projectPath, ".github");
  await fs.ensureDir(configDir);

  // Generate repository configuration
  const repoConfig = {
    name: config.repositoryName,
    description: config.description,
    owner: config.githubOrg,
    features: config.features,
    template: config.template,
    created: new Date().toISOString(),
  };

  await fs.writeJson(path.join(configDir, "repo-config.json"), repoConfig, {
    spaces: 2,
  });

  // Update README with project-specific information (only if it was copied)
  await updateReadme(config);
}

async function updateReadme(config) {
  const readmePath = path.join(config.projectPath, "README.md");

  // Check if README.md exists before trying to read it
  if (!(await fs.pathExists(readmePath))) {
    console.log(
      chalk.yellow(
        `⚠️  README.md template not found. Creating default README.md...`,
      ),
    );

    // Create a basic README.md as fallback
    const defaultReadme = generateDefaultReadme(config);
    // eslint-disable-next-line security/detect-non-literal-fs-filename
    await fs.writeFile(readmePath, defaultReadme);
    console.log(chalk.green(`  ✅ Created default README.md`));
    return;
  }

  // eslint-disable-next-line security/detect-non-literal-fs-filename
  let readme = await fs.readFile(readmePath, "utf8");

  // Replace template placeholders
  readme = readme
    .replace(/agentic-workflow-template/g, config.repositoryName)
    .replace(/YOUR_ORG/g, config.githubOrg)
    .replace(/YOUR_REPO/g, config.repositoryName)
    .replace(/{{PROJECT_DESCRIPTION}}/g, config.description)
    .replace(/{{PROJECT_NAME}}/g, config.repositoryName);

  // eslint-disable-next-line security/detect-non-literal-fs-filename
  await fs.writeFile(readmePath, readme);
  console.log(chalk.green(`  ✅ Updated README.md with project details`));
}

function generateDefaultReadme(config) {
  // Validate and normalize config properties
  const projectName = config.repositoryName || "New Project";
  const description =
    config.description || "AI-powered workflow automation project";
  const features = Array.isArray(config.features) ? config.features : [];

  return `# ${projectName}

${description}

## 🚀 Quick Start

This project uses AI-powered GitHub workflow automation.

### Setup

1. Configure your GitHub secrets:
   \`\`\`bash
   gh secret set OPENROUTER_API_KEY
   \`\`\`

2. Create your first AI task:
   \`\`\`bash
   gh issue create --title "Your task description" --label "ai-task"
   \`\`\`

3. Watch as AI automatically implements your requirements!

## 🔧 Available Features

${features.includes("ai-tasks") ? "- ✅ AI Task Automation" : ""}
${features.includes("ai-pr-review") ? "- ✅ AI PR Review" : ""}
${features.includes("cost-monitoring") ? "- ✅ Cost Monitoring" : ""}
${features.includes("security") ? "- ✅ Security Scanning" : ""}

## 🏷️ Available Labels

- \`ai-task\` - General AI development tasks
- \`ai-bug-fix\` - AI-assisted bug fixes
- \`ai-refactor\` - Code refactoring requests
- \`ai-test\` - Test generation
- \`ai-docs\` - Documentation updates

## 📚 Documentation

- [Getting Started Guide](docs/simplified-architecture.md)
- [AI Workflow Guide](docs/ai-workflows.md)
- [Security Guidelines](docs/security.md)

## 🆘 Support

Need help? Create an issue with the \`help\` label.

---

*Generated by [Agentic Workflow Template](https://github.com/stillrivercode/agentic-workflow-template)*
`;
}

async function initializeGit(config) {
  console.log(chalk.blue("\n🔧 Initializing git repository..."));

  return new Promise((resolve, reject) => {
    const git = spawn("git", ["init"], {
      cwd: config.projectPath,
      stdio: "inherit",
    });

    git.on("close", (code) => {
      if (code === 0) {
        console.log(chalk.green("  ✅ Git repository initialized"));
        resolve();
      } else {
        reject(new Error(`Git init failed with code ${code}`));
      }
    });

    git.on("error", (error) => {
      reject(new Error(`Failed to initialize git: ${error.message}`));
    });
  });
}

module.exports = { createProject, findPackageRoot };
