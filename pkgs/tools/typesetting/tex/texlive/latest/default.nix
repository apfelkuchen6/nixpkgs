{ callPackage, lib, fetchurl, useFixedHashes ? true, luametatex, runCommand
, potrace, fetchpatch }:
let attrs = (callPackage ./../default.nix rec {
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
  urlPrefixes = with version; [
    # CTAN mirror, not frozen, might result in misses
    "https://ftp.rrze.uni-erlangen.de/ctan/systems/texlive/tlnet"
    # daily snapshots hosted by one of the texlive release managers, guaranteed to have the pinned versions
    "https://texlive.info/tlnet-archive/${year}/${month}/${day}/tlnet"
  ];

  src = let year = toString tlpdb."00texlive.config".year;
  in fetchurl {
    urls = [
      "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${year}/texlive-${year}0313-source.tar.xz"
      "ftp://tug.ctan.org/pub/tex/historic/systems/texlive/${year}/texlive-${year}0313-source.tar.xz"
    ];
    hash = "sha256-OHiqDh7QMBwFOw4u5OmtmZxEE0X0iC55vdHI9M6eebk=";
  };

  tlpdb = import ./../stable/tlpdb.nix // import ./tlpdb-latest-diff.nix;
  tlpdbxzHash = "sha256-gkvU7XB/uLdEMLT5nyVYd18ioOwjNV8cLQVG1MwfBEc=";

  fixedHashes = lib.optionalAttrs useFixedHashes
    (import ./../stable/fixed-hashes.nix
      // import ./fixed-hashes-latest-diff.nix);
  inherit useFixedHashes;
}
).overrideScope' (self: super: {
  bin = super.bin // {
    core-big = super.bin.core-big.overrideAttrs (olds: {
      # fixes a security-issue in luatex that allows arbitrary code execution even with shell-escape disabled,
      # see https://tug.org/~mseven/luatex.html for more details
      patches = olds.patches ++ [
        (fetchpatch {
          name = "luatex-1.17.patch";
          url = "https://github.com/TeX-Live/texlive-source/commit/871c7a2856d70e1a9703d1f72f0587b9995dba5f.patch";
          hash = "sha256-Ke7nIF/KIiJigxvn0NurMLo032afN6xNC1xhQq+OReQ=";
        })
      ];

      buildInputs = olds.buildInputs ++ [ potrace ];
    });

    dvisvgm = super.bin.dvisvgm.overrideAttrs (_: {
      # the build system tries to 'make' a vendored copy of potrace even
      # though we use --with-system-potrace (and there isn't even a Makefile generated for potrace).
      #
      # Creating a dummy-Makefile that does nothing is easier than fixing the build system.
      postPatch = ''
        cat > texk/dvisvgm/dvisvgm-src/libs/potrace/Makefile <<EOF
        all:
        install:
        EOF
      '';
    });
  };
});

in
# also expose the texlivePackages in the top level (`pkgs.texlive`) for compatibility reasons
attrs.texlivePackages // attrs
