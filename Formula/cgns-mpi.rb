class CgnsMpi < Formula
  desc "CFD General Notation System (parallel)"
  homepage "https://cgns.github.io/"
  url "https://github.com/CGNS/CGNS/archive/refs/tags/v4.5.2.tar.gz"
  sha256 "95075e1fd0b51d97b1b96b73ebe03b1a551fbcc9cd2b2b6f487ccccedcff5964"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/CGNS/CGNS.git", branch: "develop"

  livecheck do
    formula "cgns"
  end

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "hdf5-mpi"
  depends_on "open-mpi"

  conflicts_with "cgns", because: "cgns-mpi is a variant of cgns, one can only use one or the other"

  def install
    # CMake FortranCInterface_VERIFY fails with LTO on Linux due to different GCC and GFortran versions
    ENV.append "FFLAGS", "-fno-lto" if OS.linux?

    # HDF5_NEED_MPI unlocks CGNS_ENABLE_PARALLEL, and CGNS hard-errors if the
    # HDF5 it finds turns out to lack parallel support.
    args = %w[
      -DCGNS_ENABLE_64BIT=YES
      -DCGNS_ENABLE_FORTRAN=YES
      -DCGNS_ENABLE_HDF5=YES
      -DHDF5_NEED_MPI=YES
      -DCGNS_ENABLE_PARALLEL=YES
      -DCMAKE_C_COMPILER=mpicc
      -DCMAKE_Fortran_COMPILER=mpif90
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
