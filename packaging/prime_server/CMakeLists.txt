# Packages a prime_server build tree, as prime_server's own project doesn't include CPack.
# Configure with -DPRIME_SERVER_BUILD_DIR=<dir> -DPRIME_SERVER_VERSION=<x.y.z>, then run cpack -G DEB|RPM.
cmake_minimum_required(VERSION 3.15)
project(prime_server_package NONE)

set(CPACK_INSTALL_CMAKE_PROJECTS "${PRIME_SERVER_BUILD_DIR};prime_server;ALL;/")
set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")
set(CPACK_PACKAGE_NAME "prime-server")
set(CPACK_PACKAGE_VERSION "${PRIME_SERVER_VERSION}")
set(CPACK_PACKAGE_CONTACT "Kevin Kreiser <kevinkreiser@gmail.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Non-blocking (web)server API for distributed computing and SOA based on zeromq")
set(CPACK_STRIP_FILES TRUE)

set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")
set(CPACK_DEBIAN_PACKAGE_SECTION "libs")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
# lets dpkg-shlibdeps resolve libvalhalla's dependency on libprime_server
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)

set(CPACK_RPM_FILE_NAME "RPM-DEFAULT")
set(CPACK_RPM_PACKAGE_NAME "prime_server")
set(CPACK_RPM_PACKAGE_LICENSE "BSD-2-Clause")
set(CPACK_RPM_PACKAGE_URL "https://github.com/kevinkreiser/prime_server")

include(CPack)
