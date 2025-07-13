const fs = require('fs-extra');
const path = require('path');
const chalk = require('chalk');

/**
 * Validate and sanitize file path to prevent path traversal attacks
 * @param {string} filePath - The file path to validate
 * @returns {string} Sanitized file path
 * @throws {Error} If path contains traversal attempts
 */
function sanitizePath(filePath) {
  // Remove any leading/trailing whitespace and null bytes
  const cleanPath = filePath.replace(/[\0\r\n]/g, '').trim();

  // Check for path traversal attempts
  if (
    cleanPath.includes('..') ||
    path.isAbsolute(cleanPath) ||
    cleanPath.includes('\0') ||
    cleanPath.startsWith('/') ||
    cleanPath.startsWith('\\')
  ) {
    throw new Error(`Invalid file path: ${filePath}`);
  }

  // Validate path components don't contain dangerous characters
  const pathComponents = cleanPath.split(path.sep);
  for (const component of pathComponents) {
    if (component === '.' || component === '..') {
      throw new Error(`Invalid path component: ${component} in ${filePath}`);
    }
    // Skip empty components (can happen with trailing slashes)
    if (component === '') {
      continue;
    }
  }

  // Return the normalized path (safe since we've validated no traversal)
  return path.normalize(cleanPath);
}

// Load file list directly from package.json to ensure consistency
const packageJson = require('../package.json');

/**
 * Get files to distribute based on template type
 * Uses package.json files array as the single source of truth
 * @param {string} templateType - The template type (default, minimal, enterprise)
 * @returns {string[]} Array of file paths to copy
 */
function getFilesToDistribute(templateType = 'default') {
  let filesToCopy = [...packageJson.files];

  // Filter out exclusion patterns (files starting with !)
  filesToCopy = filesToCopy.filter((file) => !file.startsWith('!'));

  // For minimal template, exclude docs
  if (templateType === 'minimal') {
    filesToCopy = filesToCopy.filter((file) => !file.includes('docs/'));
  }

  // For enterprise template, add enterprise-specific files if they exist
  if (templateType === 'enterprise') {
    const enterpriseFiles = ['monitoring/', 'advanced-scripts/'];
    filesToCopy.push(...enterpriseFiles);
  }

  return filesToCopy;
}

/**
 * Get package.json files list (used for npm packaging)
 * @returns {string[]} Array of files to include in npm package
 */
function getPackageFiles() {
  return [...packageJson.files];
}

/**
 * Get exclusion filters for file copying
 * @returns {string[]} Array of patterns to exclude
 */
function getExclusionFilters() {
  return [
    'dev-docs/',
    'tests/',
    'venv/',
    '.pytest_cache/',
    'node_modules/',
    '.git/',
  ];
}

/**
 * Validate that required files exist in the template
 * @param {string} templateDir - Path to template directory
 * @returns {Promise<{valid: boolean, missing: string[], warnings: string[]}>}
 */
async function validateTemplateFiles(templateDir) {
  const result = {
    valid: true,
    missing: [],
    warnings: [],
  };

  // Check required files from package.json
  const requiredFiles = [
    '.pre-commit-config.yaml',
    'package.json',
    'README.md',
    'LICENSE',
  ];

  for (const file of requiredFiles) {
    try {
      const sanitizedFile = sanitizePath(file);
      // nosemgrep: javascript.lang.security.audit.path-traversal.path-join-resolve-traversal.path-join-resolve-traversal
      const filePath = path.join(templateDir, sanitizedFile);
      if (!(await fs.pathExists(filePath))) {
        result.valid = false;
        result.missing.push(file);
      }
    } catch (error) {
      result.valid = false;
      result.missing.push(file);
      console.error(chalk.red(`Invalid file path: ${file} - ${error.message}`));
    }
  }

  // Check optional files (warnings only)
  const optionalFiles = ['.yamllint.yaml', '.secrets.baseline'];

  for (const file of optionalFiles) {
    try {
      const sanitizedFile = sanitizePath(file);
      // nosemgrep: javascript.lang.security.audit.path-traversal.path-join-resolve-traversal.path-join-resolve-traversal
      const filePath = path.join(templateDir, sanitizedFile);
      if (!(await fs.pathExists(filePath))) {
        result.warnings.push(file);
      }
    } catch (error) {
      result.warnings.push(file);
      console.error(
        chalk.yellow(`Invalid optional file path: ${file} - ${error.message}`)
      );
    }
  }

  return result;
}

/**
 * Copy files with validation and proper error handling
 * @param {string} templateDir - Source template directory
 * @param {string} targetDir - Target project directory
 * @param {string} templateType - Template type
 * @returns {Promise<{success: boolean, copied: string[], skipped: string[], errors: string[]}>}
 */
async function copyTemplateFiles(
  templateDir,
  targetDir,
  templateType = 'default'
) {
  const result = {
    success: true,
    copied: [],
    skipped: [],
    errors: [],
  };

  // Validate template files first
  const validation = await validateTemplateFiles(templateDir);
  if (!validation.valid) {
    result.success = false;
    result.errors.push(
      `Missing required files: ${validation.missing.join(', ')}`
    );
    return result;
  }

  // Log warnings for missing optional files
  if (validation.warnings.length > 0) {
    console.log(
      chalk.yellow(
        `  ⚠️  Optional files not found: ${validation.warnings.join(', ')}`
      )
    );
  }

  const filesToCopy = getFilesToDistribute(templateType);
  const exclusionFilters = getExclusionFilters();

  for (const file of filesToCopy) {
    try {
      const sanitizedFile = sanitizePath(file);
      // nosemgrep: javascript.lang.security.audit.path-traversal.path-join-resolve-traversal.path-join-resolve-traversal
      const srcPath = path.join(templateDir, sanitizedFile);
      // nosemgrep: javascript.lang.security.audit.path-traversal.path-join-resolve-traversal.path-join-resolve-traversal
      const destPath = path.join(targetDir, sanitizedFile);

      if (await fs.pathExists(srcPath)) {
        await fs.copy(srcPath, destPath, {
          filter: (src) => {
            // Apply exclusion filters
            return !exclusionFilters.some((filter) => src.includes(filter));
          },
        });
        result.copied.push(file);
      } else {
        result.skipped.push(file);
        console.log(chalk.yellow(`  ⚠️  Template file not found: ${file}`));
      }
    } catch (error) {
      result.success = false;
      if (error.message.includes('Invalid file path')) {
        result.errors.push(`Security error - invalid file path: ${file}`);
      } else {
        result.errors.push(`Failed to copy ${file}: ${error.message}`);
      }
    }
  }

  return result;
}

/**
 * Update package.json files list to match current configuration
 * @param {string} packageJsonPath - Path to package.json file
 * @returns {Promise<boolean>} Success status
 */
async function updatePackageJsonFiles(packageJsonPath) {
  try {
    const packageJson = await fs.readJson(packageJsonPath);
    packageJson.files = getPackageFiles();
    await fs.writeJson(packageJsonPath, packageJson, { spaces: 2 });
    return true;
  } catch (error) {
    console.error(
      chalk.red(`Failed to update package.json files: ${error.message}`)
    );
    return false;
  }
}

/**
 * Get file distribution statistics
 * @param {string} templateType - Template type
 * @returns {object} Statistics about file distribution
 */
function getDistributionStats(templateType = 'default') {
  const filesToCopy = getFilesToDistribute(templateType);
  const baseFiles = packageJson.files.length;

  const stats = {
    totalFiles: filesToCopy.length,
    baseFiles: baseFiles,
    templateType,
    sourceFiles: packageJson.files, // Show which files come from package.json
  };

  return stats;
}

module.exports = {
  getFilesToDistribute,
  getPackageFiles,
  getExclusionFilters,
  validateTemplateFiles,
  copyTemplateFiles,
  updatePackageJsonFiles,
  getDistributionStats,
  sanitizePath,
};
