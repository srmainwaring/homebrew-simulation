class Ogre22 < Formula
  desc "Scene-oriented 3D engine written in c++"
  homepage "https://www.ogre3d.org/"
  version "2.2.5"
  license "MIT"
  revision 1

  head "https://github.com/srmainwaring/ogre-next.git", branch: "feature/v2-2-egl-macos-texstorage"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :test
  depends_on "doxygen"
  depends_on "freeimage"
  depends_on "freetype"
  depends_on "libx11"
  depends_on "libzzip"
  depends_on "rapidjson"
#   depends_on "tbb"

  def install
    cmake_args = [
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
        "-DCMAKE_CXX_FLAGS='-I/usr/local/include -F/Library/Frameworks'",
        "-DCMAKE_CXX_STANDARD=11",
        "-DCMAKE_OSX_ARCHITECTURES='x86_64'",
        "-DOGRE_FULL_RPATH:BOOL=FALSE",
        "-DOGRE_GLSUPPORT_USE_GLX:BOOL=FALSE",
        "-DOGRE_BUILD_LIBS_AS_FRAMEWORKS:BOOL=FALSE",
        "-DOGRE_BUILD_RENDERSYSTEM_GL3PLUS:BOOL=TRUE",
        "-DOGRE_BUILD_SAMPLES2:BOOL=TRUE",
        "-DOGRE_BUILD_SAMPLES_AS_BUNDLES:BOOL=FALSE",
        "-DOGRE_BUILD_TESTS:BOOL=FALSE",
        "-DOGRE_BUILD_TOOLS:BOOL=TRUE",
        "-DOGRE_INSTALL_SAMPLES:BOOL=TRUE",
        "-DOGRE_INSTALL_TOOLS:BOOL=TRUE",
        "-DOGRE_LIB_DIRECTORY=lib/OGRE-2.2"
      ]

    cmake_args.concat std_cmake_args

    mkdir "build" do
        system "cmake", "..", *cmake_args
        system "make", "-j16"
        system "make", "install"
      end

    # Put these cmake files where Debian puts them
    (share/"OGRE-2.2/cmake/modules").install Dir[prefix/"CMake/*.cmake"]
    rmdir prefix/"CMake"

    # Support side-by-side OGRE installs
    # Move headers
    (include/"OGRE-2.2").install Dir[include/"OGRE/*"]
    rmdir include/"OGRE"

    # Move and update .pc files
    lib.install Dir[lib/"OGRE-2.2/pkgconfig"]
    Dir[lib/"pkgconfig/*"].each do |pc|
      mv pc, pc.sub("pkgconfig/OGRE", "pkgconfig/OGRE-2.2")
    end
    inreplace Dir[lib/"pkgconfig/*"] do |s|
      s.gsub! prefix, opt_prefix
      s.sub! "Name: OGRE", "Name: OGRE-2.2"
      s.sub!(/^includedir=.*$/, "includedir=${prefix}/include/OGRE-2.2")
    end
    inreplace (lib/"pkgconfig/OGRE-2.2.pc"), " -I${includedir}\/OGRE", ""
    inreplace (lib/"pkgconfig/OGRE-2.2-MeshLodGenerator.pc"), "-I${includedir}/OGRE/", "-I${includedir}/"
    inreplace (lib/"pkgconfig/OGRE-2.2-Overlay.pc"), "-I${includedir}/OGRE/", "-I${includedir}/"

    # Move versioned libraries (*.2.2.5.dylib) to standard location and remove symlinks
    lib.install Dir[lib/"OGRE-2.2/lib*.2.2.5.dylib"]
    rm Dir[lib/"OGRE-2.2/lib*"]

    # Move plugins to subfolder
    (lib/"OGRE-2.2/OGRE").install Dir[lib/"OGRE-2.2/*.dylib"]

    # Restore lib symlinks
    Dir[lib/"lib*"].each do |l|
      (lib/"OGRE-2.2").install_symlink l => File.basename(l.sub(".2.2.5", ""))
    end
  end

  test do
    (testpath/"test.cpp").write <<-EOS
      #include <Ogre.h>
      int main()
      {
        Ogre::Root *root = new Ogre::Root("", "", "");
        delete root;
        return 0;
      }
    EOS
    system "pkg-config", "OGRE-2.2"
    cflags = `pkg-config --cflags OGRE-2.2`.split
    libs = `pkg-config --libs OGRE-2.2`.split
    system ENV.cc, "test.cpp",
                   *cflags,
                   "-std=c++11",
                   *libs,
                   "-lc++",
                   "-o", "test"
    system "./test"
    # check for Xcode frameworks in bottle
    cmd_not_grep_xcode = "! grep -rnI 'Applications[/]Xcode' #{prefix}"
    system cmd_not_grep_xcode
  end
end
