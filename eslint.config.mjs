import { defineConfig, globalIgnores } from 'eslint/config';
import js from '@eslint/js';
import prettier from 'eslint-config-prettier';
import globals from 'globals';

export default defineConfig([
  globalIgnores([
    'frontend/app/assets/javascripts/fattable.js',
    'frontend/vendor/',
    'public/app/assets/javascripts/bootstrap-accessibility/',
    'public/vendor/assets/javascripts/',
  ]),
  js.configs.recommended,
  prettier,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'script',

      globals: {
        ...globals.browser,
        ...globals.jquery,
        AS: 'writable',
        CodeMirror: 'readonly',
      },
    },

    rules: {
      'no-undef': 'warn',
      'no-unused-vars': 'warn',
    },
  },
]);
