class ScotchParmetis < Formula
  desc "Graph partitioning, clustering and sparse matrix ordering (METIS headers)"
  homepage "https://gitlab.inria.fr/scotch/scotch"
  url "https://gitlab.inria.fr/scotch/scotch/-/archive/v7.0.12/scotch-v7.0.12.tar.bz2"
  sha256 "3bdba84f2067398ee8931de5d4b1f3608b483ac56316fd5f348f9c0a594d57ae"
  license "CECILL-C"
  head "https://gitlab.inria.fr/scotch/scotch.git", branch: "master"

  livecheck do
    formula "scotch"
  end

  bottle do
    root_url "https://github.com/kwabenantim/homebrew-chaste/releases/download/scotch-parmetis-7.0.12"
    sha256 cellar: :any, arm64_sequoia: "df499e51bb097d63299a86b8be5d4af84ddb33f94766ea7449a68842c6578170"
  end

  # Scotch's METIS and ParMETIS compatibility headers are named metis.h and
  # parmetis.h, so linking them would collide with the `metis` formula. `metis`
  # cannot simply be avoided: `petsc` requires it, and Chaste needs `petsc`.
  # Staying keg-only sidesteps the collision without constraining anything else,
  # and Chaste locates this through the prefix that `chaste-dependencies` emits.
  keg_only "it installs metis.h and parmetis.h, which conflict with `metis`"

  depends_on "bison" => :build
  depends_on "cmake" => :build
  depends_on "open-mpi"
  depends_on "xz"

  uses_from_macos "flex" => :build
  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DENABLE_TESTS=OFF
      -DINSTALL_METIS_HEADERS=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    (pkgshare/"check").install "src/check/test_strat_seq.c"
    (pkgshare/"check").install "src/check/test_strat_par.c"
    (pkgshare/"libscotch").install "src/libscotch/common.h"
    (pkgshare/"libscotch").install "src/libscotch/module.h"

    # License file has a non-standard filename
    prefix.install buildpath.glob("LICEN[CS]E_*.txt")
    doc.install (buildpath/"doc").children
  end

  test do
    # The point of this variant: the compatibility headers core's scotch
    # deliberately withholds via -DINSTALL_METIS_HEADERS=OFF.
    assert_path_exists include/"metis.h"
    assert_path_exists include/"parmetis.h"

    (testpath/"test.c").write <<~C
      #include <stdlib.h>
      #include <stdio.h>
      #include <scotch.h>
      int main(void) {
        int major, minor, patch;
        SCOTCH_version(&major, &minor, &patch);
        printf("%d.%d.%d", major, minor, patch);
        return 0;
      }
    C

    args = %W[-I#{include} -L#{lib} -lscotch -lscotcherr -pthread -lz -lm]
    args << "-L#{formula_opt_lib("zlib-ng-compat")}" if OS.linux?

    system ENV.cc, "test.c", *args
    assert_match version.to_s, shell_output("./a.out")

    # Exercise the METIS compatibility layer through scotch's own metis.h.
    # These are METIS names and types, served by libscotchmetis.
    (testpath/"metis_test.c").write <<~C
      #include <stdio.h>
      #include <metis.h>
      int main(void) {
        idx_t options[METIS_NOPTIONS];
        if (METIS_SetDefaultOptions(options) != METIS_OK)
          return 1;
        printf("metis ok");
        return 0;
      }
    C
    system ENV.cc, "metis_test.c", "-o", "metis_test", "-lscotchmetisv5", *args
    assert_match "metis ok", shell_output("./metis_test")

    # parmetis.h pulls in mpi.h itself and uses ParMETIS v3's idxtype rather
    # than metis.h's idx_t. Taking the address of an entry point forces the
    # linker to resolve it against libptscotchparmetis.
    (testpath/"parmetis_test.c").write <<~C
      #include <stdio.h>
      #include <parmetis.h>
      int main(void) {
        idxtype vtxdist = 0;
        void (*fn)(void) = (void (*)(void)) ParMETIS_V3_PartKway;
        printf("%s", (fn != NULL && vtxdist == 0) ? "parmetis ok" : "bad");
        return 0;
      }
    C
    system "mpicc", "parmetis_test.c", "-o", "parmetis_test",
                    "-lptscotchparmetisv3", "-lptscotch", "-Wl,-rpath,#{lib}", *args
    assert_match "parmetis ok", shell_output("./parmetis_test")

    system ENV.cc, pkgshare/"check/test_strat_seq.c", "-o", "test_strat_seq", *args
    assert_match "Sequential mapping strategy, SCOTCH_STRATDEFAULT", shell_output("./test_strat_seq")

    system "mpicc", pkgshare/"check/test_strat_par.c", "-o", "test_strat_par",
                    "-lptscotch", "-Wl,-rpath,#{lib}", *args
    assert_match "Parallel mapping strategy, SCOTCH_STRATDEFAULT", shell_output("./test_strat_par")
  end
end
