#!/usr/bin/env bash
# Runs inside a packaging image: packages prime_server, then Valhalla, into /out.
# Usage: build-in-container.sh DEB|RPM (sources mounted read-only at /src)
set -o errexit -o pipefail -o nounset

gen=${1:?DEB or RPM}
prime_server_version=0.12.0
if [ -f /opt/rh/gcc-toolset-14/enable ]; then
  # shellcheck disable=SC1091
  source /opt/rh/gcc-toolset-14/enable
fi

git clone --quiet --depth 1 --branch "$prime_server_version" --recurse-submodules \
  --shallow-submodules https://github.com/kevinkreiser/prime_server /build/prime_server
cmake -S /build/prime_server -B /build/prime_server/build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_TESTS=OFF -DENABLE_WERROR=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_EXE_LINKER_FLAGS=-pie
cmake --build /build/prime_server/build
cmake --install /build/prime_server/build --strip --prefix /build/prime_server/stage
libdir=$(cd /build/prime_server/stage && find . -name 'libprime_server.so.*' -type f -printf '%h\n' | cut -c3-)
cmake -S /src/packaging/prime_server -B /build/prime_server/package -G Ninja \
  -DPRIME_SERVER_STAGE=/build/prime_server/stage -DPRIME_SERVER_LIBDIR="$libdir" \
  -DPRIME_SERVER_VERSION="$prime_server_version" -DPRIME_SERVER_LICENSE=/build/prime_server/LICENSE.md \
  -DCPACK_GENERATOR="$gen"
(cd /build/prime_server/package && cpack -G "$gen" -B /build/packages)

# installed so that Valhalla's packages get a dependency on it
case $gen in
  DEB) dpkg -i /build/packages/*.deb ;;
  RPM) rpm -i --nosignature /build/packages/*.rpm ;;
esac

cmake -S /src -B /build/valhalla -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
  -DBUILD_SHARED_LIBS=ON -DENABLE_RUST_TOOLS=ON -DENABLE_MAN_PAGES=ON -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_TESTS=OFF \
  -DENABLE_CCACHE=OFF -DENABLE_SINGLE_FILES_WERROR=OFF -DCPACK_GENERATOR="$gen" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_EXE_LINKER_FLAGS=-pie
cmake --build /build/valhalla
(cd /build/valhalla && cpack -G "$gen" -B /build/packages)

cp /build/packages/*."${gen,,}" /out/
chown "${HOST_UID:-0}:${HOST_GID:-0}" /out/*."${gen,,}"
