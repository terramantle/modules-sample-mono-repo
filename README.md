# modules-sample-mono-repo

A reference example of a **Terraform module monorepo** that publishes to
[Terramantle](https://terramantle.dev) over its VCS Trust integration. It's the repo
to copy from when you want many modules living in one git repo, each versioned
and released independently through GitHub Actions.

It's also a working demo: these modules are published into the Terramantle Demo
Org, and one of them (`insecure-rds-aws`) is deliberately insecure to show how
scanning and policy gating block a bad module.

> In the Terramantle app, this is documented under **Guides & Integrations →
> Mono-repo / VCS**. This README and that guide describe the same workflow.

---

## Layout

```
.
├── .github/
│   ├── workflows/
│   │   ├── publish-modules.yml   # commit-driven release (semantic-release)
│   │   ├── reconcile.yml         # manual self-heal (re-publish stuck tags)
│   │   └── checks.yml            # advisory pre-commit checks on PRs
│   └── scripts/
│       ├── release.mjs           # runs semantic-release per module
│       └── publish-to-terramantle.sh   # idempotent publish (release + reconcile)
├── .pre-commit-config.yaml   # terraform fmt + terraform-docs on commit
├── package.json              # release tooling (semantic-release + monorepo)
└── modules/
    └── <name>-<provider>/    # one directory per module
        ├── manifest.yaml     # module identity (name, provider, description)
        ├── package.json      # lets semantic-release scope commits to this module
        ├── README.md         # docs - TF_DOCS block auto-generated
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

Each module lives in `modules/<name>-<provider>/`. The directory name is just a
human label - the registry coordinates (`name`, `provider`) come from that
module's `manifest.yaml`, never from string-splitting the directory:

```yaml
# modules/eks-cluster-aws/manifest.yaml
name: eks-cluster
provider: aws
description: EKS cluster with managed node groups
```

Notice there is **no `version` field**. That's deliberate - the version is
computed from your commit history (see below). The per-module `package.json` is
boilerplate that exists only so `semantic-release` can identify each module and
scope commits to its directory - Terraform ignores it.

---

## Versioning & releases

**You never pick a version or push a tag by hand.** Releases are driven by your
commit messages, Lerna / semantic-release style. Merge
[Conventional-Commit](https://www.conventionalcommits.org) PRs to `main`, and CI
does the rest, **per module**:

1. For each `modules/<dir>`, find the commits that touched that directory since
   its last release tag.
2. Compute the next semantic version from those commits' types.
3. Publish the module to Terramantle at that version.
4. Tag the repo `<module-dir>@<version>` (e.g. `eks-cluster-aws@1.2.3`).

A commit that touches only `vpc-aws` bumps **only** `vpc` - each module versions
independently.

### Bump rules

| Commit                                            | Bump        |
| ------------------------------------------------- | ----------- |
| `feat: …`                                         | **minor**   |
| `fix: …` / `perf: …`                              | **patch**   |
| `feat!: …` or any type with `BREAKING CHANGE:`    | **major**   |
| `docs:` / `ci:` / `chore:` / `refactor:` / `test:`| no release  |

The first release of a module is always `1.0.0`.

### Releasing

Just merge to `main`:

```bash
git commit -m "feat(eks): add cluster autoscaler support"   # → eks-cluster/aws minor bump
git commit -m "fix(vpc): correct subnet cidr"               # → vpc/aws patch bump
git push origin main
```

CI computes each changed module's next version, publishes it, and pushes its tag.
Touch several modules in one push and each is released independently.

### How it works under the hood

`.github/scripts/release.mjs` runs `semantic-release` (with the
`semantic-release-monorepo` wrapper) once per module, scoped to that module's
directory. semantic-release computes the version, **pushes the git tag**, then
runs `.github/scripts/publish-to-terramantle.sh` to PUT the module to the registry.

semantic-release pushes the tag *before* publishing and doesn't roll it back on
failure, so the publish script is **idempotent**: if a version already exists in
the registry it's a no-op, and transient failures retry. If a publish ever fails
after its tag was pushed, run the **reconcile** workflow (Actions → reconcile) -
it re-publishes any tagged version missing from the registry. Registry versions
are immutable; the tag is the permanent release record.

---

## Authentication (OIDC, no secrets)

`publish-modules.yml` authenticates with GitHub Actions' native **OIDC** token -
there are no stored client secrets. For it to work, your Terramantle org must
trust this repo as a subject. In the app:

> **Organisation settings → VCS Trust** → add subject
> `repo:terramantle/modules-sample-mono-repo`

The workflow requests an OIDC JWT (`permissions: id-token: write`) with audience
`https://registry.terramantle.dev` and uses it as the bearer token on publish.

---

## Local development & docs

Module docs are generated by [terraform-docs](https://terraform-docs.io) via a
[pre-commit](https://pre-commit.com) hook, so each module's `README.md` stays in
sync with its `variables.tf` / `outputs.tf`.

```bash
pipx install pre-commit     # or: pip install pre-commit
pre-commit install          # once per clone
```

Now every `git commit` reformats `*.tf` and regenerates the
`<!-- BEGIN_TF_DOCS -->…<!-- END_TF_DOCS -->` block in each module README. The
same hooks run on pull requests via `checks.yml`, so a `git commit --no-verify`
is still caught. These checks are **advisory** - they don't gate publishing.

---

## Scanning & policy gating

Every published version is scanned (Trivy, KICS, TFLint) and evaluated against
your org's policies. `modules/insecure-rds-aws` is intentionally vulnerable -
hardcoded credentials, public accessibility, no encryption, no backups. Merge a
change to it (e.g. `fix(insecure-rds): …`) and watch it land in the registry but
be flagged **not consumable** - the release step fails by design until an owner
overrides or the policy passes. A clean module (e.g. `vpc-aws`) publishes
consumable.

---

## Forking this repo

The only value to change is the org slug at the top of
[`.github/workflows/publish-modules.yml`](.github/workflows/publish-modules.yml):

```yaml
env:
  TM_ORG: demo   # ← your Terramantle org slug
```

…and add your fork as a trusted subject under **VCS Trust** (see above).
