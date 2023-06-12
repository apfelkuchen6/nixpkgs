{ callPackage, lib, fetchurl, useFixedHashes ? true }:
let
  version = {
    texliveYear = 2022;
    final = true;
  };

  urlPrefixes = with version;
     [
      # tlnet-final snapshot; used when texlive.tlpdb is frozen
      # the TeX Live yearly freeze typically happens in mid-March
      "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${toString texliveYear}/tlnet-final"
      "ftp://tug.org/texlive/historic/${toString texliveYear}/tlnet-final"
    ];

  tlpdbxz = fetchurl {
    urls = map (up: "${up}/tlpkg/texlive.tlpdb.xz") urlPrefixes;
    hash = "sha256-vm7DmkH/h183pN+qt1p1wZ6peT2TcMk/ae0nCXsCoMw=";
  };

  tlpdb = import ./tlpdb.nix;

  src = let year = toString tlpdb."00texlive.config".year;
  in fetchurl {
    urls = [
      "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${year}/texlive-${year}0321-source.tar.xz"
      "ftp://tug.ctan.org/pub/tex/historic/systems/texlive/${year}/texlive-${year}0321-source.tar.xz"
    ];
    hash = "sha256-X/o0heUessRJBJZFD8abnXvXy55TNX2S20vNT9YXm1Y=";
  };

  fixedHashes = lib.optionalAttrs useFixedHashes (import ./fixed-hashes.nix);

in callPackage ./../default.nix {
  inherit version tlpdb tlpdbxz fixedHashes urlPrefixes src useFixedHashes;
}
