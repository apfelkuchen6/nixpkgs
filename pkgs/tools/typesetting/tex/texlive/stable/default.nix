{ callPackage, lib, fetchurl, useFixedHashes ? true, fetchpatch }:
let attrs = (callPackage ./../make-texlive.nix rec {
  version = {
    texliveYear = 2022;
    final = true;
  };

  urlPrefixes = with version; [
    # tlnet-final snapshot; used when texlive.tlpdb is frozen
    # the TeX Live yearly freeze typically happens in mid-March
    "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${toString texliveYear}/tlnet-final"
    "ftp://tug.org/texlive/historic/${toString texliveYear}/tlnet-final"
  ];

  src = let year = toString tlpdb."00texlive.config".year;
  in fetchurl {
    urls = [
      "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${year}/texlive-${year}0321-source.tar.xz"
      "ftp://tug.ctan.org/pub/tex/historic/systems/texlive/${year}/texlive-${year}0321-source.tar.xz"
    ];
    hash = "sha256-X/o0heUessRJBJZFD8abnXvXy55TNX2S20vNT9YXm1Y=";
  };

  tlpdb = import ./tlpdb.nix;
  tlpdbxzHash = "sha256-vm7DmkH/h183pN+qt1p1wZ6peT2TcMk/ae0nCXsCoMw=";

  fixedHashes = lib.optionalAttrs useFixedHashes (import ./fixed-hashes.nix);
  inherit useFixedHashes;
}
).overrideScope (self: super: {
  bin = super.bin // {
    # fixes a security-issue in luatex that allows arbitrary code execution even with shell-escape disabled,
    # see https://tug.org/~mseven/luatex.html for more details
    core-big = super.bin.core-big.overrideAttrs (olds: {
      patches = olds.patches ++ [
        (fetchpatch {
          name = "CVE-2023-32700.patch";
          url = "https://tug.org/~mseven/luatex-files/2022/patch";
          hash = "sha256-o9ENLc1ZIIOMX6MdwpBIgrR/Jdw6tYLmAyzW8i/FUbY=";
          excludes = [ "build.sh" ];
          stripLen = 1;
        })
      ];
    });
  };
});

in
# also expose the texlivePackages in the top level (`pkgs.texlive`) for compatibility reasons
attrs.texlivePackages // attrs
