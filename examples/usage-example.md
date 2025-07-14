# IDK Usage Example

This example demonstrates how to use the Information Dense Keywords (IDKs) to generate prompts.

## 1. Basic Expansion

To expand a single IDK, use the `SELECT` verb.

```bash
idk SELECT UserAuthentication
```

This will output the base prompt for the `UserAuthentication` IDK.

## 2. Expansion with Features

To add features to the prompt, use the `with` and `and` keywords.

```bash
idk SELECT UserAuthentication with MFA and OAuth
```

This will generate a more complex prompt that includes requirements for Multi-Factor Authentication and OAuth.

## 3. Combining Multiple IDKs

While the CLI expands one IDK at a time, you can easily combine them in a script.

```bash
prompt=""
prompt+=$(idk SELECT UserAuthentication with MFA)
prompt+=$(idk SELECT ApiGateway with RateLimiting)
echo "$prompt"
```
