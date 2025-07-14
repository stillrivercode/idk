#!/usr/bin/env node

const { Command } = require("commander");
const { createProject } = require("./create-project");
const { validateSystem } = require("./validators");
const chalk = require("chalk");

const program = new Command();

program
  .name("agentic-workflow-template")
  .description("Create AI-powered GitHub workflow automation projects")
  .version(require("../package.json").version);

// Main command - create project
program
  .argument("[project-name]", "name of the project to create")
  .option("-f, --force", "overwrite existing directory")
  .option("--skip-install", "skip npm install")
  .option("--template <template>", "use specific template variant", "default")
  .option("--git-init", "initialize git repository")
  .option("--github-org <org>", "GitHub organization/username")
  .option("--repo-name <name>", "repository name (defaults to project name)")
  .option("--description <desc>", "project description")
  .option(
    "--features <features>",
    "comma-separated list of features (ai-tasks,ai-pr-review,cost-monitoring,security)",
  )
  .option("--non-interactive", "run without prompts using defaults")
  .action(async (projectName, options) => {
    try {
      console.log(chalk.blue.bold("🤖 Create Agentic Workflow"));
      console.log(chalk.gray("Setting up AI-powered GitHub automation...\n"));

      // Validate system requirements
      await validateSystem();

      // Create the project
      await createProject(projectName, options);

      console.log(chalk.green.bold("\n✅ Project created successfully!"));
      console.log(chalk.gray("Next steps:"));
      console.log(chalk.gray("1. Configure your GitHub secrets"));
      console.log(chalk.gray("2. Create your first AI task issue"));
      console.log(chalk.gray("3. Review the generated workflows"));
    } catch (error) {
      console.error(chalk.red.bold("\n❌ Error creating project:"));
      console.error(chalk.red(error.message));

      if (error.code) {
        console.error(chalk.gray(`Error code: ${error.code}`));
      }

      if (process.env.DEBUG) {
        console.error(chalk.gray("\nStack trace:"));
        console.error(error.stack);
      }

      process.exit(1);
    }
  });

// Error handling for uncaught exceptions
process.on("uncaughtException", (error) => {
  console.error(chalk.red.bold("\n💥 Uncaught exception:"));
  console.error(chalk.red(error.message));
  process.exit(1);
});

process.on("unhandledRejection", (reason, _promise) => {
  console.error(chalk.red.bold("\n💥 Unhandled promise rejection:"));
  console.error(chalk.red(reason));
  process.exit(1);
});

program.parse();
