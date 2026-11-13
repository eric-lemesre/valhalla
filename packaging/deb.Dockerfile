ARG BASE=debian:trixie
FROM ${BASE}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --yes --no-install-recommends \
    build-essential ca-certificates cmake curl dpkg-dev file git ninja-build pkgconf python3 \
    libboost-dev libcurl4-openssl-dev libczmq-dev libexpat1-dev libgeos-dev libgeotiff-dev \
    libluajit-5.1-dev liblz4-dev libprotobuf-dev libspatialite-dev libsqlite3-dev libssl-dev \
    libtiff-dev libzmq3-dev protobuf-compiler spatialite-bin zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

