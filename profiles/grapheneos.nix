{ config, pkgs, lib, ... }:
with lib;
let
  release = rec {
    marlin = {
      tag = "PQ3A.190801.002.2019.08.25.15";
      sha256 = "17776v5hxkz9qyijhaaqcmgdx6lhrm6kbc5ql9m3rq043av27ihw";
    };
    taimen = marlin;
    crosshatch = marlin;
    bonito = {
      tag = "PQ3B.190801.002.2019.08.25.15";
      sha256 = "1w4ymqhqwyy8gc01aq5gadg3ibf969mhnh5z655cv8qz21fpiiha";
    };
  }.${config.deviceFamily};

  # Hack for crosshatch since it uses submodules and repo2nix doesn't support that yet.
  kernelSrc = pkgs.fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "kernel_google_${config.deviceFamily}";
    rev = release.tag;
    sha256 = {
      crosshatch = "1r3pj5fv2a2zy1kjm9cc49j5vmscvwpvlx5hffhc9r8jbc85acgi";
      bonito = "071kxvmch43747a3vprf0igh5qprafdi4rjivny8yvv41q649m4z";
    }.${config.deviceFamily};
    fetchSubmodules = true;
  };
in
{
  imports = [ ./common.nix ./pixel.nix ];

  source.manifest = {
    url = mkDefault "https://github.com/GrapheneOS/platform_manifest.git";
    rev = mkDefault "refs/tags/${release.tag}";
    sha256 = mkDefault release.sha256;
  };

  # Hack for crosshatch since it uses submodules and repo2nix doesn't support that yet.
  kernel.src = mkDefault (if (elem config.deviceFamily ["crosshatch" "bonito"])
    then kernelSrc
    else config.source.dirs."kernel/google/${replaceStrings ["taimen"] ["wahoo"] config.deviceFamily}".contents);
  kernel.configName = mkIf (elem config.deviceFamily ["taimen" "crosshatch"]) (mkForce config.device); # GrapheneOS uses different config names than upstream

  # No need to include these in AOSP build since we build separately
  source.dirs."kernel/google/marlin".enable = false;
  source.dirs."kernel/google/wahoo".enable = false;
  source.dirs."kernel/google/crosshatch".enable = false;
  source.dirs."kernel/google/bonito".enable = false;

  apps.webview.enable = mkDefault true;
  # TODO: Build and include vanadium
  removedProductPackages = [ "Vanadium" ];

  apps.updater.enable = mkDefault true;

  # Don't include upstream if we use the patched version
  source.dirs."packages/apps/Updater".enable = mkIf config.apps.updater.enable false;

  # Leave the existing auditor in the build--just in case the use wants to
  # audit devices using the official upstream build

  source.dirs."vendor/android-prepare-vendor".enable = false; # Use our own version
}
