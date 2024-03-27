class Parmetis < Formula
  desc "Library for parallel graph partitioning and fill-reducing matrix ordering"
  homepage "http://glaros.dtc.umn.edu/gkhome/metis/parmetis/overview"
  url "http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz"
  sha256 "f2d9a231b7cf97f1fee6e8c9663113ebf6c240d407d3c118c55b3633d6be6e5f"
  license :cannot_represent
  revision 1
  head "https://github.com/KarypisLab/ParMETIS", branch: "main"

  depends_on "cmake" => :build
  depends_on "metis"
  depends_on "open-mpi"

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
