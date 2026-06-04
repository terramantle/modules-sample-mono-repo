#!/usr/bin/env node
// Run semantic-release once per module, scoped to that module's directory.
//
// semantic-release-monorepo identifies each package and scopes commit analysis
// by reading the *process* working directory (not semantic-release's `cwd`
// option), so we must chdir into each module dir before invoking it. Each
// module therefore needs its own package.json (any name/version — Terraform
// ignores it; it only exists so the wrapper can locate the package).
//
// The tag is pushed by semantic-release core; the actual publish to Terramantle
// happens in the @semantic-release/exec publishCmd (.github/scripts/publish-to-terramantle.sh),
// which is idempotent.

import { readdirSync } from 'node:fs'
import { join, resolve } from 'node:path'
import semanticRelease from 'semantic-release'

const root = resolve(process.cwd())
const modulesDir = join(root, 'modules')
const dryRun = process.argv.includes('--dry-run')

const dirs = readdirSync(modulesDir, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)
  .sort()

let failed = false
for (const dir of dirs) {
  const cwd = join(modulesDir, dir)
  process.stdout.write(`\n::group::semantic-release: ${dir}\n`)
  try {
    process.chdir(cwd) // the monorepo wrapper scopes by the real process cwd
    await semanticRelease(
      {
        extends: 'semantic-release-monorepo',
        branches: ['main'],
        tagFormat: `${dir}@\${version}`,
        dryRun,
        plugins: [
          '@semantic-release/commit-analyzer',
          '@semantic-release/release-notes-generator',
          ['@semantic-release/exec', {
            publishCmd: `"${root}/.github/scripts/publish-to-terramantle.sh" "${dir}" "\${nextRelease.version}"`,
          }],
        ],
      },
      { cwd, env: { ...process.env, MODULE_DIR: dir } },
    )
  } catch (err) {
    console.error(`semantic-release failed for ${dir}:`, err)
    failed = true
  } finally {
    process.chdir(root)
  }
  process.stdout.write('::endgroup::\n')
}
process.exit(failed ? 1 : 0)
