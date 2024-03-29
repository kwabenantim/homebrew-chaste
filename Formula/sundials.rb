class Sundials < Formula
  desc "Nonlinear and differential/algebraic equations solver"
  homepage "https://computing.llnl.gov/projects/sundials"
  url "https://github.com/LLNL/sundials/releases/download/v5.8.0/sundials-5.8.0.tar.gz"
  sha256 "d4ed403351f72434d347df592da6c91a69452071860525385b3339c824e8a213"
  license "BSD-3-Clause"

  livecheck do
    url "https://computing.llnl.gov/projects/sundials/sundials-software"
    regex(/href=.*?sundials[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/kwabenantim/homebrew-chaste/releases/download/sundials-5.8.0"
    sha256 cellar: :any,                 arm64_sonoma: "f5c94f7a81b2b5aecd1577d5a156d9a01dde83701e4575b66a3a6b4f69c2e5aa"
    sha256 cellar: :any,                 ventura:      "fb304674957c291f3e2ac1d2d51da1a150f5328f662888bff4f97859b167fc44"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "bc02ade8cf77396fa5a261edf73fcfed013324c38709a901fe5a00c65bcf2d72"
  end

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "open-mpi"
  depends_on "openblas"
  depends_on "suite-sparse"

  uses_from_macos "libpcap"
  uses_from_macos "m4"

  def install
    blas = "-L#{Formula["openblas"].opt_lib} -lopenblas"
    args = std_cmake_args + %W[
      -DBUILD_SHARED_LIBS=ON
      -DKLU_ENABLE=ON
      -DKLU_LIBRARY_DIR=#{Formula["suite-sparse"].opt_lib}
      -DKLU_INCLUDE_DIR=#{Formula["suite-sparse"].opt_include}/suitesparse
      -DLAPACK_ENABLE=ON
      -DBLA_VENDOR=OpenBLAS
      -DLAPACK_LIBRARIES=#{blas};#{blas}
      -DMPI_ENABLE=ON
    ]

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end

    # Only keep one example for testing purposes
    (pkgshare/"examples").install Dir[prefix/"examples/nvector/serial/*"] \
                                  - Dir[prefix/"examples/nvector/serial/{CMake*,Makefile}"]
    rm_rf prefix/"examples"
  end

  test do
    cp Dir[pkgshare/"examples/*"], testpath
    system ENV.cc, "-I#{include}", "test_nvector.c", "sundials_nvector.c",
                   "test_nvector_serial.c", "-L#{lib}", "-lsundials_nvecserial", "-lm"
    assert_match "SUCCESS: NVector module passed all tests",
                 shell_output("./a.out 42 0")
  end
end
