class XercesC < Formula
  desc "Validating XML parser"
  homepage "https://xerces.apache.org/xerces-c/"
  url "https://www.apache.org/dyn/closer.lua?path=xerces/c/3/sources/xerces-c-3.2.5.tar.gz"
  mirror "https://archive.apache.org/dist/xerces/c/3/sources/xerces-c-3.2.5.tar.gz"
  sha256 "545cfcce6c4e755207bd1f27e319241e50e37c0c27250f11cda116018f1ef0f5"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/kwabenantim/homebrew-chaste/releases/download/xerces-c-3.2.5"
    sha256 cellar: :any,                 arm64_sonoma: "ba08617a8b6dfb928450c09c4e820953df72c05510dee82a84dcaeb6dd6c7ace"
    sha256 cellar: :any,                 ventura:      "78ff1a437c3a54dba79b5b67a4538add982de835b191e25baa6836245cbc517a"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "64656a227bf2bffd6dd6106fc34a530059f997b68ad0215903171c361abea456"
  end

  depends_on "cmake" => :build

  uses_from_macos "curl"

  def install
    # Prevent opportunistic linkage to `icu4c`
    args = std_cmake_args + %W[
      -DCMAKE_DISABLE_FIND_PACKAGE_ICU=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build_shared", "-DBUILD_SHARED_LIBS=ON", *args
    system "cmake", "--build", "build_shared"
    system "ctest", "--test-dir", "build_shared", "--verbose"
    system "cmake", "--install", "build_shared"

    system "cmake", "-S", ".", "-B", "build_static", "-DBUILD_SHARED_LIBS=OFF", *args
    system "cmake", "--build", "build_static"
    lib.install Dir["build_static/src/*.a"]

    # Remove a sample program that conflicts with libmemcached
    # on case-insensitive file systems
    (bin/"MemParse").unlink
  end

  test do
    (testpath/"ducks.xml").write <<~EOS
      <?xml version="1.0" encoding="iso-8859-1"?>

      <ducks>
        <person id="Red.Duck" >
          <name><family>Duck</family> <given>One</given></name>
          <email>duck@foo.com</email>
        </person>
      </ducks>
    EOS

    output = shell_output("#{bin}/SAXCount #{testpath}/ducks.xml")
    assert_match "(6 elems, 1 attrs, 0 spaces, 37 chars)", output
  end
end
