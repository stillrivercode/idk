const chalk = require("chalk");
const inquirer = require("inquirer");
const { validateGitHubOrgIfProvided } = require("./project-validation");

/**
 * Builds configuration from CLI options for non-interactive mode
 * @param {Object} config - Base configuration object
 * @param {Object} options - CLI options
 * @returns {void}
 */
function buildNonInteractiveConfig(config, options) {
  console.log(
    chalk.gray("Using non-interactive mode with provided options..."),
  );

  // Set defaults from CLI options or use sensible defaults
  config.template = options.template || "default";
  config.githubOrg = options.githubOrg || "your-org";
  config.repositoryName = options.repoName || config.projectName;
  config.description =
    options.description || "AI-powered workflow automation project";

  // Parse features from comma-separated string or use defaults
  if (options.features) {
    config.features = options.features.split(",").map((f) => f.trim());
  } else {
    config.features = [
      "ai-tasks",
      "ai-pr-review",
      "cost-monitoring",
      "security",
    ];
  }

  console.log(chalk.gray(`  Template: ${config.template}`));
  console.log(chalk.gray(`  GitHub Org: ${config.githubOrg}`));
  console.log(chalk.gray(`  Repository: ${config.repositoryName}`));
  console.log(chalk.gray(`  Features: ${config.features.join(", ")}`));
}

/**
 * Creates questions for interactive configuration
 * @param {Object} config - Base configuration object
 * @param {Object} options - CLI options
 * @returns {Array} Array of inquirer questions
 */
function createConfigurationQuestions(config, options) {
  const questions = [
    {
      type: "input",
      name: "githubOrg",
      message: "GitHub organization/username:",
      default: options.githubOrg,
      validate: (input) =>
        input.trim().length > 0 || "Organization is required",
      filter: (input) => input.trim(),
      when: () => !options.githubOrg,
    },
    {
      type: "input",
      name: "repositoryName",
      message: "Repository name:",
      default: options.repoName || config.projectName,
      validate: (input) =>
        input.trim().length > 0 || "Repository name is required",
      filter: (input) => input.trim(),
      when: () => !options.repoName,
    },
    {
      type: "input",
      name: "description",
      message: "Project description:",
      default: options.description || "AI-powered workflow automation project",
      when: () => !options.description,
    },
    {
      type: "checkbox",
      name: "features",
      message: "Select features to enable:",
      choices: [
        { name: "AI Task Automation", value: "ai-tasks", checked: true },
        { name: "AI PR Review", value: "ai-pr-review", checked: true },
        { name: "Cost Monitoring", value: "cost-monitoring", checked: true },
        { name: "Security Scanning", value: "security", checked: true },
      ],
      when: () => !options.features,
    },
  ];

  // Add template question if not specified
  if (!options.template || options.template === "default") {
    questions.unshift({
      type: "list",
      name: "template",
      message: "Choose project template:",
      choices: [
        { name: "Default (Recommended)", value: "default" },
        { name: "Minimal (Basic workflows only)", value: "minimal" },
        { name: "Enterprise (Advanced features)", value: "enterprise" },
      ],
      default: "default",
    });
  }

  return questions;
}

/**
 * Merges CLI options with interactive answers
 * @param {Object} config - Base configuration object
 * @param {Object} options - CLI options
 * @param {Object} answers - Inquirer answers
 * @returns {void}
 */
function mergeConfigurationAnswers(config, options, answers) {
  Object.assign(config, {
    template: options.template || answers.template || "default",
    githubOrg: options.githubOrg || answers.githubOrg,
    repositoryName: options.repoName || answers.repositoryName,
    description: options.description || answers.description,
    features: options.features
      ? options.features.split(",").map((f) => f.trim())
      : answers.features,
  });
}

/**
 * Determines if non-interactive mode should be used
 * @param {Object} options - CLI options
 * @returns {boolean}
 */
function shouldUseNonInteractiveMode(options) {
  return options.nonInteractive || (options.githubOrg && options.repoName);
}

/**
 * Main configuration collection function
 * @param {Object} config - Base configuration object
 * @param {Object} options - CLI options
 * @returns {Promise<void>}
 */
async function collectConfiguration(config, options) {
  console.log(chalk.blue("\n📋 Project Configuration"));

  // Use non-interactive mode if appropriate
  if (shouldUseNonInteractiveMode(options)) {
    buildNonInteractiveConfig(config, options);
    return;
  }

  // Interactive mode
  const questions = createConfigurationQuestions(config, options);
  const answers = await inquirer.prompt(questions);

  mergeConfigurationAnswers(config, options, answers);

  // Validate GitHub organization for interactive flow
  if (config.githubOrg && !options.githubOrg) {
    validateGitHubOrgIfProvided(config.githubOrg);
  }
}

module.exports = {
  collectConfiguration,
  buildNonInteractiveConfig,
  createConfigurationQuestions,
  mergeConfigurationAnswers,
  shouldUseNonInteractiveMode,
};
