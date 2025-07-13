#!/usr/bin/env node

// Script to update package.json files array to match centralized configuration
const fs = require('fs-extra');
const path = require('path');
const { getPackageFiles } = require('./file-distribution');

async function updatePackageFiles() {
  const packageJsonPath = path.join(__dirname, '..', 'package.json');

  try {
    // Load current package.json
    const packageJson = await fs.readJson(packageJsonPath);

    // Get the centralized file list
    const centralizedFiles = getPackageFiles();

    // Update files array
    packageJson.files = centralizedFiles;

    // Write back to package.json
    await fs.writeJson(packageJsonPath, packageJson, { spaces: 2 });

    console.log('✅ Successfully updated package.json files array');
    console.log(
      `📦 ${centralizedFiles.length} files configured for distribution`
    );
    console.log('Files:', centralizedFiles.join(', '));
  } catch (error) {
    console.error('❌ Error updating package.json:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  updatePackageFiles();
}

module.exports = { updatePackageFiles };
