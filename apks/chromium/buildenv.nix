{ pkgs }:
with pkgs;
# TODO: Hack to workaround some android-related prebuilts that need to be fixup'd
# See 32-bit dependencies in src/build/install-build-deps-android
buildFHSUserEnv {
  name = "chromium-fhs";
  targetPkgs = pkgs: with pkgs; [
    # Stuff verified to be needed in chromium
    jdk8
    glibc_multi.dev # Needs unistd.h
    kerberos.dev # Needs headers
    kerberos
    ncurses5
    libxml2
  ];
  multiPkgs = pkgs: with pkgs; [
    zlib
    ncurses5
    gcc
    libgcc # Needed by their clang toolchain
  ];
}
