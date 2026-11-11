#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 2 || ! "$1" =~ ^coder-[a-zA-Z0-9-]+-home$ || "$2" != /mnt/* ]]; then
  echo "Usage: $0 coder-<workspace-id>-home /mnt/c/<backup-directory>" >&2
  exit 2
fi
volume="$1"
if [[ ! -d "$2" ]]; then
  echo "Create the backup destination on the mounted Windows drive first: $2" >&2
  exit 2
fi
destination="$2/$volume"
docker volume inspect "$volume" >/dev/null
if [[ -n "$(docker ps -q --filter "volume=$volume")" ]]; then
  echo "Stop the workspace before backing up: $volume" >&2
  exit 1
fi
mkdir -p "$destination"
archive="$destination/$(date -u +%Y%m%dT%H%M%SZ)-$$.tar.gz"
trap 'rm -f -- "$archive.partial"' EXIT
# Stop the workspace before running this script for a consistent backup.
# No host Docker socket or other users' backup directories enter the workspace.
docker run --rm --user 0 --network none --entrypoint tar \
  --mount "type=volume,source=$volume,target=/source,readonly" \
  intball2-workspace:noetic-v1 -czf - -C /source . > "$archive.partial"
gzip -t "$archive.partial"
mv -- "$archive.partial" "$archive"
echo "$archive"
