#!/usr/bin/env bash
# Builds the Valhalla and prime_server packages for one distribution in a container.
# Usage: packaging/build.sh debian-13|ubuntu-24.04|fedora-45|rocky-9 [output dir]
set -o errexit -o pipefail -o nounset

dist=${1:?distribution: debian-13, ubuntu-24.04, fedora-45 or rocky-9}
here=$(cd "$(dirname "$0")" && pwd)
src=$(dirname "$here")
out=$(realpath -m "${2:-$here/out/$dist}")

case $dist in
  debian-13) base=debian:trixie gen=DEB ;;
  ubuntu-24.04) base=ubuntu:24.04 gen=DEB ;;
  fedora-45) base=fedora:45 gen=RPM ;;
  rocky-9) base=rockylinux/rockylinux:9 gen=RPM ;;
  *) echo "unknown distribution: $dist" >&2; exit 2 ;;
esac

image=valhalla-packaging:$dist
docker build -f "$here/${gen,,}.Dockerfile" --build-arg BASE="$base" -t "$image" "$here"
mkdir -p "$out"
rm -f "$out"/*.deb "$out"/*.rpm
docker run --rm -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$src:/src:ro" -v "$out:/out" "$image" /src/packaging/build-in-container.sh "$gen"
ls -l "$out"
