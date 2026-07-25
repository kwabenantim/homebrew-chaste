require "digest"

class ChasteDependencies < Formula
  # This formula is its own source: the file is both the download and the
  # recipe. When installing from a bottle, Homebrew reads the recipe out of the
  # bottle and evaluates it against a simulated Cellar path that does not exist
  # on disk, so digesting __FILE__ unconditionally raises Errno::ENOENT. No
  # download happens on that path, so a placeholder digest is enough.
  formula_path = File.expand_path(__FILE__)

  desc "Dependencies for Chaste, a simulation package for computational biology"
  homepage "https://chaste.github.io/"
  url "file://"+formula_path
  version "3"
  sha256 File.exist?(formula_path) ? Digest::SHA256.file(formula_path).hexdigest : "0"*64
  license "BSD-3-Clause"

  depends_on "boost"
  depends_on "cmake"
  depends_on "hdf5-mpi"
  depends_on "kwabenantim/chaste/scotch-parmetis"
  depends_on "kwabenantim/chaste/vtk-mpi"
  depends_on "petsc"
  depends_on "sundials"
  depends_on "xerces-c"
  depends_on "xsd"

  def install
    File.open("chaste-dependencies", "w") do |file|
      file.write "#!/bin/sh"+"\n"
      deps.each do |dep|
        f = dep.to_formula
        file.write "echo "+[f.full_name, f.version, f.prefix].join("\t")+"\n"
      end
    end
    bin.install "chaste-dependencies"
  end
end
