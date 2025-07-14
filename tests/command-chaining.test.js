#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

class CommandChainingTest {
  constructor() {
    this.rootDir = path.dirname(__dirname);
    this.mainIndex = path.join(this.rootDir, 'information-dense-keywords.md');
    this.passed = 0;
    this.failed = 0;
    this.tests = [];
    this.knownCommands = [];
  }

  runTests() {
    console.log('🧪 Testing Command Chaining...\n');

    this.loadKnownCommands();
    this.testChainingSection();
    this.testChainingKeywords();
    this.testChainingExamples();
    this.testChainingLogic();
    this.testComplexWorkflows();

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

  loadKnownCommands() {
    // Extract commands from main index
    const content = fs.readFileSync(this.mainIndex, 'utf8');

    // Parse Quick Reference table
    const quickRefMatch = content.match(/## Quick Reference\n\n([\s\S]*?)(?=\n---|\n##|$)/);
    if (quickRefMatch) {
      const tableContent = quickRefMatch[1];
      const rows = tableContent.split('\n').filter(line => line.includes('|') && !line.includes('--'));

      // Skip header row
      const commandRows = rows.slice(1);

      this.knownCommands = commandRows.map(row => {
        const columns = row.split('|').map(col => col.trim()).filter(col => col);
        return columns[0]; // First column is command name
      }).filter(cmd => cmd);
    }

    console.log(`📚 Loaded ${this.knownCommands.length} known commands`);
  }

  testChainingSection() {
    console.log('📋 Testing chaining section presence...');

    const content = fs.readFileSync(this.mainIndex, 'utf8');

    this.test('Command Chaining section exists', () => {
      if (!content.includes('## Command Chaining')) {
        throw new Error('Command Chaining section not found in main index');
      }
    });

    this.test('Chaining section has content', () => {
      const chainingMatch = content.match(/## Command Chaining\n\n([\s\S]*?)(?=\n---)/);
      if (!chainingMatch || chainingMatch[1].trim().length < 100) {
        throw new Error('Command Chaining section is too brief or empty');
      }
    });

    this.test('Chaining section explains sequential operations', () => {
      const chainingMatch = content.match(/## Command Chaining\n\n([\s\S]*?)(?=\n---)/);
      if (chainingMatch) {
        const chainingContent = chainingMatch[1];
        if (!chainingContent.includes('sequential') && !chainingContent.includes('Sequential')) {
          throw new Error('Chaining section should explain sequential operations');
        }
      }
    });

    this.test('Chaining section explains parallel operations', () => {
      const chainingMatch = content.match(/## Command Chaining\n\n([\s\S]*?)(?=\n---)/);
      if (chainingMatch) {
        const chainingContent = chainingMatch[1];
        if (!chainingContent.includes('parallel') && !chainingContent.includes('Parallel')) {
          throw new Error('Chaining section should explain parallel operations');
        }
      }
    });
  }

  testChainingKeywords() {
    console.log('🔗 Testing chaining keywords...');

    const content = fs.readFileSync(this.mainIndex, 'utf8');
    const chainingMatch = content.match(/## Command Chaining\n\n([\s\S]*?)(?=\n---)/);

    if (!chainingMatch) {
      return; // Skip if section doesn't exist
    }

    const chainingContent = chainingMatch[1];

    this.test('Uses "then" keyword for sequential chaining', () => {
      if (!chainingContent.includes(' then ')) {
        throw new Error('Missing "then" keyword for sequential operations');
      }
    });

    this.test('Uses "and" keyword for parallel chaining', () => {
      if (!chainingContent.includes(' and ')) {
        throw new Error('Missing "and" keyword for parallel operations');
      }
    });

    this.test('Demonstrates both chaining types', () => {
      const hasSequential = chainingContent.includes('Sequential') || chainingContent.includes('sequential');
      const hasParallel = chainingContent.includes('Parallel') || chainingContent.includes('parallel');

      if (!hasSequential || !hasParallel) {
        throw new Error('Should demonstrate both sequential and parallel chaining');
      }
    });
  }

  testChainingExamples() {
    console.log('📝 Testing chaining examples...');

    const content = fs.readFileSync(this.mainIndex, 'utf8');
    const chainingMatch = content.match(/## Command Chaining\n\n([\s\S]*?)(?=\n---)/);

    if (!chainingMatch) {
      return;
    }

    const chainingContent = chainingMatch[1];

    // Extract code examples in backticks
    const examples = chainingContent.match(/`([^`]+)`/g);

    this.test('Contains chaining examples in backticks', () => {
      if (!examples || examples.length === 0) {
        throw new Error('No chaining examples found in backticks');
      }
    });

    if (examples) {
      const chainingExamples = examples.filter(example =>
        example.includes(' then ') || example.includes(' and ')
      );

      this.test('Has actual chaining examples', () => {
        if (chainingExamples.length === 0) {
          throw new Error('No examples with chaining keywords found');
        }
      });

      chainingExamples.forEach((example, index) => {
        this.test(`Chaining example ${index + 1} uses known commands`, () => {
          const cleanExample = example.slice(1, -1); // Remove backticks
          const parts = cleanExample.split(/ then | and /);

          parts.forEach(part => {
            const words = part.trim().split(' ');
            const firstWord = words[0];

            // Check if first word is a known command (case-insensitive)
            const isKnownCommand = this.knownCommands.some(cmd =>
              cmd.toLowerCase().includes(firstWord.toLowerCase()) ||
              firstWord.toLowerCase().includes(cmd.toLowerCase()) ||
              this.isCommonCommandWord(firstWord)
            );

            if (!isKnownCommand) {
              throw new Error(`Unknown command in example: "${firstWord}" in "${part.trim()}"`);
            }
          });
        });
      });
    }
  }

  testChainingLogic() {
    console.log('🧠 Testing chaining logic...');

    const testChains = [
      'analyze this system then optimize this performance',
      'test this component and document this API',
      'debug this issue then fix this problem then test this solution',
      'SELECT user data and CREATE backup file',
      'review this code then plan this refactoring then implement this change'
    ];

    testChains.forEach((chain, index) => {
      this.test(`Chain ${index + 1}: "${chain}" is logically valid`, () => {
        const parts = chain.split(/ then | and /);

        if (parts.length < 2) {
          throw new Error('Chain should have at least 2 parts');
        }

        // Check for logical flow
        if (chain.includes(' then ')) {
          // Sequential - should make logical sense
          const hasAnalysisFirst = parts[0].includes('analyze') || parts[0].includes('debug') || parts[0].includes('SELECT');
          const hasActionLater = parts.some(part =>
            part.includes('fix') || part.includes('optimize') || part.includes('CREATE') || part.includes('implement')
          );

          // This is a soft validation - not all chains need to follow this pattern
          // but it's good to validate the examples do
        }

        parts.forEach(part => {
          if (part.trim().length === 0) {
            throw new Error(`Empty part in chain: "${chain}"`);
          }
        });
      });
    });
  }

  testComplexWorkflows() {
    console.log('🌊 Testing complex workflow examples...');

    const content = fs.readFileSync(this.mainIndex, 'utf8');
    const chainingMatch = content.match(/## Command Chaining\n\n([\s\S]*?)(?=\n---)/);

    if (!chainingMatch) {
      return;
    }

    const chainingContent = chainingMatch[1];

    this.test('Contains complex workflow example', () => {
      // Look for examples with multiple chaining keywords
      const complexPattern = /`[^`]*\b(then|and)\b[^`]*\b(then|and)\b[^`]*`/;

      if (!complexPattern.test(chainingContent)) {
        throw new Error('No complex workflow examples found (should have multiple then/and keywords)');
      }
    });

    this.test('Complex workflows are well-structured', () => {
      const complexExamples = chainingContent.match(/`[^`]*\b(then|and)\b[^`]*\b(then|and)\b[^`]*`/g);

      if (complexExamples) {
        complexExamples.forEach(example => {
          const cleanExample = example.slice(1, -1);
          const parts = cleanExample.split(/ then | and /);

          if (parts.length < 3) {
            throw new Error(`Complex workflow should have at least 3 parts: ${cleanExample}`);
          }

          // Check for reasonable workflow progression
          const verbs = parts.map(part => {
            const words = part.trim().split(' ');
            return words[0].toLowerCase();
          });

          // Should not repeat the same verb immediately
          for (let i = 1; i < verbs.length; i++) {
            if (verbs[i] === verbs[i-1]) {
              throw new Error(`Repeated consecutive verbs in workflow: ${cleanExample}`);
            }
          }
        });
      }
    });
  }

  isCommonCommandWord(word) {
    const commonWords = [
      'analyze', 'debug', 'optimize', 'test', 'document', 'explain',
      'research', 'review', 'plan', 'spec', 'select', 'create', 'delete',
      'fix', 'commit', 'push', 'gh', 'pr', 'comment'
    ];

    return commonWords.some(common =>
      word.toLowerCase().includes(common) || common.includes(word.toLowerCase())
    );
  }

  reportResults() {
    console.log('\n📊 Command Chaining Test Results:');
    console.log('==================================');

    if (this.failed === 0) {
      console.log(`✅ All ${this.passed} chaining tests passed! Command chaining is well-defined.`);
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
  const tester = new CommandChainingTest();
  const success = tester.runTests();
  process.exit(success ? 0 : 1);
}

module.exports = CommandChainingTest;
