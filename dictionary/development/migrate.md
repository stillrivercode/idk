# migrate

**Category**: Development Commands

**Definition**: Generates a structured plan for migrating a codebase, such as upgrading a framework, library, or language version.

## Parameters

- **`--from <current_version>`**: (Required) The current version of the technology being used (e.g., `react@17.0.0`, `python@3.8`).
- **`--to <target_version>`**: (Required) The target version to migrate to (e.g., `react@18.2.0`, `python@3.11`).
- **`--tech <technology_name>`**: (Required) The name of the technology being migrated (e.g., `React`, `Python`, `Django`).
- **`--repo <path_to_repo>`**: (Optional) The path to the repository to be migrated. If not provided, the current directory is assumed.

## Description

The `migrate` command analyzes the requirements for a technology migration and generates a comprehensive, step-by-step plan. This plan is designed to guide a developer through the migration process, minimizing risk and ensuring all necessary steps are covered.

The generated plan will be a markdown document that includes:

1. **Pre-migration Analysis:**
    - Automated search for official migration guides and release notes.
    - Identification of known breaking changes between the specified versions.
    - A checklist for creating a baseline (e.g., ensuring the current test suite is green, performance benchmarking).

2. **Step-by-Step Migration Plan:**
    - A detailed sequence of actions to perform the upgrade.
    - Code modification steps (e.g., updating dependencies, running codemods).
    - Configuration changes.
    - Database schema migrations, if applicable.

3. **Post-migration Verification:**
    - A checklist for verifying the success of the migration.
    - Running tests and linters.
    - Manual verification steps for critical user flows.
    - Performance comparison against the baseline.

4. **Rollback Plan:**
    - Steps to revert the migration in case of critical failure.

## Example Prompts

- `idk migrate --tech React --from 17.0.2 --to 18.2.0`
- `idk migrate --tech Python --from 3.8 --to 3.11 --repo ./my-python-app`

## Expected Output Format

```markdown
# Migration Plan: React 17.0.2 to 18.2.0

## 1. Pre-migration Analysis

### ✅ Baseline Checklist

- [ ] Ensure all tests in the suite are passing on the `main` branch.
- [ ] Record baseline performance metrics (e.g., Lighthouse score, bundle size).
- [ ] Create a new branch for the migration: `git checkout -b feat/react-18-upgrade`

### 📚 Breaking Changes & Guides

- **Official React 18 Upgrade Guide:** [https://react.dev/blog/2022/03/08/react-v18-upgrade-guide](https://react.dev/blog/2022/03/08/react-v18-upgrade-guide)
- **Key Breaking Change:** Automatic batching. Review components that rely on multiple state updates within a single event handler.

## 2. Migration Steps

1.  **Update Dependencies:**
    ```bash
    npm install react@18.2.0 react-dom@18.2.0
    ```
2.  **Update Client Rendering API:**
    -   Find the root `ReactDOM.render` call (usually in `index.js` or `main.js`).
    -   Replace it with the new `createRoot` API.

    **Before:**
    ```javascript
    import ReactDOM from 'react-dom';
    import App from './App';

    const rootElement = document.getElementById('root');
    ReactDOM.render(<App />, rootElement);
    ```

    **After:**
    ```javascript
    import ReactDOM from 'react-dom/client';
    import App from './App';

    const rootElement = document.getElementById('root');
    const root = ReactDOM.createRoot(rootElement);
    root.render(<App />);
    ```

## 3. Post-migration Verification

- [ ] Run the full test suite: `npm test`
- [ ] Run the linter: `npm run lint`
- [ ] Manually test critical user flows:
    - [ ] User login and logout.
    - [ ] Core application features.
- [ ] Compare performance metrics against the baseline.
```
