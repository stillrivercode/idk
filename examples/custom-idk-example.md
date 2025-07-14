# Custom IDK Example

This example demonstrates how to create a custom Information Dense Keyword (IDK).

## 1. Create a new YAML file

Create a new YAML file in the `idks` directory. The filename should be the `keyword` in snake_case.

```bash
touch idks/my_custom_idk.yaml
```

## 2. Add the IDK content

Add the following content to the new YAML file. This structure allows the expansion engine to compose prompts.

```yaml
meta:
  id: "custom.MyCustomIdk"
  version: "0.1.0"
  status: "draft"
  authors: ["@your_github_username"]

keyword: "MyCustomIdk"
namespace: "custom"
brief: "A custom IDK for demonstration."
base_prompt: "Create a custom component"

features:
  - name: "with-logging"
    prompt_addition: "that includes detailed logging."
  - name: "with-caching"
    prompt_addition: "and implements a caching layer."

examples:
  - input: "idk SELECT MyCustomIdk"
    expands_to: "Create a custom component"
  - input: "idk SELECT MyCustomIdk with logging"
    expands_to: "Create a custom component that includes detailed logging."
  - input: "idk SELECT MyCustomIdk with logging and caching"
    expands_to: "Create a custom component that includes detailed logging and implements a caching layer."
```

## 3. Validate the new IDK

Run the validation script to ensure that the new IDK is valid.

```bash
./scripts/validate-idks.sh
```

If the validation script runs successfully, you have created a new custom IDK that can be used with the `idk SELECT` command.
