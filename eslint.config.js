// eslint.config.js
const security = require("eslint-plugin-security");
const prettier = require("eslint-config-prettier");

module.exports = [
  security.configs.recommended,
  prettier,
  {
    rules: {
      semi: "error",
      "prefer-const": "error",
    },
  },
];
