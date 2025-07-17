#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const glob = require('glob');
const { shouldSkipLink } = require('./lib/link-helper');

class DictionaryValidator {
  constructor() {
    this.errors = [];
    this.warnings = [];
    this.rootDir = path.dirname(__dirname);
    this.dictionaryDir = path.join(this.rootDir, 'dictionary');
    this.mainIndex = path.join(this.rootDir, 'information-dense-keywords.md');
  }

  validate() {
    console.log('🧪 Validating Information Dense Keywords Dictionary...\n');

    this.validateMainIndex();
    this.validateCommandFiles();
    this.validateLinksIntegrity();
    this.validateCommandStructure();
    this.validateChainingSyntax();

    this.reportResults();
    return this.errors.length === 0;
  }

  validateMainIndex() {
    console.log('📋 Validating main index file...');

    if (!fs.existsSync(this.mainIndex)) {
      this.errors.push('Main index file not found: information-dense-keywords.md');
      return;
    }

    const content = fs.readFileSync(this.mainIndex, 'utf8');

    // Check for required sections
    const requiredSections = [
      '# Information Dense Keywords Dictionary',
      '## Command Chaining',
      '## Core Commands',
      '## Quick Reference'
    ];

    requiredSections.forEach(section => {
      if (!content.includes(section)) {
        this.errors.push(`Missing required section: ${section}`);
      }
    });

    // Validate command links in main index
    const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
    let match;
    while ((match = linkPattern.exec(content)) !== null) {
      const [, linkText, linkPath] = match;
      if (linkPath.startsWith('dictionary/')) {
        const fullPath = path.join(this.rootDir, linkPath);
        if (!fs.existsSync(fullPath)) {
          this.errors.push(`Broken link in main index: ${linkPath}`);
        }
      }
    }

    console.log('✅ Main index validation complete');
  }

  validateCommandFiles() {
    console.log('📁 Validating command files...');

    const commandFiles = glob.sync('dictionary/**/*.md', { cwd: this.rootDir });

    if (commandFiles.length === 0) {
      this.errors.push('No command files found in dictionary directory');
      return;
    }

    commandFiles.forEach(file => {
      this.validateCommandFile(path.join(this.rootDir, file));
    });

    console.log(`✅ Validated ${commandFiles.length} command files`);
  }

  validateCommandFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const relativePath = path.relative(this.rootDir, filePath);

    // Required structure for command files
    const requiredElements = [
      { pattern: /^# .+/m, description: 'Command title (H1)' },
      { pattern: /\*\*Category\*\*:/m, description: 'Category field' },
      { pattern: /\*\*Definition\*\*:/m, description: 'Definition field' },
      { pattern: /## Example Prompts/m, description: 'Example Prompts section' },
      { pattern: /## Expected Output Format/m, description: 'Expected Output Format section' }
    ];

    requiredElements.forEach(({ pattern, description }) => {
      if (!pattern.test(content)) {
        this.errors.push(`${relativePath}: Missing ${description}`);
      }
    });

    // Validate category matches directory structure
    const categoryMatch = content.match(/\*\*Category\*\*:\s*(.+)/);
    if (categoryMatch) {
      const category = categoryMatch[1].trim();
      const dirCategory = this.getCategoryFromPath(relativePath);
      if (!this.categoriesMatch(category, dirCategory)) {
        this.warnings.push(`${relativePath}: Category "${category}" doesn't match directory structure`);
      }
    }

    // Validate code blocks are properly formatted
    const codeBlockPattern = /```(\w+)?\n([\s\S]*?)```/g;
    let codeMatch;
    while ((codeMatch = codeBlockPattern.exec(content)) !== null) {
      const [, language, code] = codeMatch;
      if (code.trim().length === 0) {
        this.warnings.push(`${relativePath}: Empty code block found`);
      }
    }
  }

  validateLinksIntegrity() {
    console.log('🔗 Validating link integrity...');

    const allFiles = glob.sync('**/*.md', { cwd: this.rootDir, ignore: 'node_modules/**' });

    allFiles.forEach(file => {
      const filePath = path.join(this.rootDir, file);
      const content = fs.readFileSync(filePath, 'utf8');

      // Find all markdown links
      const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
      let match;
      while ((match = linkPattern.exec(content)) !== null) {
        const [, linkText, linkPath] = match;

        // Skip external links and conceptual docs links, as they are not expected to exist in the repo.
        if (shouldSkipLink(linkPath)) {
          continue;
        }

        // Resolve relative paths
        const resolvedPath = path.resolve(path.dirname(filePath), linkPath);

        if (!fs.existsSync(resolvedPath)) {
          this.errors.push(`${file}: Broken internal link to ${linkPath}`);
        }
      }
    });

    console.log('✅ Link integrity validation complete');
  }

  validateCommandStructure() {
    console.log('🏗️  Validating command structure...');

    const mainContent = fs.readFileSync(this.mainIndex, 'utf8');
    const quickRefMatch = mainContent.match(/## Quick Reference\n\n([\s\S]*?)(?=\n---|\n##|$)/);

    if (!quickRefMatch) {
      this.errors.push('Quick Reference table not found in main index');
      return;
    }

    const quickRefContent = quickRefMatch[1];
    const tableRows = quickRefContent.split('\n').filter(line => line.includes('|') && !line.includes('--'));

    // Skip header row
    const commandRows = tableRows.slice(1);

    commandRows.forEach(row => {
      const columns = row.split('|').map(col => col.trim()).filter(col => col);
      if (columns.length >= 3) {
        const [command, purpose, category] = columns;

        // Validate command exists as file
        const commandFile = this.findCommandFile(command);
        if (!commandFile) {
          this.warnings.push(`Quick Reference: Command "${command}" not found in dictionary`);
        }
      }
    });

    console.log('✅ Command structure validation complete');
  }

  validateChainingSyntax() {
    console.log('🔗 Validating command chaining syntax...');

    const mainContent = fs.readFileSync(this.mainIndex, 'utf8');

    // Extract chaining examples
    const chainingSection = mainContent.match(/## Command Chaining\n\n([\s\S]*?)(?=\n---)/);
    if (!chainingSection) {
      this.errors.push('Command Chaining section not found');
      return;
    }

    const chainingContent = chainingSection[1];

    // Validate chaining keywords are present
    const chainingKeywords = ['then', 'and'];
    chainingKeywords.forEach(keyword => {
      if (!chainingContent.includes(keyword)) {
        this.warnings.push(`Chaining keyword "${keyword}" not demonstrated in examples`);
      }
    });

    // Validate chaining examples are properly formatted
    const examplePattern = /`([^`]+)`/g;
    let match;
    while ((match = examplePattern.exec(chainingContent)) !== null) {
      const example = match[1];
      if (example.includes(' then ') || example.includes(' and ')) {
        // This is a chaining example - validate it contains known commands
        const parts = example.split(/ then | and /);
        parts.forEach(part => {
          const commandMatch = part.match(/^\w+/);
          if (commandMatch) {
            const command = commandMatch[0];
            if (!this.isKnownCommand(command)) {
              this.warnings.push(`Unknown command in chaining example: "${command}"`);
            }
          }
        });
      }
    }

    console.log('✅ Command chaining validation complete');
  }

  getCategoryFromPath(filePath) {
    const parts = filePath.split('/');
    if (parts.length >= 2 && parts[0] === 'dictionary') {
      return parts[1];
    }
    return '';
  }

  categoriesMatch(declared, directory) {
    const categoryMap = {
      'Core Commands': 'core',
      'Git Operations': 'git',
      'Development Commands': 'development',
      'Documentation Commands': 'documentation',
      'Quality Assurance Commands': 'quality-assurance',
      'Workflow Commands': 'workflow'
    };

    return categoryMap[declared] === directory;
  }

  findCommandFile(commandName) {
    const searchName = commandName.toLowerCase().replace(/\s+/g, '-');
    const commandFiles = glob.sync('dictionary/**/*.md', { cwd: this.rootDir });

    return commandFiles.find(file => {
      const baseName = path.basename(file, '.md');
      return baseName === searchName || file.includes(searchName);
    });
  }

  isKnownCommand(command) {
    const knownCommands = [
      'analyze', 'debug', 'optimize', 'test', 'document', 'explain',
      'research', 'review', 'plan', 'spec', 'SELECT', 'CREATE', 'DELETE', 'FIX',
      'gh', 'commit', 'push', 'pr', 'comment'
    ];

    return knownCommands.some(known =>
      command.toLowerCase().includes(known.toLowerCase()) ||
      known.toLowerCase().includes(command.toLowerCase())
    );
  }

  reportResults() {
    console.log('\n📊 Validation Results:');
    console.log('========================');

    if (this.errors.length === 0 && this.warnings.length === 0) {
      console.log('✅ All validations passed! Dictionary is well-formed.');
    } else {
      if (this.errors.length > 0) {
        console.log(`❌ ${this.errors.length} error(s) found:`);
        this.errors.forEach(error => console.log(`   • ${error}`));
      }

      if (this.warnings.length > 0) {
        console.log(`⚠️  ${this.warnings.length} warning(s) found:`);
        this.warnings.forEach(warning => console.log(`   • ${warning}`));
      }
    }

    console.log(`\n📈 Summary: ${this.errors.length} errors, ${this.warnings.length} warnings`);
  }
}

// Run validator if called directly
if (require.main === module) {
  const validator = new DictionaryValidator();
  const success = validator.validate();
  process.exit(success ? 0 : 1);
}

module.exports = DictionaryValidator;
