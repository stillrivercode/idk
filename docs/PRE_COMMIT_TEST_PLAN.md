# Pre-commit Configuration Test Plan

## Overview

This document outlines the comprehensive testing strategy for pre-commit configuration distribution and setup functionality
in the Agentic Workflow Template.

## Test Scope

### In Scope

- Pre-commit configuration file distribution
- Pre-commit hook installation and setup
- Configuration file validation
- Version compatibility testing
- Error handling and edge cases
- Documentation accuracy

### Out of Scope

- Individual hook execution (covered by pre-commit framework)
- Performance testing of large repositories
- Multi-platform compatibility (focus on Unix-like systems)

## Test Categories

### 1. Configuration Distribution Tests

#### 1.1 File Existence and Structure

- **Objective**: Verify that `.pre-commit-config.yaml` exists and has correct structure
- **Test Cases**:
  - Configuration file exists in template root
  - YAML syntax is valid
  - Required hooks are present
  - Hook configurations are properly formatted
- **Expected Results**: All configuration files are valid and complete

#### 1.2 File Content Validation

- **Objective**: Ensure configuration contains all required hooks and settings
- **Test Cases**:
  - General file checks (trailing-whitespace, end-of-file-fixer, etc.)
  - Markdown formatting (markdownlint)
  - YAML formatting (yamllint)
  - Python formatting (black, isort, ruff)
  - Security scanning (detect-secrets, bandit)
- **Expected Results**: All essential hooks are configured correctly

### 2. Installation Process Tests

#### 2.1 Standard Installation

- **Objective**: Test normal pre-commit setup during template installation
- **Test Cases**:
  - Pre-commit available in PATH
  - Hook installation succeeds
  - Git hooks directory is created
  - Hook scripts are executable
- **Expected Results**: Pre-commit hooks are properly installed

#### 2.2 Missing Dependencies

- **Objective**: Test behavior when pre-commit is not available
- **Test Cases**:
  - Pre-commit command not found
  - Python not available
  - Git repository not initialized
- **Expected Results**: Graceful degradation with appropriate warnings

#### 2.3 Development vs Production Setup

- **Objective**: Test different installation modes
- **Test Cases**:
  - `--dev` flag enables pre-commit setup
  - Production mode skips pre-commit setup
  - Development dependencies are handled correctly
- **Expected Results**: Appropriate setup based on installation mode

### 3. Hook Execution Simulation

#### 3.1 Hook Trigger Tests

- **Objective**: Verify hooks would execute on appropriate file types
- **Test Cases**:
  - Python files trigger formatting hooks
  - Markdown files trigger linting
  - YAML files trigger validation
  - JSON files trigger syntax checking
- **Expected Results**: Hooks are triggered for correct file types

#### 3.2 Hook Configuration Tests

- **Objective**: Test hook-specific configurations
- **Test Cases**:
  - Black profile compatibility with isort
  - Ruff auto-fix capabilities
  - Yamllint custom configuration
  - Bandit security level settings
- **Expected Results**: Hooks work together without conflicts

### 4. Version Compatibility Tests

#### 4.1 Hook Version Validation

- **Objective**: Ensure hook versions are compatible and up-to-date
- **Test Cases**:
  - Version format validation (semver patterns)
  - Minimum version requirements
  - Version compatibility matrix
- **Expected Results**: All versions are valid and compatible

#### 4.2 Pre-commit Framework Compatibility

- **Objective**: Test compatibility with different pre-commit versions
- **Test Cases**:
  - Minimum pre-commit version (documented)
  - Configuration syntax compatibility
  - Hook stage support
- **Expected Results**: Configuration works with supported pre-commit versions

### 5. Error Handling Tests

#### 5.1 Configuration Errors

- **Objective**: Test handling of invalid configurations
- **Test Cases**:
  - Malformed YAML syntax
  - Invalid hook IDs
  - Missing repository URLs
  - Incorrect version specifications
- **Expected Results**: Clear error messages and graceful failure

#### 5.2 Runtime Errors

- **Objective**: Test handling of execution errors
- **Test Cases**:
  - Network connectivity issues
  - Permission errors
  - Disk space limitations
- **Expected Results**: Appropriate error handling and recovery

### 6. Documentation Tests

#### 6.1 Documentation Accuracy

- **Objective**: Verify documentation matches implementation
- **Test Cases**:
  - Installation instructions are correct
  - Skip instructions are documented
  - Minimum version requirements are stated
  - Troubleshooting guides are helpful
- **Expected Results**: Documentation is accurate and complete

#### 6.2 Example Validation

- **Objective**: Ensure examples in documentation work
- **Test Cases**:
  - Skip hook examples function correctly
  - Manual installation commands work
  - Configuration customization examples are valid
- **Expected Results**: All examples are functional

## Test Data Requirements

### Sample Files

- Valid Python files with various formatting issues
- Markdown files with linting violations
- YAML files with syntax errors
- JSON files with formatting problems
- Files with secrets for detection testing

### Test Environments

- Clean git repositories
- Repositories with existing commits
- Repositories with existing pre-commit configurations
- Non-git directories

## Test Execution Strategy

### Automated Testing

- Shell script tests for file distribution
- Python tests for configuration validation
- Integration tests for full installation process
- Continuous integration test suite

### Manual Testing

- Cross-platform compatibility verification
- User experience testing
- Documentation review
- Edge case exploration

## Success Criteria

### Functional Requirements

- ✅ All configuration files distribute correctly
- ✅ Pre-commit hooks install without errors
- ✅ Hook configurations are syntactically valid
- ✅ All essential hooks are included
- ✅ Error conditions are handled gracefully

### Quality Requirements

- ✅ Test coverage > 90% for distribution logic
- ✅ All edge cases have corresponding tests
- ✅ Documentation is complete and accurate
- ✅ Performance is acceptable for typical usage

### Usability Requirements

- ✅ Installation process is intuitive
- ✅ Error messages are clear and actionable
- ✅ Skip options are well-documented
- ✅ Troubleshooting information is available

## Test Schedule

### Phase 1: Core Functionality (Immediate)

- Configuration distribution tests
- Basic installation tests
- File validation tests

### Phase 2: Integration Testing (Next)

- End-to-end installation tests
- Error handling tests
- Documentation validation

### Phase 3: Edge Cases and Polish (Final)

- Performance testing
- Cross-platform validation
- User acceptance testing

## Risk Assessment

### High Risk

- Pre-commit framework changes breaking compatibility
- Hook version conflicts causing installation failures
- Configuration syntax changes requiring updates

### Medium Risk

- Documentation becoming outdated
- New hook requirements not being tested
- Platform-specific installation issues

### Low Risk

- Minor formatting differences
- Performance variations
- Non-critical hook failures

## Mitigation Strategies

### Automated Validation

- Regular hook version updates
- Automated configuration syntax checking
- Continuous integration testing

### Documentation Maintenance

- Regular documentation reviews
- Example validation in CI
- User feedback incorporation

### Compatibility Management

- Version pinning for stable configurations
- Compatibility matrix maintenance
- Migration guides for breaking changes

## Test Artifacts

### Test Scripts

- `test_precommit_distribution.sh` - Main distribution testing
- `test_precommit_installation.py` - Installation process testing
- `test_hook_configuration.py` - Hook-specific configuration testing

### Documentation

- This test plan document
- Test execution reports
- Bug reports and resolution tracking

### Configuration Files

- Sample valid configurations
- Invalid configuration examples
- Test data files for hook validation

## Continuous Improvement

### Metrics Tracking

- Test execution time
- Test failure rates
- Coverage metrics
- User-reported issues

### Regular Reviews

- Monthly test plan reviews
- Quarterly compatibility assessments
- Annual strategy evaluations

### Feedback Integration

- User experience feedback
- Developer workflow insights
- Community best practices adoption
