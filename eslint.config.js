// @ts-check
import { defineConfig } from 'eslint/config'
import tseslint from 'typescript-eslint'
import eslint from '@eslint/js'

export default defineConfig(
  // ignore generated output
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/coverage/**',
    ],
  },

  // base configs
  eslint.configs.recommended,
  tseslint.configs.recommended,
  tseslint.configs.strict,
  tseslint.configs.stylistic,

  // overrides
  {
    rules: {
      'no-console': 'off',
    },
  },

  // ts overrides
  {
    files: ['**/*.{ts,tsx}'],
    rules: {
      '@typescript-eslint/no-unused-vars': [
        'warn',
        { argsIgnorePattern: '^_' },
      ],
    },
  }
)
