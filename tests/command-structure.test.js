#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const glob = require('glob');

class CommandStructureTest {
  constructor() {
    this.rootDir = path.dirname(__dirname);
    this.dictionaryDir = path.join(this.rootDir, 'dictionary');
    this.passed = 0;
    this.failed = 0;
    this.tests = [];
  }

  runTests() {
    console.log('🧪 Testing Command Structure...\n');

    this.testCommandFileStructure();
    this.testCommandCategories();
    this.testCommandExamples();
    this.testOutputFormats();
    this.testRelatedCommandLinks();

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

  testCommandFileStructure() {
    console.log('📋 Testing command file structure...');

    const commandFiles = glob.sync('dictionary/**/*.md', { cwd: this.rootDir });

    this.test('All command files have proper extension', () => {
      if (commandFiles.length === 0) {
        throw new Error('No command files found');
      }

      commandFiles.forEach(file => {
        if (!file.endsWith('.md')) {
          throw new Error(`Invalid file extension: ${file}`);
        }
      });
    });

    commandFiles.forEach(file => {
      const filePath = path.join(this.rootDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      const fileName = path.basename(file);

      this.test(`${fileName} has proper H1 title`, () => {
        const h1Match = content.match(/^# (.+)/m);
        if (!h1Match) {
          throw new Error('Missing H1 title');
        }

        const title = h1Match[1].trim();
        if (title.length === 0) {
          throw new Error('Empty H1 title');
        }
      });

      this.test(`${fileName} has required metadata fields`, () => {
        const requiredFields = ['**Category**:', '**Definition**:'];
        requiredFields.forEach(field => {
          if (!content.includes(field)) {
            throw new Error(`Missing required field: ${field}`);
          }
        });
      });

      this.test(`${fileName} has proper section structure`, () => {
        const requiredSections = [
          '## Example Prompts',
          '## Expected Output Format'
        ];

        requiredSections.forEach(section => {
          if (!content.includes(section)) {
            throw new Error(`Missing required section: ${section}`);
          }
        });
      });
    });
  }

  testCommandCategories() {
    console.log('📂 Testing command categories...');

    const expectedCategories = {
      'core': 'Core Commands',
      'development': 'Development Commands',
      'documentation': 'Documentation Commands',
      'quality-assurance': 'Quality Assurance Commands',
      'workflow': 'Workflow Commands',
      'git': 'Git Operations'
    };

    Object.entries(expectedCategories).forEach(([dir, categoryName]) => {
      const categoryPath = path.join(this.dictionaryDir, dir);

      this.test(`Category directory exists: ${dir}`, () => {
        if (!fs.existsSync(categoryPath)) {
          throw new Error(`Category directory not found: ${dir}`);
        }
      });

      if (fs.existsSync(categoryPath)) {
        const files = fs.readdirSync(categoryPath).filter(f => f.endsWith('.md'));

        this.test(`Category ${dir} has command files`, () => {
          if (files.length === 0) {
            throw new Error(`No command files in category: ${dir}`);
          }
        });

        files.forEach(file => {
          const filePath = path.join(categoryPath, file);
          const content = fs.readFileSync(filePath, 'utf8');

          this.test(`${dir}/${file} has correct category declaration`, () => {
            const categoryMatch = content.match(/\*\*Category\*\*:\s*(.+)/);
            if (!categoryMatch) {
              throw new Error('Category field not found');
            }

            const declaredCategory = categoryMatch[1].trim();
            if (declaredCategory !== categoryName) {
              throw new Error(`Category mismatch: declared "${declaredCategory}", expected "${categoryName}"`);
            }
          });
        });
      }
    });
  }

  testCommandExamples() {
    console.log('📝 Testing command examples...');

    const commandFiles = glob.sync('dictionary/**/*.md', { cwd: this.rootDir });

    commandFiles.forEach(file => {
      const filePath = path.join(this.rootDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      const fileName = path.basename(file);

      this.test(`${fileName} has example prompts`, () => {
        const exampleSection = content.match(/## Example Prompts\n\n([\s\S]*?)(?=\n##|$)/);
        if (!exampleSection) {
          throw new Error('Example Prompts section not found');
        }

        const examples = exampleSection[1];
        const bulletPoints = examples.match(/^- /gm);

        if (!bulletPoints || bulletPoints.length < 2) {
          throw new Error('Need at least 2 example prompts');
        }
      });

      this.test(`${fileName} examples use backticks properly`, () => {
        const exampleSection = content.match(/## Example Prompts\n\n([\s\S]*?)(?=\n##|$)/);
        if (exampleSection) {
          const examples = exampleSection[1];
          const backtickMatches = examples.match(/`[^`]+`/g);

          if (backtickMatches) {
            backtickMatches.forEach(match => {
              const inner = match.slice(1, -1);
              if (inner.trim().length === 0) {
                throw new Error('Empty backtick content found');
              }
            });
          }
        }
      });
    });
  }

  testOutputFormats() {
    console.log('📄 Testing output formats...');

    const commandFiles = glob.sync('dictionary/**/*.md', { cwd: this.rootDir });

    commandFiles.forEach(file => {
      const filePath = path.join(this.rootDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      const fileName = path.basename(file);

      this.test(`${fileName} has output format specification`, () => {
        // Find the Expected Output Format section - stop at next top-level section that's not inside a code block
        const lines = content.split('\n');
        let startIdx = -1;
        let endIdx = lines.length;

        for (let i = 0; i < lines.length; i++) {
          if (lines[i] === '## Expected Output Format') {
            startIdx = i;
            break;
          }
        }

        if (startIdx === -1) {
          throw new Error('Expected Output Format section not found');
        }

        // Find the end of the section - look for next ## section that's not inside a code block
        let inCodeBlock = false;
        for (let i = startIdx + 1; i < lines.length; i++) {
          if (lines[i].startsWith('```')) {
            inCodeBlock = !inCodeBlock;
          } else if (!inCodeBlock && lines[i].match(/^## [^#]/)) {
            endIdx = i;
            break;
          }
        }

        const sectionLines = lines.slice(startIdx + 1, endIdx);
        const formatContent = sectionLines.join('\n').trim();

        if (formatContent.length < 50) {
          throw new Error('Output format specification too brief');
        }
      });

      this.test(`${fileName} output format includes code blocks`, () => {
        // Find the Expected Output Format section - stop at next top-level section that's not inside a code block
        const lines = content.split('\n');
        let startIdx = -1;
        let endIdx = lines.length;

        for (let i = 0; i < lines.length; i++) {
          if (lines[i] === '## Expected Output Format') {
            startIdx = i;
            break;
          }
        }

        if (startIdx === -1) {
          return; // No Expected Output Format section
        }

        // Find the end of the section - look for next ## section that's not inside a code block
        let inCodeBlock = false;
        for (let i = startIdx + 1; i < lines.length; i++) {
          if (lines[i].startsWith('```')) {
            inCodeBlock = !inCodeBlock;
          } else if (!inCodeBlock && lines[i].match(/^## [^#]/)) {
            endIdx = i;
            break;
          }
        }

        const sectionLines = lines.slice(startIdx + 1, endIdx);
        const formatContent = sectionLines.join('\n');

        // Count triple backticks - should have at least 2 (opening and closing)
        const backtickCount = (formatContent.match(/```/g) || []).length;
        if (backtickCount < 2) {
          throw new Error('Output format should include code block examples');
        }
      });
    });
  }

  testRelatedCommandLinks() {
    console.log('🔗 Testing related command links...');

    const commandFiles = glob.sync('dictionary/**/*.md', { cwd: this.rootDir });

    commandFiles.forEach(file => {
      const filePath = path.join(this.rootDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      const fileName = path.basename(file);

      // Check if file has Related Commands section
      if (content.includes('## Related Commands')) {
        this.test(`${fileName} related command links are valid`, () => {
          const relatedSection = content.match(/## Related Commands\n\n([\s\S]*?)(?=\n##|$)/);
          if (relatedSection) {
            const linksContent = relatedSection[1];
            const links = linksContent.match(/\[([^\]]+)\]\(([^)]+)\)/g);

            if (links) {
              links.forEach(link => {
                const [, linkText, linkPath] = link.match(/\[([^\]]+)\]\(([^)]+)\)/);

                if (linkPath.startsWith('../')) {
                  const resolvedPath = path.resolve(path.dirname(filePath), linkPath);
                  if (!fs.existsSync(resolvedPath)) {
                    throw new Error(`Broken related command link: ${linkPath}`);
                  }
                }
              });
            }
          }
        });
      }
    });
  }

  reportResults() {
    console.log('\n📊 Command Structure Test Results:');
    console.log('===================================');

    if (this.failed === 0) {
      console.log(`✅ All ${this.passed} tests passed! Command structure is valid.`);
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
  }
}

// Run tests if called directly
if (require.main === module) {
  const tester = new CommandStructureTest();
  const success = tester.runTests();
  process.exit(success ? 0 : 1);
}

module.exports = CommandStructureTest;
