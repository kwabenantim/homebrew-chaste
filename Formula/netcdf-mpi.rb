class NetcdfMpi < Formula
  desc "Libraries and data formats for array-oriented scientific data (parallel)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.10.1.tar.gz"
  sha256 "33c27231c478c3b35da7c7758fbdd02da1fe407abcb16ddfe195f69d164f930d"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/Unidata/netcdf-c.git", branch: "main"

  livecheck do
    formula "netcdf"
  end

  bottle do
    root_url "https://github.com/kwabenantim/homebrew-chaste/releases/download/netcdf-mpi-4.10.1"
    sha256 cellar: :any, arm64_sequoia: "37595c689a535ea452b7797aea7240d808b46b61820238ab2f9ae6d39f706167"
  end

  depends_on "cmake" => :build
  depends_on "hdf5-mpi"
  depends_on "open-mpi"

  uses_from_macos "m4" => :build
  uses_from_macos "bzip2"
  uses_from_macos "curl"
  uses_from_macos "libxml2"

  on_macos do
    depends_on "libaec"
    depends_on "zstd"
  end

  conflicts_with "netcdf", because: "netcdf-mpi is a variant of netcdf, one can only use one or the other"

  def install
    args = %w[
      -DNETCDF_ENABLE_TESTS=OFF
      -DNETCDF_ENABLE_HDF5=ON
      -DNETCDF_ENABLE_DOXYGEN=OFF
      -DNETCDF_ENABLE_PARALLEL4=ON
      -DHDF5_PARALLEL=ON
      -DCMAKE_C_COMPILER=mpicc
    ]
    # Fixes "relocation R_X86_64_PC32 against symbol `stderr@@GLIBC_2.2.5' can not be used" on Linux
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" if OS.linux?

    system "cmake", "-S", ".", "-B", "build_shared", *args, "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"
    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF", *std_cmake_args
    system "cmake", "--build", "build_static"
    lib.install "build_static/libnetcdf.a"

    # Remove shim paths. The MPI wrappers are not shimmed, so this only fires if
    # a plain compiler reached the recorded settings.
    inreplace [bin/"nc-config", lib/"pkgconfig/netcdf.pc", lib/"cmake/netCDF/netCDFConfig.cmake",
               lib/"libnetcdf.settings"], Superenv.shims_path/ENV.cc, ENV.cc, audit_result: false

    # libnetcdf.settings is a build-configuration summary, not a library, and
    # nothing in the keg reads it (nc-config exposes the same information).
    # Keep a copy but out of lib, where non-libraries fail `brew audit --new`.
    pkgshare.install lib/"libnetcdf.settings"
  end

  test do
    # netcdf quietly falls back to a serial build when it cannot see parallel
    # HDF5, which would defeat the point of this variant.
    assert_equal "yes", shell_output("#{bin}/nc-config --has-parallel4").chomp

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include "netcdf_meta.h"
      int main()
      {
        printf(NC_VERSION);
        return 0;
      }
    C
    system "mpicc", "test.c", "-L#{lib}", "-I#{include}", "-lnetcdf", "-o", "test"
    assert_equal version.to_s, `./test`
  end
end
