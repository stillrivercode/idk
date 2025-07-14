# Custom IDK Example

This example demonstrates how to create a custom Information Dense Keyword (IDK).

## 1. Create a new YAML file

Create a new YAML file in the `idks` directory. The filename should be in the format `NNN_your_idk_name.yaml`, where `NNN` is a unique number.

```bash
touch idks/021_my_custom_idk.yaml
```

## 2. Add the IDK content

Add the following content to the new YAML file:

```yaml
meta:
  id: "custom.MyCustomIdk"
  version: "0.1.0"
  status: "draft"
  authors: ["@your_github_username"]

keyword: "MyCustomIdk"
namespace: "custom"
brief: "This is a custom IDK."
tokens_saved: 5

definition:
  description: |
    This is a custom IDK that demonstrates how to create your own IDKs.
  parameters: []

examples:
  - input: "MyCustomIdk"
    expands_to: "This is the expanded version of my custom IDK."

tests:
  - description: "Ensures the custom IDK expands correctly."
    input: "MyCustomIdk"
    should_include: ["custom", "expanded"]

related: []
```

## 3. Validate the new IDK

Run the validation script to ensure that the new IDK is valid.

```bash
./scripts/validate-idks.sh
```

If the validation script runs successfully, you have created a new custom IDK.
