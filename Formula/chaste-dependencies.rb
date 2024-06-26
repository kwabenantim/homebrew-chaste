require "digest"

class ChasteDependencies < Formula
  desc "Dependencies for Chaste, a simulation package for computational biology"
  homepage "https://chaste.github.io/"
  url "file://"+File.expand_path(__FILE__)
  version "1"
  sha256 Digest::SHA256.file(File.expand_path(__FILE__)).hexdigest
  license "BSD-3-Clause"

  depends_on "boost"
  depends_on "cmake"
  depends_on "hdf5-mpi"
  depends_on "kwabenantim/chaste/parmetis"
  depends_on "kwabenantim/chaste/petsc"
  depends_on "kwabenantim/chaste/vtk"
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
