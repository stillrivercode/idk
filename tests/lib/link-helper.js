/**
 * Checks if a given link path should be skipped during validation.
 *
 * @param {string} linkPath - The path of the link to check.
 * @returns {boolean} - True if the link should be skipped, false otherwise.
 */
function shouldSkipLink(linkPath) {
  // Skip external links (http/https) and conceptual 'docs/' links.
  // The 'docs/' directory is a convention for AI-generated content in the user's
  // project and is not expected to exist in this source repository.
  return (
    linkPath.startsWith('http://') ||
    linkPath.startsWith('https://') ||
    linkPath.startsWith('docs/')
  );
}

module.exports = { shouldSkipLink };
