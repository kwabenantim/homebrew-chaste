class Netcdf < Formula
  desc "Libraries and data formats for array-oriented scientific data"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.2.tar.gz"
  sha256 "bc104d101278c68b303359b3dc4192f81592ae8640f1aee486921138f7f88cb7"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/Unidata/netcdf-c.git", branch: "main"

  livecheck do
    url :stable
    regex(/^(?:netcdf[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/kwabenantim/homebrew-chaste/releases/download/netcdf-4.9.2_1"
    rebuild 1
    sha256 cellar: :any,                 arm64_sonoma: "28fdd81b1a59a4a5666fca283838a74f668d1973e47899c04273e03a2e57fdc0"
    sha256 cellar: :any,                 ventura:      "da738072d8091468cb684b6afc5a7012b4121407548227ba57fe840a7b56b7c5"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "342452a0099f8fc40235580ac6fb7a5a95e49b5f224773bc16b4fe45fc603a36"
  end

  depends_on "cmake" => :build
  depends_on "hdf5-mpi" # Chaste
  depends_on "open-mpi" # Chaste

  uses_from_macos "m4" => :build
  uses_from_macos "bzip2"
  uses_from_macos "curl"
  uses_from_macos "libxml2"
  uses_from_macos "zlib"

  def install
    args = %w[-DENABLE_TESTS=OFF -DENABLE_NETCDF_4=ON -DENABLE_DOXYGEN=OFF]
    # Fixes "relocation R_X86_64_PC32 against symbol `stderr@@GLIBC_2.2.5' can not be used" on Linux
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" if OS.linux?

    ENV["CC"] = "mpicc" # Chaste
    ENV["CXX"] = "mpicxx" # Chaste

    system "cmake", "-S", ".", "-B", "build_shared", *args, "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"
    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF", *std_cmake_args
    system "cmake", "--build", "build_static"
    lib.install "build_static/liblib/libnetcdf.a"

    # Remove shim paths
    inreplace [bin/"nc-config",
               lib/"pkgconfig/netcdf.pc",
               lib/"cmake/netCDF/netCDFConfig.cmake",
               lib/"libnetcdf.settings"],
               which(ENV.cc).to_s, ENV.cc
    # Chaste: which(ENV.cc)
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include "netcdf_meta.h"
      int main()
      {
        printf(NC_VERSION);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lnetcdf",
                   "-o", "test"
    if head?
      assert_match(/^\d+(?:\.\d+)+/, `./test`)
    else
      assert_equal version.to_s, `./test`
    end
  end
end
