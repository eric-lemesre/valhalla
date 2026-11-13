ARG BASE=debian:trixie
FROM ${BASE}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --yes --no-install-recommends \
    build-essential ca-certificates cmake curl dpkg-dev file git ninja-build pkgconf \
    libboost-dev libcurl4-openssl-dev libczmq-dev libexpat1-dev libgeos-dev libgeotiff-dev \
    libluajit-5.1-dev liblz4-dev libprotobuf-dev libspatialite-dev libsqlite3-dev libssl-dev \
    libtiff-dev libzmq3-dev protobuf-compiler spatialite-bin zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# valhalla-tools needs edition 2024, newer than some distributions' rustc
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain stable --no-modify-path
