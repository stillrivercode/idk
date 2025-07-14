const inquirer = require("inquirer");
const fs = require("fs-extra");
const { validateProjectName, validateGitHubOrg } = require("./validators");

/**
 * Validates project name and handles interactive/non-interactive modes
 * @param {string} projectName - The project name to validate
 * @param {Object} options - CLI options
 * @param {boolean} options.nonInteractive - Whether running in non-interactive mode
 * @returns {Promise<string>} - The validated project name
 */
async function validateAndGetProjectName(projectName, options) {
  if (!projectName || projectName.trim() === "") {
    if (options.nonInteractive) {
      throw new Error("Project name is required in non-interactive mode");
    }

    const { name } = await inquirer.prompt([
      {
        type: "input",
        name: "name",
        message: "Project name:",
        validate: validateProjectName,
        filter: (input) => input.trim(),
      },
    ]);
    return name;
  }

  validateProjectName(projectName);
  return projectName;
}

/**
 * Checks if directory exists and handles overwrite logic
 * @param {string} projectPath - Path to the project directory
 * @param {string} projectName - Name of the project
 * @param {Object} options - CLI options
 * @param {boolean} options.force - Whether to force overwrite
 * @param {boolean} options.nonInteractive - Whether running in non-interactive mode
 * @returns {Promise<void>}
 */
async function handleDirectoryConflict(projectPath, projectName, options) {
  if (!(await fs.pathExists(projectPath))) {
    return; // No conflict
  }

  if (options.force) {
    await fs.remove(projectPath);
    return;
  }

  if (options.nonInteractive) {
    throw new Error(
      `Directory "${projectName}" already exists. Use --force to overwrite.`,
    );
  }

  const { overwrite } = await inquirer.prompt([
    {
      type: "confirm",
      name: "overwrite",
      message: `Directory "${projectName}" already exists. Overwrite?`,
      default: false,
    },
  ]);

  if (!overwrite) {
    throw new Error("Operation cancelled");
  }

  await fs.remove(projectPath);
}

/**
 * Validates template type
 * @param {string} template - The template type to validate
 * @returns {void}
 * @throws {Error} If template is invalid
 */
function validateTemplate(template) {
  const validTemplates = ["default", "minimal", "enterprise"];
  if (template && !validTemplates.includes(template)) {
    throw new Error(
      `Invalid template "${template}". Valid options: ${validTemplates.join(", ")}`,
    );
  }
}

/**
 * Validates required options for non-interactive mode
 * @param {Object} options - CLI options
 * @param {boolean} options.nonInteractive - Whether running in non-interactive mode
 * @param {string} options.githubOrg - GitHub organization
 * @returns {void}
 * @throws {Error} If required options are missing
 */
function validateNonInteractiveOptions(options) {
  if (options.nonInteractive && !options.githubOrg) {
    throw new Error(
      "GitHub organization (--github-org) is required in non-interactive mode",
    );
  }
}

/**
 * Validates GitHub organization if provided
 * @param {string} githubOrg - GitHub organization to validate
 * @returns {void}
 * @throws {Error} If organization is invalid
 */
function validateGitHubOrgIfProvided(githubOrg) {
  if (githubOrg) {
    const orgValidation = validateGitHubOrg(githubOrg);
    if (orgValidation !== true) {
      throw new Error(orgValidation);
    }
  }
}

module.exports = {
  validateAndGetProjectName,
  handleDirectoryConflict,
  validateTemplate,
  validateNonInteractiveOptions,
  validateGitHubOrgIfProvided,
};
