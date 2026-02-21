import type { Config } from 'prettier'

const config: Config = {
  arrowParens: 'avoid',
  bracketSpacing: true,
  endOfLine: 'lf',
  printWidth: 80,
  semi: false,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'es5',
  plugins: ['@ianvs/prettier-plugin-sort-imports'],
  importOrder: [
    '<BUILTIN_MODULES>',
    '^react',
    '^@supabase/',
    '<THIRD_PARTY_MODULES>',
    '^types$',
    '^@types',
    '^@[a-zA-Z0-9-]+/',
    '^@/.*$',
    '^\\.\\.?.*$',
    '\\.css$',
  ],
}

export default config
