# MeshLab Compilation Script

This script downloads and compiles [MeshLab](https://github.com/cnr-isti-vclab/meshlab) from source with all necessary patches applied automatically.

## Usage

Simply run:
```bash
./compile_meshlab.sh
```

## What the script does

1. **Installs dependencies** (only if `meshlab` directory doesn't exist)
   - Qt5 development libraries
   - OpenGL libraries
   - Math libraries (GMP, MPFR)
   - Build tools (CMake, Ninja)
   - Other required libraries

2. **Clones MeshLab repository** (only if not already present)
   - Uses shallow clone for faster download
   - Includes all submodules

3. **Applies patches** to fix compilation issues:
   - **CGAL**: Enables CORE support for advanced geometric computations
   - **lib3mf**: Adds missing `#include <algorithm>` header

4. **Builds MeshLab** using Ninja build system in parallel

## Output

After successful compilation:
- **Executable**: `meshlab/build/src/distrib/meshlab`
- **Plugins**: `meshlab/build/src/distrib/plugins/`

## Patches Applied

### 1. CGAL CORE Support
**File**: `meshlab/src/external/cgal.cmake`

**Issue**: CGAL's `Exact_predicates_exact_constructions_kernel_with_sqrt` type requires CORE library support to be explicitly enabled. Without it, compilation fails with "You need LEDA or CORE installed" error.

**Fix**: Adds `CGAL_USE_CORE=1` compile definition to the `external-cgal` interface target. CORE is already bundled with CGAL 5.6 and only requires GMP/MPFR (which are installed as dependencies).

### 2. lib3mf Missing Include
**File**: `meshlab/src/external/downloads/lib3mf-2.4.1/Source/Model/Writer/v100/NMR_ResourceDependencySorter.cpp`

**Issue**: Missing `#include <algorithm>` for `std::sort`

**Fix**: Adds the include at the top of the file

## Notes

- The script is idempotent: running it multiple times won't re-download or re-patch
- Set `MESHLAB_BUILD_JOBS` environment variable to control parallel build (defaults to `nproc`)
- CGAL CORE support is enabled for proper geometric computations without needing LEDA
- Patches are applied with markers to prevent re-patching

## Requirements

- Ubuntu-based Linux distribution
- `sudo` access for installing packages
- Internet connection for initial download

## Technical Details

### Why CGAL CORE?

MeshLab uses libigl which relies on CGAL's `Exact_predicates_exact_constructions_kernel_with_sqrt` for certain boolean operations and mesh processing. This kernel requires either:
- **LEDA** (commercial, not in Ubuntu repos)
- **CORE** (open-source, bundled with CGAL)

The script enables CORE support which is already included in CGAL 5.6 and only requires GMP/MPFR libraries.
