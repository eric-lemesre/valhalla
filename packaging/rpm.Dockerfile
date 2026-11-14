ARG BASE=fedora:45
FROM ${BASE}

# RHEL-like 9: geos, luajit, czmq, spatialite and libgeotiff come from EPEL, their -devel
# dependencies from CRB, GCC 11 is too old for C++20, hence gcc-toolset-14; protobuf 3.14 lacks
# the has_*() accessors and Boost 1.75 the geographic area strategy Valhalla uses, hence a static
# protobuf and Boost headers below
RUN if grep -q '^ID="\?fedora' /etc/os-release; then \
      dnf install -y boost-devel gcc gcc-c++ protobuf-compiler protobuf-devel; \
    else \
      dnf install -y dnf-plugins-core epel-release && dnf config-manager --set-enabled crb && \
      dnf install -y gcc-toolset-14-gcc gcc-toolset-14-gcc-c++ gcc-toolset-14-libquadmath-devel; \
    fi \
  && dnf install -y \
    cmake file git help2man ninja-build pkgconf python3 rpm-build \
    bzip2 czmq-devel expat-devel geos-devel libcurl-devel libgeotiff-devel libspatialite-devel \
    libtiff-devel luajit-devel lz4-devel openssl-devel sqlite-devel zeromq-devel zlib-devel \
  && dnf clean all

ARG PROTOBUF_VERSION=21.12
RUN if ! command -v protoc >/dev/null; then \
      source /opt/rh/gcc-toolset-14/enable && \
      git clone --quiet --depth 1 --branch "v${PROTOBUF_VERSION}" https://github.com/protocolbuffers/protobuf /tmp/protobuf && \
      cmake -S /tmp/protobuf -B /tmp/protobuf/build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=OFF && \
      cmake --build /tmp/protobuf/build && cmake --install /tmp/protobuf/build && rm -rf /tmp/protobuf; \
    fi

ARG BOOST_VERSION=1.83.0
RUN if [ ! -d /usr/include/boost ]; then \
      curl -sSfL "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.bz2" \
        | tar -xj -C /usr/local/include --strip-components=1 "boost_${BOOST_VERSION//./_}/boost"; \
    fi
