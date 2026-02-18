#!/usr/bin/env bash
set -e

if [[ -n "$enable_moab" && "$enable_moab" != "nomoab" ]]; then
  MOAB_CMAKE_ARGS="-DWITH_MOAB=ON -DMOAB_ROOT=${PREFIX}"
fi

export VERBOSE=1

# atomic_data.h/cpp are not in the source tarball and must be generated
# before cmake can configure. Mirrors setup.py's ensure_atomic() pre-cmake step.
pushd src
${PYTHON} -c "import atomicgen; atomicgen.main()" 2>/dev/null || \
  { [ ! -f atomic_data.h ] && cp _atomic_data.h atomic_data.h && cp _atomic_data.cpp atomic_data.cpp; } || true
popd

rm -rf build
cmake \
  ${CMAKE_ARGS} \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DHDF5_ROOT="${PREFIX}" \
  -DPYTHON_EXECUTABLE="${PYTHON}" \
  ${MOAB_CMAKE_ARGS} \
  -S . \
  -B build

cmake build -LH
cmake --build build --parallel "${CPU_COUNT}"
# cmake's install step invokes SetupSubPyInstall.cmake.in, which runs
# `${PYTHON} setup_sub.py install --prefix=${PREFIX}` via setuptools.
cmake --install build

# Create data library
pushd build
${PYTHON} "${PREFIX}/bin/nuc_data_make"
popd
