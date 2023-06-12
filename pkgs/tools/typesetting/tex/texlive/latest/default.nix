{ callPackage, texlive_latest, lib, fetchurl, useFixedHashes ? true }:
let
  version = {
    # day of the snapshot being taken
    year = "2023";
    month = "06";
    day = "06";
    # TeX Live version
    texliveYear = 2023;
    # final (historic) release or snapshot
    final = false;
  };

  # The tarballs on CTAN mirrors for the current release are constantly
  # receiving updates, so we can't use those directly. Stable snapshots
  # need to be used instead. Ideally, for the release branches of NixOS we
  # should be switching to the tlnet-final versions
  # (https://tug.org/historic/).
  urlPrefixes = with version;
    [
      # CTAN mirror, not frozen, might result in misses
      "https://ftp.rrze.uni-erlangen.de/ctan/systems/texlive/tlnet"
      # daily snapshots hosted by one of the texlive release managers, guaranteed to have the pinned versions
      "https://texlive.info/tlnet-archive/${year}/${month}/${day}/tlnet"
    ];

  tlpdbxz = fetchurl {
    url = (up: "${up}/tlpkg/texlive.tlpdb.xz") (lib.last urlPrefixes);
    hash = "sha256-gkvU7XB/uLdEMLT5nyVYd18ioOwjNV8cLQVG1MwfBEc=";
  };

  tlpdb = import ./../stable/tlpdb.nix // import ./tlpdb-latest-diff.nix;

  src = let year = toString tlpdb."00texlive.config".year;
  in fetchurl {
    urls = [
      "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${year}/texlive-${year}0313-source.tar.xz"
      "ftp://tug.ctan.org/pub/tex/historic/systems/texlive/${year}/texlive-${year}0313-source.tar.xz"
    ];
    hash = "sha256-OHiqDh7QMBwFOw4u5OmtmZxEE0X0iC55vdHI9M6eebk=";
  };

  fixedHashes = lib.optionalAttrs useFixedHashes (import ./../stable/fixed-hashes.nix // import ./fixed-hashes-latest-diff.nix);
in
callPackage ./../default.nix {
  inherit version tlpdb tlpdbxz fixedHashes urlPrefixes src useFixedHashes;
  texlive = texlive_latest;
}
