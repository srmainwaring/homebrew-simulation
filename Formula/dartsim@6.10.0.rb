class DartsimAT6100 < Formula
  desc "Dynamic Animation and Robotics Toolkit (openrobotics port)"
  homepage "https://dartsim.github.io/"
  # OSRF's fork
  url "https://github.com/ignition-forks/dart/archive/d2b6ee08a60d0dbf71b0f008cd8fed1f611f6e24.tar.gz"
  version "6.10.0~20211005~d2b6ee08a60d0dbf71b0f008cd8fed1f611f6e24"
  sha256 "372af181024452418eec95f8a9cd723ceb1ada979208add66c9a4330b9c0fa32"
  license "BSD-2-Clause"
  revision 6

  bottle do
    root_url "https://osrf-distributions.s3.amazonaws.com/bottles-simulation"
    sha256 big_sur:  "2d6fa500451ddde92be8e7ae4ac3e7261612eca95584748f894d161d93798f76"
    sha256 catalina: "baa069907b662f2986120cdf59984fa7307574050dd7866531a634c045f38394"
  end

  keg_only "open robotics fork of dart HEAD + custom changes"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "assimp"
  depends_on "boost"
  depends_on "bullet"
  depends_on "eigen"
  depends_on "fcl"
  depends_on "flann"
  depends_on "ipopt"
  depends_on "libccd"
  depends_on "nlopt"
  depends_on "ode"
  depends_on "open-scene-graph"
  depends_on "tinyxml2"
  depends_on "urdfdom"

  patch do
    # Fix for compatibility with ipopt 3.13
    url "https://github.com/scpeters/dart/commit/d8500b7ee4d672ede22fbbbd72ef66c003aa2b6f.patch?full_index=1"
    sha256 "3c85f594b477ff2357017364a55cdc7b3ffa25ab53f08bd910ed5db71083ed6d"
  end

  patch do
    # Fix syntax error in glut_human_joint_limits/CMakeLists.txt
    url "https://github.com/dartsim/dart/commit/47274b551bd48a31a702b4ddc7c1f8061daef3d9.patch?full_index=1"
    sha256 "030e16a5728e856d0cc1788494da50272c52a7efec5c2a93e95de2cda7407f23"
  end

  def install
    ENV.cxx11
    args = std_cmake_args

    if OS.mac?
      # Force to link to system GLUT (see: https://cmake.org/Bug/view.php?id=16045)
      glut_lib = "#{MacOS.sdk_path}/System/Library/Frameworks/GLUT.framework"
      args << "-DGLUT_glut_LIBRARY=#{glut_lib}"
    end

    mkdir "build" do
      system "cmake", "..", *args, "-DCMAKE_INSTALL_RPATH=#{rpath}"
      system "make", "install"
    end

    # Add rpath to shared libraries
    Dir[lib/"libdart*.6.10.0.dylib"].each do |l|
      macho = MachO.open(l)
      macho.add_rpath(opt_lib.to_s)
      macho.write!
    end

    # Clean up the build file garbage that has been installed.
    rm_r Dir["#{share}/doc/dart/**/CMakeFiles/"]
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <dart/dart.hpp>
      int main() {
        auto world = std::make_shared<dart::simulation::World>();
        assert(world != nullptr);
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-I#{Formula["eigen"].include}/eigen3",
                    "-I#{include}", "-L#{lib}", "-ldart",
                    "-L#{Formula["assimp"].opt_lib}", "-lassimp",
                    "-L#{Formula["boost"].opt_lib}", "-lboost_system",
                    "-std=c++14", "-o", "test"
    ENV.append_path "DYLD_FALLBACK_LIBRARY_PATH", Formula["dartsim@6.10.0"].opt_lib
    ENV.append_path "DYLD_FALLBACK_LIBRARY_PATH", Formula["assimp"].opt_lib
    ENV.append_path "DYLD_FALLBACK_LIBRARY_PATH", Formula["octomap"].opt_lib
    system "./test"
  end
end
