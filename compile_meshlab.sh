#!/usr/bin/env bash
set -euo pipefail

# Only run apt-get if meshlab directory doesn't exist (fresh install)
if [ ! -d "meshlab" ]; then
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
        ca-certificates git build-essential cmake ninja-build pkg-config \
        qtbase5-dev qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5svg5-dev \
        libeigen3-dev libglew-dev libglu1-mesa-dev libgl1-mesa-dev \
        libopencv-dev libgmp-dev libmpfr-dev libmuparser-dev libopenctm-dev libqhull-dev

  rm -rf meshlab
  git clone --depth 1 --recurse-submodules "https://github.com/cnr-isti-vclab/meshlab" meshlab
fi

# Monkeypatch: Enable CGAL CORE support for Exact_predicates_exact_constructions_kernel_with_sqrt
CGAL_CMAKE="meshlab/src/external/cgal.cmake"
if [ -f "${CGAL_CMAKE}" ] && ! grep -q "CGAL_USE_CORE" "${CGAL_CMAKE}"; then
  echo "Patching CGAL cmake to enable CORE support..."
  # Add CGAL_USE_CORE=1 compile definition to the external-cgal target
  sed -i '/target_link_libraries(external-cgal INTERFACE CGAL::CGAL Threads::Threads)/a\	target_compile_definitions(external-cgal INTERFACE CGAL_USE_CORE=1)' "${CGAL_CMAKE}"
  sed -i '/target_link_libraries(external-cgal INTERFACE ${GMP_LIBRARIES} mpfr Threads::Threads)/a\		target_compile_definitions(external-cgal INTERFACE CGAL_USE_CORE=1)' "${CGAL_CMAKE}"
fi

# Only run cmake configuration if build directory doesn't exist
if [ ! -d "meshlab/build" ]; then
  cmake -S meshlab -B meshlab/build -G Ninja -DCMAKE_BUILD_TYPE=Release
fi

# Monkeypatch: Fix missing #include <algorithm> in lib3mf
LIB3MF_FILE="meshlab/src/external/downloads/lib3mf-2.4.1/Source/Model/Writer/v100/NMR_ResourceDependencySorter.cpp"
if [ -f "${LIB3MF_FILE}" ] && ! grep -q "#include <algorithm>" "${LIB3MF_FILE}"; then
  echo "Patching lib3mf for missing #include <algorithm>..."
  sed -i "1i #include <algorithm>" "${LIB3MF_FILE}"
fi

cmake --build meshlab/build --parallel "${MESHLAB_BUILD_JOBS:-$(nproc)}"

echo ""
echo "========================================="
echo "MeshLab compiled successfully!"
echo "========================================="
echo "Executable: meshlab/build/src/distrib/meshlab"
echo "Plugins:    meshlab/build/src/distrib/plugins/"
echo ""
