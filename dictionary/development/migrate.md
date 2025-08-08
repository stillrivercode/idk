# migrate

**Category**: Development Commands

**Definition**: Generates a structured, phased migration plan for migrating a codebase, such as upgrading a framework, library, or language version.

## Parameters

- **`--from <current_version>`**: (Required) The current version of the technology being used. Version format should be as specific as possible (e.g., `2.7.0`, `17.0.0`, `3.8`) and may follow semantic versioning where applicable. The accepted format is dependent on the specified `--tech`.
- **`--to <target_version>`**: (Required) The target version to migrate to. Use the same format as `--from` for consistency.
- **`--tech <technology_name>`**: (Required) The name of the technology being migrated (e.g., `SpringBoot`, `Python`, `Django`, `React`).
- **`--repo <path_to_repo>`**: (Optional) The path to the repository to be migrated. If not provided, the current directory is assumed.
- **`--phases <number>`**: (Optional) Number of phases to break the migration into (default: 3).
  Specifying more than the default will generate additional placeholder phase sections in the plan,
  allowing teams to manually break down complex tasks further. Useful for large migrations requiring
  more granular planning.

## Description

The `migrate` command analyzes the requirements for a technology migration and generates a comprehensive, phased migration plan. This approach breaks down complex migrations into manageable phases, reducing risk and allowing for incremental progress with validation checkpoints.

**Important Note:** The generated plan is a comprehensive template based on our knowledge base
for the specified technology and established best practices. It is designed to be a powerful
starting point, but it requires careful review and adaptation by the development team to fit
the unique complexities of their codebase. The tool serves as an aid to guide the migration
process, not as a replacement for engineering expertise.

The generated plan will be a markdown document that includes:

1. **Migration Overview & Strategy:**
    - Executive summary of the migration scope and timeline
    - Risk assessment and mitigation strategies
    - Phase breakdown with clear success criteria for each phase
    - Inclusion of links to official migration guides, release notes, and relevant documentation

2. **Pre-migration Preparation:**
    - A checklist of common breaking changes and deprecated APIs, compiled from official release notes, to guide the team's impact analysis
    - A checklist for creating a baseline (e.g., ensuring the current test suite is green, performance benchmarking)
    - Team communication and coordination requirements
    - Rollback strategy and contingency planning

3. **Phased Migration Plan:**
    - **Phase 1**: Foundation & Dependencies (low-risk infrastructure changes)
    - **Phase 2**: Core Implementation (main migration work with breaking changes)
    - **Phase 3**: Optimization & Cleanup (performance improvements and cleanup tasks)
    - Each phase includes:
      - Detailed sequence of actions to perform
      - Code modification steps (e.g., updating dependencies, running codemods)
      - Configuration changes
      - Database schema migrations, if applicable
      - Validation checkpoints and success criteria

4. **Post-migration Verification:**
    - Comprehensive checklist for verifying the success of each phase
    - Running tests and linters after each phase
    - Manual verification steps for critical user flows
    - Performance comparison against the baseline
    - Production deployment considerations

5. **Rollback & Recovery Plans:**
    - Phase-specific rollback procedures
    - Steps to revert the migration in case of critical failure
    - Data recovery procedures if applicable

## Example Prompts

- `idk migrate --tech SpringBoot --from 2.7.0 --to 3.2.0`
- `idk migrate --tech Python --from 3.8 --to 3.11 --repo ./my-python-app`
- `idk migrate --tech SpringBoot --from 2.7.0 --to 3.2.0 --phases 4`

## Expected Output Format

```markdown
# Phased Migration Plan: Spring Boot 2.7.0 to 3.2.0

## 📋 Migration Overview & Strategy

**Migration Scope:** Spring Boot framework upgrade from 2.7.0 to 3.2.0
**Estimated Timeline:** 4-6 weeks (Note: This is a rough estimate. Please adjust based on your team's capacity and the specific complexity of the repository)
**Risk Level:** High (major version upgrade with Jakarta EE namespace changes)

### Phase Breakdown
- **Phase 1 (Week 1-2):** Foundation & Dependencies - Update build tools, analyze dependencies
- **Phase 2 (Week 3-4):** Core Implementation - Spring Boot upgrade and namespace changes
- **Phase 3 (Week 5-6):** Optimization & Cleanup - Performance improvements, cleanup

### Success Criteria
- All existing functionality preserved
- Test suite maintains >95% coverage
- Application startup time within 10% of baseline
- All security vulnerabilities addressed

---

## 🛠 Pre-migration Preparation

### ✅ Baseline Checklist
- [ ] Ensure all tests in the suite are passing on the `main` branch
- [ ] Record baseline performance metrics (startup time, memory usage, response times)
- [ ] Document current Spring Boot configuration and custom beans
- [ ] Audit all dependencies for Spring Boot 3.x compatibility
- [ ] Create a dedicated migration branch: `git checkout -b feat/spring-boot-3-upgrade`
- [ ] Create a baseline backup branch from the starting commit: `git branch backup/spring-boot-2-baseline` for emergency rollbacks

### 📚 Breaking Changes & Official Guides
- **Official Spring Boot 3.0 Migration Guide:** [https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)
- **Key Breaking Changes:**
  - Jakarta EE namespace migration (javax.* → jakarta.*)
  - Minimum Java 17 requirement
  - Spring Security 6.0 changes
  - Configuration property changes
  - Actuator endpoint changes

### 🔄 Rollback Strategy
- Keep Spring Boot 2.7 branch as fallback: `git branch backup/spring-boot-2-baseline`
- Backup current application.yml/properties files
- Document rollback procedure for each phase

---

## 🚀 Phase 1: Foundation & Dependencies (Low Risk)

**Goal:** Prepare development environment and analyze dependency compatibility

### Phase 1 Tasks:

1. **Java Runtime Update:**
   ```bash
   # Update to Java 17 (minimum requirement for Spring Boot 3.x)
   # Update JAVA_HOME and build configuration
   ```

1. **Update Environment Configuration:**
   - [ ] Ensure all developers have JDK 17 installed and configured in their IDEs
   - [ ] Update `JAVA_HOME` environment variables on all development machines
   - [ ] Update CI/CD pipeline configurations (e.g., `Jenkinsfile`, `gitlab-ci.yml`, GitHub Actions) to use a JDK 17 build environment
   - [ ] Update Docker base images if applicable to use Java 17

1. **Dependency Analysis:**

   ```bash
   # Run dependency analysis to identify incompatible libraries
   ./mvnw dependency:tree
   ./mvnw versions:display-dependency-updates
   ```

1. **Build Configuration Updates:**

   ```xml
   <!-- Update Maven configuration -->
   <properties>
       <maven.compiler.source>17</maven.compiler.source>
       <maven.compiler.target>17</maven.compiler.target>
       <java.version>17</java.version>
   </properties>
   ```

1. **Update Build Plugins:**

   ```xml
   <plugin>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-maven-plugin</artifactId>
       <version>3.2.0</version>
   </plugin>
   ```

### Phase 1 Validation

- [ ] Project compiles with Java 17
- [ ] Build process completes without errors
- [ ] All dependency compatibility issues identified
- [ ] Development environment configured correctly

**Phase 1 Rollback:** Revert Java version and build configuration changes

---

## ⚙️ Phase 2: Core Implementation (Breaking Changes)

**Goal:** Execute main Spring Boot 3.x upgrade with namespace and API migrations

### Phase 2 Tasks

1. **Update Spring Boot Version:**

   ```xml
   <parent>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-parent</artifactId>
       <version>3.2.0</version>
       <relativePath/>
   </parent>
   ```

2. **Jakarta EE Namespace Migration:**

   ```java
   // Before (javax)
   import javax.persistence.Entity;
   import javax.servlet.http.HttpServletRequest;
   import javax.validation.constraints.NotNull;

   // After (jakarta)
   import jakarta.persistence.Entity;
   import jakarta.servlet.http.HttpServletRequest;
   import jakarta.validation.constraints.NotNull;
   ```

   **Note:** Modern IDEs like IntelliJ IDEA Ultimate provide powerful, automated refactoring tools for this namespace migration that can handle complex cases more safely than manual find-and-replace operations.

3. **Update Spring Security Configuration:**

   ```java
   // Before (Using deprecated WebSecurityConfigurerAdapter)
   // @Configuration
   // public class SecurityConfig extends WebSecurityConfigurerAdapter {
   //     @Override
   //     protected void configure(HttpSecurity http) throws Exception {
   //         http.authorizeRequests().anyRequest().authenticated().and().formLogin();
   //     }
   // }

   // After (Using SecurityFilterChain bean - Spring Security 6.x+)
   @Configuration
   @EnableWebSecurity
   public class SecurityConfig {

       @Bean
       public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
           http
               .authorizeHttpRequests(authorize -> authorize
                   .anyRequest().authenticated()
               )
               .formLogin(Customizer.withDefaults());
           return http.build();
       }
   }
   ```

4. **Configuration Properties Updates:**

   ```yaml
   # Update application.yml for Spring Boot 3.x property changes
   spring:
     datasource:
       # Updated property names and structure
   ```

5. **Update Dependencies:**

   ```xml
   <!-- Update all Spring Boot starters and related dependencies -->
   <dependency>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-web</artifactId>
   </dependency>
   ```

### Phase 2 Validation

- [ ] Application starts successfully
- [ ] All REST endpoints function correctly
- [ ] Database connections and transactions work
- [ ] Security configuration is functional
- [ ] Test suite passes with 100% success rate (any failing tests must be either fixed or consciously deprecated/removed as part of the migration effort)
- [ ] No deprecated API warnings

**Phase 2 Rollback:** Revert to Phase 1 state and downgrade Spring Boot version

---

## 🎯 Phase 3: Optimization & Cleanup (Enhancement)

**Goal:** Leverage Spring Boot 3.x features and optimize performance

### Phase 3 Tasks

1. **Implement Spring Boot 3.x Features:**
   - Enable native compilation support (GraalVM)
   - Utilize improved observability features
   - Implement new Micrometer metrics

2. **Performance Optimization:**

   ```java
   // Leverage new performance improvements
   @Configuration
   public class PerformanceConfig {

       @Bean
       @ConditionalOnProperty("app.native-image")
       public RuntimeHintsRegistrar customHints() {
           // Native compilation hints
       }
   }
   ```

3. **Code Modernization:**
   - Update to use Records where appropriate
   - Implement new Spring Boot 3.x patterns
   - Utilize improved auto-configuration

4. **Security Enhancements:**
   - Review and implement new security features
   - Update authentication/authorization patterns
   - Audit security configurations

### Phase 3 Validation

- [ ] Performance metrics improved over baseline
- [ ] Memory usage optimized
- [ ] Security posture enhanced
- [ ] Code quality metrics improved
- [ ] Documentation updated

**Phase 3 Rollback:** Revert optimization changes while keeping core Spring Boot 3.x upgrade

---

## ✅ Post-Migration Verification

### Comprehensive Testing

- [ ] Full regression test suite execution
- [ ] Integration testing with external services
- [ ] Load testing and performance benchmarking
- [ ] Security penetration testing
- [ ] Database migration validation

### Production Deployment

- [ ] Staging environment deployment and testing
- [ ] Blue-green deployment strategy
- [ ] Database backup and migration procedures
- [ ] Monitoring and alerting configuration
- [ ] Performance tracking post-deployment

### Documentation Updates

- [ ] Update development setup instructions
- [ ] Document new Spring Boot 3.x patterns and configurations
- [ ] Update API documentation
- [ ] Create migration retrospective document

---

## 🚨 Emergency Rollback Procedures

### Immediate Rollback (Critical Issues)

```bash
git checkout backup/spring-boot-2-baseline
./mvnw clean install -DskipTests
# Restore database from backup if necessary
# Update deployment configurations
```

### Partial Rollback by Phase

- **Phase 3 Rollback:** `git revert <phase-3-commits>` (safer for shared branches)
- **Phase 2 Rollback:** `git checkout backup/spring-boot-2-baseline && git reset --soft <phase-1-completion-commit>` (preserves uncommitted work)
- **Phase 1 Rollback:** `git checkout backup/spring-boot-2-baseline` (complete rollback to baseline)

### Data Recovery

- Restore database from pre-migration backup
- Configuration backups stored in `./migration-backups/` (**Security Warning:** Ensure this directory is added to `.gitignore` to prevent accidentally committing sensitive information like secrets or credentials)
- Revert infrastructure changes if applicable
