class IgnitionGarden < Formula
  include Language::Python::Virtualenv

  desc "Collection of gazebo simulation software"
  homepage "https://github.com/gazebosim/gz-garden"
  url "https://github.com/gazebosim/gz-garden.git", branch: "main"
  version "0.999.999~0~20220414"
  license "Apache-2.0"

  head "https://github.com/gazebosim/gz-garden.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "gz-cmake3"
  depends_on "gz-common5"
  depends_on "gz-fuel-tools8"
  depends_on "gz-gui7"
  depends_on "gz-launch6"
  depends_on "gz-math7"
  depends_on "gz-msgs9"
  depends_on "gz-physics6"
  depends_on "gz-plugin2"
  depends_on "gz-rendering7"
  depends_on "gz-sensors7"
  depends_on "gz-sim7"
  depends_on "gz-tools2"
  depends_on "gz-transport12"
  depends_on "gz-utils2"
  depends_on macos: :mojave # c++17
  depends_on "pkg-config"
  depends_on "sdformat13"

  resource "PyYAML" do
    url "https://files.pythonhosted.org/packages/64/c2/b80047c7ac2478f9501676c988a5411ed5572f35d1beff9cae07d321512c/PyYAML-5.3.1.tar.gz"
    sha256 "b8eac752c5e14d3eca0e6dd9199cd627518cb5ec06add0de9d32baeee6fe645d"
  end

  def install
    mkdir "build" do
      system "cmake", "..", *std_cmake_args
      system "make", "install"
    end

    venv = virtualenv_create(libexec, Formula["python@3.9"].opt_bin/"python3")
    %w[PyYAML vcstool].each do |pkg|
      venv.pip_install pkg
    end
  end

  test do
    # TODO: migrate ignition to gz when IGN_DATA_INSTALL_DIR is migrated
    yaml_file = share/"ignition/gz-garden/gazebodistro/collection-garden.yaml"
    system libexec/"bin/vcs", "validate", "--input", yaml_file
  end
end
