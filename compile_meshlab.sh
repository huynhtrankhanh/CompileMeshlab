#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
      ca-certificates git build-essential cmake ninja-build pkg-config \
      qtbase5-dev qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5svg5-dev \
      libeigen3-dev libglew-dev libglu1-mesa-dev libgl1-mesa-dev \
      libopencv-dev libgmp-dev libmuparser-dev libopenctm-dev libqhull-dev

rm -rf meshlab
git clone --depth 1 --recurse-submodules "https://github.com/cnr-isti-vclab/meshlab" meshlab

cmake -S meshlab -B meshlab/build -G Ninja -DCMAKE_BUILD_TYPE=Release

LIB3MF_FILE="meshlab/src/external/downloads/lib3mf-2.4.1/Source/Model/Writer/v100/NMR_ResourceDependencySorter.cpp"
if [ -f "${LIB3MF_FILE}" ] && ! grep -q "#include <algorithm>" "${LIB3MF_FILE}"; then
  sed -i "1i #include <algorithm>" "${LIB3MF_FILE}"
fi

cmake --build meshlab/build --parallel "${MESHLAB_BUILD_JOBS:-$(nproc)}"
