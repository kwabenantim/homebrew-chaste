class Parmetis < Formula
  desc "Library for parallel graph partitioning and fill-reducing matrix ordering"
  homepage "http://glaros.dtc.umn.edu/gkhome/metis/parmetis/overview"
  url "http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz"
  sha256 "f2d9a231b7cf97f1fee6e8c9663113ebf6c240d407d3c118c55b3633d6be6e5f"
  license :cannot_represent
  revision 2

  bottle do
    root_url "https://github.com/kwabenantim/homebrew-chaste/releases/download/parmetis-4.0.3_1"
    rebuild 1
    sha256 cellar: :any,                 ventura:      "32017f9d0122173052fd0b271fa27ae9e74c1f2dade91b22cc100f94a82b40f8"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1938a5289907bfaef623d1ab05d78f038564da87793b75a5acf6ad317e9dcebd"
  end

  depends_on "cmake" => :build
  depends_on "metis"
  depends_on "open-mpi"

  # Do not build the METIS 5.* that ships with ParMETIS.
  patch :DATA

  # Bug fixes from PETSc developers.
  patch do
    url "https://bitbucket.org/petsc/pkg-parmetis/commits/82409d68aa1d6cbc70740d0f35024aae17f7d5cb/raw/"
    sha256 "72f2c282bfdec35cd1cfd66163551bf5e7cb34df97363fd465a26d41b836a75f"
  end

  patch do
    url "https://bitbucket.org/petsc/pkg-parmetis/commits/1c1a9fd0f408dc4d42c57f5c3ee6ace411eb222b/raw/"
    sha256 "0696a65a26a51cdf2e48879be4b42f5d73e6b82253525e869b08d45f3f2c5b0c"
  end

  def install
    ENV.append "LDFLAGS", "-L#{Formula["metis"].opt_lib} -lmetis -lm"

    system "make", "config", "prefix=#{prefix}", "shared=1"
    system "make", "install"
    pkgshare.install "Graphs" # Sample data for test
  end

  test do
    system "mpirun", "#{bin}/ptest", "#{pkgshare}/Graphs/rotor.graph"
  end
end

__END__
diff --git a/CMakeLists.txt b/CMakeLists.txt
index ca945dd..1bf94e9 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -33,7 +33,7 @@ include_directories(${GKLIB_PATH})
 include_directories(${METIS_PATH}/include)

 # List of directories that cmake will look for CMakeLists.txt
-add_subdirectory(${METIS_PATH}/libmetis ${CMAKE_BINARY_DIR}/libmetis)
+#add_subdirectory(${METIS_PATH}/libmetis ${CMAKE_BINARY_DIR}/libmetis)
 add_subdirectory(include)
 add_subdirectory(libparmetis)
 add_subdirectory(programs)

diff --git a/libparmetis/CMakeLists.txt b/libparmetis/CMakeLists.txt
index 9cfc8a7..dfc0125 100644
--- a/libparmetis/CMakeLists.txt
+++ b/libparmetis/CMakeLists.txt
@@ -5,7 +5,7 @@ file(GLOB parmetis_sources *.c)
 # Create libparmetis
 add_library(parmetis ${ParMETIS_LIBRARY_TYPE} ${parmetis_sources})
 # Link with metis and MPI libraries.
-target_link_libraries(parmetis metis ${MPI_LIBRARIES})
+target_link_libraries(parmetis metis ${MPI_LIBRARIES} "-lm")
 set_target_properties(parmetis PROPERTIES LINK_FLAGS "${MPI_LINK_FLAGS}")

 install(TARGETS parmetis