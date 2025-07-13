const { execSync } = require('child_process');

const dependencies = ['gh', 'jq'];
const missing = [];

for (const dep of dependencies) {
  try {
    execSync(`command -v ${dep}`, { stdio: 'ignore' });
  } catch (_err) {
    missing.push(dep);
  }
}

if (missing.length > 0) {
  console.warn(`
    \x1b[33mWarning: The following dependencies are not installed: ${missing.join(', ')}\x1b[0m
    \x1b[33mThe shared commands may not function correctly without them.\x1b[0m
    \x1b[33mPlease install them to ensure full functionality.\x1b[0m
  `);
}
