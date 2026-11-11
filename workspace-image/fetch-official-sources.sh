#!/usr/bin/env bash
set -euo pipefail

# Update this commit deliberately when upgrading the official ROS packages.
repository=https://github.com/jaxa/int-ball2_platform_works.git
commit=b24d13496f3dd2ac739070667d81e23eff1056cf
if [[ $# != 1 ]]; then
  echo "Usage: $0 <catkin-source-directory>" >&2
  exit 2
fi
destination="$1"
checkout=$(mktemp -d)
trap 'rm -rf -- "$checkout"' EXIT
git init -q "$checkout"
git -C "$checkout" remote add origin "$repository"
git -C "$checkout" fetch --depth 1 origin "$commit"
git -C "$checkout" checkout --detach FETCH_HEAD
[[ $(git -C "$checkout" rev-parse HEAD) == "$commit" ]]
mkdir -p "$destination"
# Preserve the existing development environment: messages and official samples.
cp -a "$checkout/platform_docker/sample_tests/user_programs/." "$destination/"
