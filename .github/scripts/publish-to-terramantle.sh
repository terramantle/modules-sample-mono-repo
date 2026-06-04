#!/usr/bin/env bash
#
# Idempotent publish of one module version to the Terramantle registry.
#
# Usage: publish-to-terramantle.sh <module-dir> <version>
#   e.g. publish-to-terramantle.sh eks-cluster-aws 1.2.3
#
# This is the single source of publish logic. It is invoked by
# semantic-release's @semantic-release/exec publishCmd (one call per released
# module) and reused by the reconcile workflow.
#
# Idempotency: semantic-release pushes the git tag BEFORE this step and does not
# roll it back on failure. So this script must be safe to re-run for a version
# that may already exist in the registry:
#   - if the version is already published  -> no-op success
#   - 409/422 (immutable version exists)    -> treat as success
#   - transient 5xx / network               -> retry with backoff
#   - failed scan / not consumable          -> fail (surfaces a bad module)
#
# Required env:
#   TM_ORG       Terramantle org slug
#   TM_REGISTRY  e.g. https://registry.terramantle.dev
#   TM_TOKEN     GitHub OIDC JWT (bearer) — minted by the workflow
#   GITHUB_WORKSPACE  repo root (set by GitHub Actions)

set -euo pipefail

dir="${1:?module-dir required}"
version="${2:?version required}"

: "${TM_ORG:?TM_ORG is required}"
: "${TM_REGISTRY:?TM_REGISTRY is required}"
: "${TM_TOKEN:?TM_TOKEN is required}"

root="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"
moddir="$root/modules/$dir"

[ -d "$moddir" ] || { echo "::error::module dir not found: $moddir"; exit 1; }

meta="$moddir/manifest.yaml"
[ -f "$meta" ] || { echo "::error::missing $meta"; exit 1; }

name=$(yq -r '.name' "$meta")
provider=$(yq -r '.provider' "$meta")
description=$(yq -r '.description // ""' "$meta")
if [ -z "$name" ] || [ "$name" = "null" ] || [ -z "$provider" ] || [ "$provider" = "null" ]; then
  echo "::error::$meta must define both 'name' and 'provider'"; exit 1
fi

base="$TM_REGISTRY/v1/modules/$TM_ORG/$name/$provider/$version"
auth=(-H "Authorization: Bearer $TM_TOKEN")

echo "→ ${name}/${provider}@${version} (from modules/$dir)"

# ── 1. Idempotency check — already published? ───────────────────────────────
# A prior run may have published this version but died before/while tagging.
get_code=$(curl -fsS -o /dev/null -w '%{http_code}' "${auth[@]}" "$base" || echo 000)
if [ "$get_code" = "200" ]; then
  echo "::notice::${name}/${provider}@${version} already in registry — nothing to do."
  exit 0
fi

# ── 2. Package the module root ──────────────────────────────────────────────
tarball="$(mktemp -d)/module.tar.gz"
tar -czf "$tarball" -C "$moddir" .

desc=$(printf '%s' "$description" | jq -sRr @uri)
put_url="${base}?description=${desc}&wait=true&timeout=15000"

# ── 3. PUT with retry on transient failures ─────────────────────────────────
attempt=0
max_attempts=3
body="$(mktemp)"
while :; do
  attempt=$((attempt + 1))
  code=$(curl -sS -o "$body" -w '%{http_code}' -X PUT "$put_url" \
    "${auth[@]}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"$tarball" || echo 000)

  echo "HTTP $code (attempt $attempt/$max_attempts)"; cat "$body"; echo

  case "$code" in
    2*)
      status=$(jq -r '.status // "published"' "$body" 2>/dev/null || echo unknown)
      consumable=$(jq -r '.consumable // "unknown"' "$body" 2>/dev/null || echo unknown)
      echo "::notice::Published ${name}/${provider}@${version} (status=$status, consumable=$consumable)"
      if [ "$status" = "failed" ] || [ "$consumable" = "false" ]; then
        echo "::error::Published but NOT consumable — scans or policy failed. See the registry."
        exit 1
      fi
      exit 0
      ;;
    409|422)
      # Version already exists and is immutable — an expected, idempotent no-op.
      echo "::notice::${name}/${provider}@${version} already published (immutable) — treating as success."
      exit 0
      ;;
    5*|000)
      if [ "$attempt" -ge "$max_attempts" ]; then
        echo "::error::Publish failed after $max_attempts attempts (last HTTP $code)"; exit 1
      fi
      sleep $((attempt * 3))
      ;;
    *)
      echo "::error::Publish failed with HTTP $code"; exit 1
      ;;
  esac
done
