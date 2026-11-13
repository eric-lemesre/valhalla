#!/usr/bin/env bash
# Runs lintian (DEB) or rpmlint (RPM) on the built packages, in a container of the distribution.
# Usage: packaging/lint.sh debian-13|ubuntu-24.04|fedora-45|rocky-9 [packages dir]
set -o errexit -o pipefail -o nounset

dist=${1:?distribution}
here=$(cd "$(dirname "$0")" && pwd)
pkgs=$(realpath "${2:-$here/out/$dist}")

case $dist in
  debian-13) base=debian:trixie ;;
  ubuntu-24.04) base=ubuntu:24.04 ;;
  # rpmlint isn't in EPEL 9, Fedora's checks the same rules
  fedora-45 | rocky-9) base=fedora:45 ;;
  *) echo "unknown distribution: $dist" >&2; exit 2 ;;
esac

docker run --rm -v "$pkgs:/pkgs:ro" "$base" bash -c '
if command -v apt-get >/dev/null; then
  apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq lintian >/dev/null
  lintian --version && lintian --no-tag-display-limit /pkgs/*.deb
else
  dnf install -y -q rpmlint >/dev/null && rpmlint --version && rpmlint /pkgs/*.rpm
fi'
