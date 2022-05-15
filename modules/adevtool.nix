# SPDX-FileCopyrightText: 2021 Daniel Fullmer
# SPDX-License-Identifier: MIT

{ config, pkgs, lib, ... }:

let
  inherit (lib) types;

  cfg = config.adevtool;

  # This also emits patches for the sepolicy dirs.
  # TODO: Actually use the patches
  vendor = pkgs.runCommand "adevtool-vendor" {
    outputs = [ "out" "sepolicyPatches" ];
  } ''
    ${lib.concatStringsSep "\n" (map (sedir: ''
      set -x
      mkdir -p $(dirname ${sedir})
      cp -a ${config.source.dirs.${sedir}.src} ${sedir}
      chmod u+w ${sedir} -R
      set +x
    '') cfg.sepolicySourceDirs)}

    ${pkgs.adevtool}/bin/adevtool \
      generate-all \
      ${pkgs.adevtool.src}/config/pixel/${config.device}.yml \
      -c ${cfg.stateFile} \
      -s ${config.build.apv.unpackedImg} \
      -a ${pkgs.robotnix.build-tools}/aapt2

    ${pkgs.adevtool}/bin/adevtool \
      fix-certs \
      -d ${config.device} \
      -s ${config.build.apv.unpackedImg} \
      -p ${lib.concatStringsSep " " cfg.sepolicySourceDirs}

    mv vendor/google_devices $out

    ${builtins.concatStringsSep "\n" (map (sedir: ''
      echo -n "Generating patches for ${sedir}... "
      mkdir -p $sepolicyPatches/$(dirname ${sedir})

      set +e
      diff -Naur ${config.source.dirs.${sedir}.src} ${sedir} > $sepolicyPatches/${sedir}.patch
      status=$?
      case $status in
        0)
          echo "No differences"
          ;;
        1)
          echo "Patch generated"
          ;;
        *)
          echo "Failed ($status)"
          exit $status
          ;;
      esac
      set -e
    '') cfg.sepolicySourceDirs)}
  '';
in {
  options = {
    adevtool = {
      enable = lib.mkEnableOption "adevtool";

      stateFile = lib.mkOption {
        description = ''
          The state file to use.

          The state file can be generated by following
          <https://github.com/kdrag0n/adevtool/blob/main/docs/pixel-generate.md>.
        '';
        type = types.path;
      };

      sepolicySourceDirs = lib.mkOption {
        description = ''
          A list of source dirs that contain sepolicy files.

          adevtools will patch the source dirs to add the correct signing certificates
          so special SELinux domains are correctly assigned.
        '';
        example = [
          "hardware/google/pixel-sepolicy"
          "hardware/google/gs101-sepolicy"
        ];
        default = [];
        type = types.listOf types.str;
      };
    };
  };

  config = lib.mkIf config.adevtool.enable (lib.mkMerge [
    {
      source.dirs."vendor/google_devices".src = vendor;
    }
    #{
    #  source.dirs = lib.listToAttrs (map (name: {
    #    inherit name;
    #    value = {
    #      patches = [ "${vendor.sepolicyPatches}/${name}.patch" ];
    #    };
    #  }) cfg.sepolicySourceDirs);
    #}
  ]);
}