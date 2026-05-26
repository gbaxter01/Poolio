const js = require("@eslint/js");
const globals = require("globals");

/** @type {import('eslint').Linter.FlatConfig[]} */
module.exports = [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2024,
      sourceType: "commonjs",
      globals: {
        ...globals.node,
      },
    },
    rules: {
      // Possible errors
      "no-console": "warn",
      "no-debugger": "error",
      "no-duplicate-imports": "error",

      // Best practices
      "eqeqeq": ["error", "always"],
      "no-var": "error",
      "prefer-const": "error",
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "no-use-before-define": ["error", { functions: false }],
      "consistent-return": "error",

      // Style
      "semi": ["error", "always"],
      "quotes": ["error", "double"],
      "indent": ["error", 2],
      "comma-dangle": ["error", "always-multiline"],
      "arrow-parens": ["error", "always"],
    },
  },
];