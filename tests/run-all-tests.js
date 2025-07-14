#!/usr/bin/env node

const DictionaryValidator = require('./dictionary-validator.test');
const CommandStructureTest = require('./command-structure.test');
const LinkValidationTest = require('./link-validation.test');
const CommandChainingTest = require('./command-chaining.test');

class TestRunner {
  constructor() {
    this.totalPassed = 0;
    this.totalFailed = 0;
    this.suites = [];
  }

  async runAllTests() {
    console.log('🧪 Information Dense Keywords Dictionary - Test Suite');
    console.log('====================================================\n');

    const testSuites = [
      { name: 'Dictionary Validation', runner: DictionaryValidator },
      { name: 'Command Structure', runner: CommandStructureTest },
      { name: 'Link Validation', runner: LinkValidationTest },
      { name: 'Command Chaining', runner: CommandChainingTest }
    ];

    for (const suite of testSuites) {
      console.log(`\n🎯 Running ${suite.name} Tests...`);
      console.log('='.repeat(50));

      const tester = new suite.runner();
      const success = suite.name === 'Dictionary Validation'
        ? tester.validate()
        : tester.runTests();

      this.suites.push({
        name: suite.name,
        success,
        passed: tester.passed || (success ? 1 : 0),
        failed: tester.failed || (success ? 0 : 1)
      });

      if (tester.passed !== undefined) {
        this.totalPassed += tester.passed;
      } else if (success) {
        this.totalPassed += 1;
      }

      if (tester.failed !== undefined) {
        this.totalFailed += tester.failed;
      } else if (!success) {
        this.totalFailed += 1;
      }
    }

    this.reportOverallResults();
    return this.totalFailed === 0;
  }

  reportOverallResults() {
    console.log('\n' + '='.repeat(60));
    console.log('📊 OVERALL TEST RESULTS');
    console.log('='.repeat(60));

    this.suites.forEach(suite => {
      const status = suite.success ? '✅' : '❌';
      const details = suite.passed !== undefined
        ? `(${suite.passed} passed, ${suite.failed} failed)`
        : '';

      console.log(`${status} ${suite.name} ${details}`);
    });

    console.log('\n' + '-'.repeat(40));

    if (this.totalFailed === 0) {
      console.log('🎉 ALL TESTS PASSED! 🎉');
      console.log('The Information Dense Keywords Dictionary is fully validated.');
    } else {
      console.log(`❌ ${this.totalFailed} test(s) failed, ${this.totalPassed} passed`);
      console.log('Please review the failed tests above and fix the issues.');
    }

    console.log(`\n📈 Summary: ${this.totalPassed} passed, ${this.totalFailed} failed`);

    // Test coverage summary
    console.log('\n📋 Test Coverage:');
    console.log('• Dictionary structure and format validation');
    console.log('• Command file structure and metadata');
    console.log('• Link integrity and cross-references');
    console.log('• Command chaining syntax and examples');
    console.log('• Category organization');
    console.log('• Output format specifications');

    if (this.totalFailed === 0) {
      console.log('\n✨ The dictionary is ready for use!');
    }
  }
}

// Run all tests if called directly
if (require.main === module) {
  const runner = new TestRunner();
  runner.runAllTests().then(success => {
    process.exit(success ? 0 : 1);
  }).catch(error => {
    console.error('Test runner error:', error);
    process.exit(1);
  });
}

module.exports = TestRunner;
