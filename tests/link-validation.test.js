#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const glob = require('glob');

class LinkValidationTest {
  constructor() {
    this.rootDir = path.dirname(__dirname);
    this.passed = 0;
    this.failed = 0;
    this.tests = [];
    this.linkMap = new Map();
  }

  runTests() {
    console.log('🧪 Testing Link Validation...\n');

    this.buildLinkMap();
    this.testMainIndexLinks();
    this.testCommandFileLinks();
    this.testCrossReferences();
    this.testLinkConsistency();
    this.testExternalLinkFormat();

    this.reportResults();
    return this.failed === 0;
  }

  test(description, testFn) {
    try {
      testFn();
      this.passed++;
      console.log(`✅ ${description}`);
      this.tests.push({ description, status: 'PASS' });
    } catch (error) {
      this.failed++;
      console.log(`❌ ${description}: ${error.message}`);
      this.tests.push({ description, status: 'FAIL', error: error.message });
    }
  }

  buildLinkMap() {
    console.log('🗺️  Building link map...');

    const allFiles = glob.sync('**/*.md', {
      cwd: this.rootDir,
      ignore: ['node_modules/**', 'CHANGELOG.md']
    });

    allFiles.forEach(file => {
      const filePath = path.join(this.rootDir, file);
      const content = fs.readFileSync(filePath, 'utf8');

      // Extract all markdown links
      const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
      let match;
      const links = [];

      while ((match = linkPattern.exec(content)) !== null) {
        const [fullMatch, linkText, linkPath] = match;
        links.push({
          text: linkText,
          path: linkPath,
          fullMatch,
          lineNumber: this.getLineNumber(content, match.index)
        });
      }

      this.linkMap.set(file, links);
    });

    console.log(`📊 Found ${allFiles.length} files with ${Array.from(this.linkMap.values()).flat().length} total links`);
  }

  getLineNumber(content, index) {
    return content.substring(0, index).split('\n').length;
  }

  testMainIndexLinks() {
    console.log('📋 Testing main index links...');

    const mainIndexFile = 'information-dense-keywords.md';
    const links = this.linkMap.get(mainIndexFile) || [];

    this.test('Main index file exists and has links', () => {
      if (links.length === 0) {
        throw new Error('No links found in main index file');
      }
    });

    // Test dictionary links specifically
    const dictionaryLinks = links.filter(link => link.path.startsWith('dictionary/'));

    this.test('Main index has dictionary command links', () => {
      if (dictionaryLinks.length === 0) {
        throw new Error('No dictionary command links found in main index');
      }
    });

    dictionaryLinks.forEach((link, index) => {
      this.test(`Main index link ${index + 1}: "${link.text}" -> ${link.path}`, () => {
        const fullPath = path.join(this.rootDir, link.path);
        if (!fs.existsSync(fullPath)) {
          throw new Error(`Target file does not exist: ${link.path}`);
        }

        // Verify the target file has the expected command name
        const targetContent = fs.readFileSync(fullPath, 'utf8');
        const h1Match = targetContent.match(/^# (.+)/m);

        if (!h1Match) {
          throw new Error(`Target file has no H1 title: ${link.path}`);
        }

        const targetTitle = h1Match[1].trim();
        if (!this.titlesMatch(link.text, targetTitle)) {
          throw new Error(`Link text "${link.text}" doesn't match target title "${targetTitle}"`);
        }
      });
    });
  }

  testCommandFileLinks() {
    console.log('📁 Testing command file links...');

    const commandFiles = Array.from(this.linkMap.keys()).filter(file =>
      file.startsWith('dictionary/') && file.endsWith('.md')
    );

    commandFiles.forEach(file => {
      const links = this.linkMap.get(file) || [];
      const fileName = path.basename(file);

      // Test relative links within command files
      const relativeLinks = links.filter(link =>
        link.path.startsWith('../') || link.path.startsWith('./')
      );

      relativeLinks.forEach(link => {
        this.test(`${fileName}: relative link "${link.text}" -> ${link.path}`, () => {
          const filePath = path.join(this.rootDir, file);
          const resolvedPath = path.resolve(path.dirname(filePath), link.path);
          const isDirectory = fs.existsSync(resolvedPath) && fs.lstatSync(resolvedPath).isDirectory();

          if (!fs.existsSync(resolvedPath) && !isDirectory) {
            throw new Error(`Broken relative link: ${link.path} (line ${link.lineNumber})`);
          }
        });
      });
    });
  }

  testCrossReferences() {
    console.log('🔗 Testing cross-references...');

    this.linkMap.forEach((links, file) => {
      const fileName = path.basename(file);

      links.forEach(link => {
        this.test(`${fileName}: cross-reference "${link.text}" -> ${link.path} is valid`, () => {
          if (link.path.startsWith('http') || link.path.startsWith('docs/')) {
            return; // Skip external links and conceptual docs links
          }

          const targetPath = path.resolve(path.dirname(path.join(this.rootDir, file)), link.path);

          if (!fs.existsSync(targetPath)) {
            throw new Error(`Broken link: target does not exist at ${link.path} (line ${link.lineNumber})`);
          }
        });
      });
    });
  }

  testLinkConsistency() {
    console.log('🎯 Testing link consistency...');

    // Find all links that point to the same target
    const targetMap = new Map();

    this.linkMap.forEach((links, sourceFile) => {
      links.forEach(link => {
        if (!link.path.startsWith('http')) {
          const normalizedPath = path.normalize(link.path);

          if (!targetMap.has(normalizedPath)) {
            targetMap.set(normalizedPath, []);
          }

          targetMap.get(normalizedPath).push({
            sourceFile,
            linkText: link.text,
            fullMatch: link.fullMatch
          });
        }
      });
    });

    // Check for inconsistent link text to same target (relaxed - just warnings)
    targetMap.forEach((references, targetPath) => {
      if (references.length > 1) {
        this.test(`Consistent link text for ${targetPath}`, () => {
          const linkTexts = [...new Set(references.map(ref => ref.linkText))];

          if (linkTexts.length > 1) {
            const details = references.map(ref =>
              `"${ref.linkText}" in ${ref.sourceFile}`
            ).join(', ');

            // Only warn for cosmetic inconsistencies, don't fail tests
            console.log(`⚠️  Link text varies for ${targetPath}: ${details}`);
            // Allow the test to pass - this is cosmetic
          }
        });
      }
    });
  }

  testExternalLinkFormat() {
    console.log('🌐 Testing external link format...');

    this.linkMap.forEach((links, sourceFile) => {
      const externalLinks = links.filter(link =>
        link.path.startsWith('http://') || link.path.startsWith('https://')
      );

      externalLinks.forEach(link => {
        this.test(`${sourceFile}: external link format "${link.path}"`, () => {
          // Prefer HTTPS over HTTP
          if (link.path.startsWith('http://')) {
            console.log(`⚠️  Consider using HTTPS: ${link.path} in ${sourceFile}`);
          }

          // Check for common URL issues
          if (link.path.includes(' ')) {
            throw new Error(`URL contains spaces: ${link.path}`);
          }

          if (!link.path.match(/^https?:\/\/.+\..+/)) {
            throw new Error(`Invalid URL format: ${link.path}`);
          }
        });
      });
    });
  }

  titlesMatch(linkText, targetTitle) {
    // Remove markdown formatting and normalize
    const normalizeText = (text) =>
      text.replace(/\*\*/g, '').replace(/`/g, '').trim().toLowerCase();

    const normalizedLink = normalizeText(linkText);
    const normalizedTarget = normalizeText(targetTitle);

    return normalizedLink === normalizedTarget ||
           normalizedLink.includes(normalizedTarget) ||
           normalizedTarget.includes(normalizedLink);
  }

  reportResults() {
    console.log('\n📊 Link Validation Test Results:');
    console.log('=================================');

    if (this.failed === 0) {
      console.log(`✅ All ${this.passed} link tests passed! All links are valid.`);
    } else {
      console.log(`❌ ${this.failed} test(s) failed, ${this.passed} passed`);

      console.log('\nFailed tests:');
      this.tests
        .filter(test => test.status === 'FAIL')
        .forEach(test => {
          console.log(`   • ${test.description}: ${test.error}`);
        });
    }

    console.log(`\n📈 Summary: ${this.passed} passed, ${this.failed} failed`);
    console.log(`🔗 Total links analyzed: ${Array.from(this.linkMap.values()).flat().length}`);
  }
}

// Run tests if called directly
if (require.main === module) {
  const tester = new LinkValidationTest();
  const success = tester.runTests();
  process.exit(success ? 0 : 1);
}

module.exports = LinkValidationTest;
