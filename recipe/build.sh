#!/usr/bin/env bash
set -e

if [[ -n "$enable_moab" && "$enable_moab" != "nomoab" ]]; then
  export CONFIGURE_ARGS="--moab=${PREFIX} ${CONFIGURE_ARGS}"
fi

# pyne ships pre-assembled CRAM/decay sources only for x86_64
# (cram-linux-gnu.s and cram-apple-clang.s are both x86_64). On
# aarch64/arm64 the assembler rejects them, so disable fast-compile
# and fall back to the portable C/C++ sources via setup.py --slow.
case "${target_platform}" in
  linux-aarch64|osx-arm64)
    export CONFIGURE_ARGS="--slow ${CONFIGURE_ARGS}"
    ;;
esac

# CMake's FindHDF5 falls back to parsing H5_VERSION out of H5pubconf.h, but its
# regex only accepts "X.Y.Z" or "X.Y.Z-patchN". hdf5 1.14.4 defines
# H5_VERSION "1.14.4-3", which leaves HDF5_VERSION empty and makes pyne's
# unquoted 'if(NOT (${HDF5_VERSION} VERSION_LESS 1.12.0))' check fail, so
# derive the version from H5public.h and hand it to CMake explicitly.
hdf5_version=$(awk '/^#define H5_VERS_(MAJOR|MINOR|RELEASE) /{v = v sep $3; sep="."} END{print v}' "${PREFIX}/include/H5public.h")
echo "Using HDF5_VERSION=${hdf5_version}"

# Install PyNE
export VERBOSE=1
${PYTHON} setup.py install \
  --build-type="Release" \
  --prefix="${PREFIX}" \
  --hdf5="${PREFIX}" \
  -D HDF5_VERSION="${hdf5_version}" \
  ${CONFIGURE_ARGS} \
  --clean \
  -j "${CPU_COUNT}"

# Create data library
cd build
${PYTHON} ${PREFIX}/bin/nuc_data_make
