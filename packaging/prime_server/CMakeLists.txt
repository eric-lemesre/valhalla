# Packages prime_server, whose own project doesn't include CPack, as a library and a -dev/-devel
# package. Configure with -DPRIME_SERVER_STAGE=<dir prime_server was installed to with --prefix>
# -DPRIME_SERVER_LIBDIR=<its lib dir, relative> -DPRIME_SERVER_VERSION=<x.y.z>
# -DPRIME_SERVER_LICENSE=<its LICENSE.md> -DCPACK_GENERATOR=DEB|RPM, then run cpack.
cmake_minimum_required(VERSION 3.15)
project(prime_server_package NONE)

set(stage "${PRIME_SERVER_STAGE}")
set(libdir "${PRIME_SERVER_LIBDIR}")
set(debian_dir "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/debian")
# LICENSE.md is a symlink, the package needs the file
get_filename_component(license "${PRIME_SERVER_LICENSE}" REALPATH)

# keeps the library executable, rpm only reads the sonames of executable files
install(DIRECTORY "${stage}/${libdir}/" DESTINATION "${libdir}" COMPONENT runtime USE_SOURCE_PERMISSIONS
  FILES_MATCHING PATTERN "libprime_server.so.*" PATTERN "cmake" EXCLUDE PATTERN "pkgconfig" EXCLUDE)
install(DIRECTORY "${stage}/include/" DESTINATION include COMPONENT devel)
install(DIRECTORY "${stage}/${libdir}/" DESTINATION "${libdir}" COMPONENT devel
  FILES_MATCHING PATTERN "libprime_server.so" PATTERN "*.pc" PATTERN "*.cmake")

set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")
set(CPACK_PACKAGE_NAME "prime_server")
set(CPACK_PACKAGE_VERSION "${PRIME_SERVER_VERSION}")
set(CPACK_PACKAGE_CONTACT "Kevin Kreiser <kevinkreiser@gmail.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Non-blocking web server API for distributed computing")
set(CPACK_COMPONENTS_ALL runtime devel)

set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://github.com/kevinkreiser/prime_server")
set(CPACK_DEBIAN_PACKAGE_SECTION "libs")
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "An HTTP server and a pipeline of workers communicating over ZeroMQ,
as used by the Valhalla routing services.")
set(CPACK_DEBIAN_RUNTIME_PACKAGE_NAME "libprime-server0")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
# lets dpkg-shlibdeps resolve libvalhalla's dependency on libprime_server
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY ">=")
set(CPACK_DEBIAN_RUNTIME_PACKAGE_CONTROL_EXTRA
  "${debian_dir}/triggers;${debian_dir}/postinst;${debian_dir}/postrm")
set(CPACK_DEBIAN_RUNTIME_PACKAGE_CONTROL_STRICT_PERMISSION ON)
set(CPACK_DEBIAN_DEVEL_PACKAGE_NAME "libprime-server-dev")
set(CPACK_DEBIAN_DEVEL_PACKAGE_SECTION "libdevel")
set(CPACK_DEBIAN_DEVEL_PACKAGE_DEPENDS
  "libprime-server0 (= ${PRIME_SERVER_VERSION}), libczmq-dev, libcurl4-openssl-dev | libcurl-dev, libzmq3-dev")

set(CPACK_RPM_COMPONENT_INSTALL ON)
set(CPACK_RPM_FILE_NAME "RPM-DEFAULT")
set(CPACK_RPM_PACKAGE_LICENSE "BSD-2-Clause")
set(CPACK_RPM_PACKAGE_URL "https://github.com/kevinkreiser/prime_server")
set(CPACK_RPM_PACKAGE_DESCRIPTION "An HTTP server and a pipeline of workers communicating over ZeroMQ,
as used by the Valhalla routing services.")
set(CPACK_RPM_RUNTIME_PACKAGE_NAME "prime_server")
set(CPACK_RPM_DEVEL_PACKAGE_NAME "prime_server-devel")
set(CPACK_RPM_DEVEL_PACKAGE_REQUIRES "prime_server = ${PRIME_SERVER_VERSION}")

# Debian policy wants a copyright file and a changelog (named as for a native package, the version
# having no Debian revision) in every package's doc directory
if(CPACK_GENERATOR STREQUAL "DEB")
  string(TIMESTAMP deb_changelog_date "%a, %d %b %Y %H:%M:%S +0000" UTC)
  foreach(component runtime devel)
    string(TOUPPER ${component} component_upper)
    set(deb_package ${CPACK_DEBIAN_${component_upper}_PACKAGE_NAME})
    set(deb_doc_dir "${CMAKE_BINARY_DIR}/debian-doc/${deb_package}")
    file(WRITE "${deb_doc_dir}/changelog"
      "${deb_package} (${PRIME_SERVER_VERSION}) unstable; urgency=medium\n\n"
      "  * prime_server ${PRIME_SERVER_VERSION}.\n\n"
      " -- ${CPACK_PACKAGE_CONTACT}  ${deb_changelog_date}\n")
    execute_process(COMMAND gzip -9nf "${deb_doc_dir}/changelog" RESULT_VARIABLE gzip_result)
    if(NOT gzip_result EQUAL 0)
      message(FATAL_ERROR "gzip failed on ${deb_doc_dir}/changelog")
    endif()
    install(FILES "${deb_doc_dir}/changelog.gz" DESTINATION "share/doc/${deb_package}"
      COMPONENT ${component})
    install(FILES "${license}" RENAME copyright DESTINATION "share/doc/${deb_package}"
      COMPONENT ${component})
  endforeach()
endif()

include(CPack)
