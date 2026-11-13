#!/usr/bin/env bash
# Installs the built packages in a clean container and routes on a tile extract.
# Usage: packaging/test-install.sh debian-13|ubuntu-24.04|fedora-45|rocky-9 <tiles.tar> [packages dir]
set -o errexit -o pipefail -o nounset

dist=${1:?distribution}
tiles=$(realpath "${2:?tiles.tar of an extract around Le Mans, France}")
here=$(cd "$(dirname "$0")" && pwd)
pkgs=$(realpath "${3:-$here/out/$dist}")

case $dist in
  debian-13) base=debian:trixie ;;
  ubuntu-24.04) base=ubuntu:24.04 ;;
  fedora-45) base=fedora:45 ;;
  rocky-9) base=rockylinux/rockylinux:9 ;;
  *) echo "unknown distribution: $dist" >&2; exit 2 ;;
esac

docker run --rm -v "$pkgs:/pkgs:ro" -v "$tiles:/data/tiles.tar:ro" "$base" bash -c '
set -o errexit -o pipefail
if command -v apt-get >/dev/null; then
  apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends /pkgs/*.deb >/dev/null
else
  if grep -q "^ID=\"\?rocky" /etc/os-release; then dnf install -y -q epel-release >/dev/null; fi
  dnf install -y -q /pkgs/*.rpm >/dev/null
fi
echo "python3: $(command -v python3 || echo absent)"
for tool in valhalla_build_config valhalla_build_elevation valhalla_build_extract; do
  echo "$tool: $(head -c 4 "$(command -v $tool)" | tr -dc "[:print:]") $($tool --help >/dev/null && echo help-ok)"
done
valhalla_build_config --mjolnir-tile-extract /data/tiles.tar --mjolnir-tile-dir /nonexistent > /tmp/valhalla.json
valhalla_service /tmp/valhalla.json route \
  "{\"locations\":[{\"lat\":48.0061,\"lon\":0.1996},{\"lat\":47.6997,\"lon\":-0.0758}],\"costing\":\"auto\"}" \
  2>/dev/null | grep -o "\"summary\":{[^}]*}" | head -1
'
