{ lib, finalTlpdb, bin, callPackage, fixedHashes, texlivePackages, mirrors, }:
let
    buildTeXLivePackage = callPackage ./build-texlive-package.nix { };
in

  lib.mapAttrs (pname: { revision, extraRevision ? "", ... }@args:
    buildTeXLivePackage (args
      # NOTE: the fixed naming scheme must match generate-fixed-hashes.nix
      // { texliveBinaries = bin; inherit mirrors pname; fixedHashes = fixedHashes."${pname}-${toString revision}${extraRevision}" or { }; }
      // lib.optionalAttrs (args ? deps) { deps = map (n: texlivePackages.${n}) (args.deps or [ ]); })
  ) finalTlpdb
