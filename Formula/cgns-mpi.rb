class CgnsMpi < Formula
  desc "CFD General Notation System (parallel)"
  homepage "https://cgns.github.io/"
  url "https://github.com/CGNS/CGNS/archive/refs/tags/v4.5.2.tar.gz"
  sha256 "95075e1fd0b51d97b1b96b73ebe03b1a551fbcc9cd2b2b6f487ccccedcff5964"
  license "Zlib"
  compatibility_version 1
  head "https://github.com/CGNS/CGNS.git", branch: "develop"

  livecheck do
    formula "cgns"
  end

  bottle do
    root_url "https://github.com/kwabenantim/homebrew-chaste/releases/download/cgns-mpi-4.5.2"
    sha256 arm64_sequoia: "2685ab3b877552750a2c3b30ace19bb6b3e44c5fa3fc5fa95abfbae1e2dd9f87"
    sha256 sequoia:       "00d659bb4066ebad11ed706c8eb2a9d6d26d734f209bfaa787139ccce0b2d6d9"
  end

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "hdf5-mpi"
  depends_on "open-mpi"

  conflicts_with "cgns", because: "cgns-mpi is a variant of cgns, one can only use one or the other"

  def install
    # CMake FortranCInterface_VERIFY fails with LTO on Linux due to different GCC and GFortran versions
    ENV.append "FFLAGS", "-fno-lto" if OS.linux?

    # Fortran is driven by gfortran rather than the mpif90 wrapper. Open MPI's
    # Fortran wrapper hardcodes -Wl,-flat_namespace (see `mpif90 -show`), which
    # cannot be overridden by a later -Wl,-twolevel_namespace at any position,
    # and it would leave libcgns compiled with a flat namespace. CMake still
    # finds the MPI Fortran bindings itself via find_package(MPI).
    #
    # HDF5_NEED_MPI unlocks CGNS_ENABLE_PARALLEL, and CGNS hard-errors if the
    # HDF5 it finds turns out to lack parallel support.
    args = %W[
      -DCGNS_ENABLE_64BIT=YES
      -DCGNS_ENABLE_FORTRAN=YES
      -DCGNS_ENABLE_HDF5=YES
      -DHDF5_NEED_MPI=YES
      -DCGNS_ENABLE_PARALLEL=YES
      -DCMAKE_C_COMPILER=mpicc
      -DCMAKE_Fortran_COMPILER=#{formula_opt_bin("gcc")}/gfortran
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Avoid references to Homebrew shims. The MPI wrappers are not shimmed, so
    # this only fires if a plain compiler reached the recorded settings.
    inreplace include/"cgnsBuild.defs", Superenv.shims_path/ENV.cc, ENV.cc, audit_result: false
  end

  test do
    # The parallel interface header is only installed for a parallel build.
    assert_path_exists include/"pcgnslib.h"

    # The Fortran module is only installed when the Fortran bindings are built.
    assert_path_exists include/"cgns.mod"

    # Guard against the Fortran link drifting back to the mpif90 wrapper, which
    # would silently produce a flat-namespace library.
    if OS.mac?
      dylib = lib/"libcgns.#{version.major_minor}.dylib"
      assert_match "TWOLEVEL", shell_output("otool -hv #{dylib}")
    end

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include "cgnslib.h"
      int main(int argc, char *argv[])
      {
        int filetype = CG_FILE_NONE;
        if (cg_is_cgns(argv[0], &filetype) != CG_ERROR)
          return 1;
        return 0;
      }
    C
    flags = %W[-L#{lib} -lcgns]
    flags << "-Wl,-rpath,#{lib},-rpath,#{formula_opt_lib("libaec")}" if OS.linux?
    system formula_opt_prefix("hdf5-mpi")/"bin/h5pcc", "test.c", *flags
    system "./a.out"
  end
end
