{ callPackage, lib, fetchurl, useFixedHashes ? true
, luametatex, runCommand, makeWrapper, mupdf, potrace, fetchpatch }:
(callPackage ./../make-texlive-toplevel.nix rec {
  texliveVersion = {
    # day of the snapshot being taken
    year = "2023";
    month = "08";
    day = "07";
    # TeX Live version
    texliveYear = 2023;
    # final (historic) release or snapshot
    final = false;
  };

  mirrors = with texliveVersion; [
    # CTAN mirror, not frozen, might result in misses
    # "https://ftp.rrze.uni-erlangen.de/ctan/systems/texlive/tlnet"
    # daily snapshots hosted by one of the texlive release managers, guaranteed to have the pinned versions
    "https://texlive.info/tlnet-archive/${year}/${month}/${day}/tlnet"
  ];

  src = with texliveVersion; fetchurl {
    urls = [
      "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${toString texliveYear}/texlive-${toString texliveYear}0313-source.tar.xz"
      "ftp://tug.ctan.org/pub/tex/historic/systems/texlive/${toString texliveYear}/texlive-${toString texliveYear}0313-source.tar.xz"
    ];
    hash = "sha256-OHiqDh7QMBwFOw4u5OmtmZxEE0X0iC55vdHI9M6eebk=";
  };
  tlpdb = import ./tlpdb.nix;
  tlpdbxzHash = "sha256-bu3zEJcveJQz735PNYFllTql50kv74jNYeuGCNIkX0Y=";

  fixedHashes = lib.optionalAttrs useFixedHashes (import ./fixed-hashes.nix);
  inherit useFixedHashes;
}).overrideScope (self: super: {
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

    dvisvgm = super.bin.dvisvgm.overrideAttrs (olds: {
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

      #> ERROR: To process PDF files, either Ghostscript < 10.1 or mutool is required.
      nativeBuildInputs = olds.nativeBuildInputs ++ [ makeWrapper ];
      postFixup = ''
        wrapProgram $out/bin/dvisvgm --prefix PATH : ${mupdf}/bin
      '';
    });
  };

  overrides = args:
    let old = super.overrides args; in
    removeAttrs old ["context-inifile" "context-lettrine" "npp-for-context" "penrose" "tablestyles" ];
})
