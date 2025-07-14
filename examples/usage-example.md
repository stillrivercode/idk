# IDK Usage Example

This example demonstrates how to use the Information Dense Keywords (IDKs) to generate documentation for a project.

## 1. Select the IDKs you need

For this example, we'll use the following IDKs:

- `001_user_authentication.yaml`
- `002_api_gateway.yaml`
- `003_database_schema.yaml`

## 2. Expand the IDKs

You can expand the IDKs using the CLI tool.

```bash
./scripts/idk.sh 001_user_authentication
```

This will output the expanded version of the IDK:

```
"Create a user authentication system with login, logout, and registration."
```

You can also expand multiple IDKs and combine them into a single document.

```bash
./scripts/idk.sh 001_user_authentication > project_documentation.md
./scripts/idk.sh 002_api_gateway >> project_documentation.md
./scripts/idk.sh 003_database_schema >> project_documentation.md
```

This will create a Markdown file with the following content:

```markdown
"Create a user authentication system with login, logout, and registration."
"Set up an API gateway with rate limiting and authentication."
"Create a database schema for a PostgreSQL database."
```
