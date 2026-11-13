ARG BASE=fedora:43
FROM ${BASE}

# RHEL-like 9: geos, luajit, czmq, spatialite and libgeotiff come from EPEL, their -devel
# dependencies from CRB, and GCC 11 is too old for C++20, hence gcc-toolset-14
RUN if grep -q '^ID="\?fedora' /etc/os-release; then \
      dnf install -y gcc gcc-c++; \
    else \
      dnf install -y dnf-plugins-core epel-release && dnf config-manager --set-enabled crb && \
      dnf install -y gcc-toolset-14-gcc gcc-toolset-14-gcc-c++; \
    fi \
  && dnf install -y \
    cmake file git ninja-build pkgconf rpm-build spatialite-tools \
    boost-devel czmq-devel expat-devel geos-devel libcurl-devel libgeotiff-devel libspatialite-devel \
    libtiff-devel luajit-devel lz4-devel openssl-devel protobuf-compiler protobuf-devel sqlite-devel \
    zeromq-devel zlib-devel \
  && dnf clean all

ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain stable --no-modify-path
