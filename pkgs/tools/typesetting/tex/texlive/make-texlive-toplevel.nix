/* TeX Live user docs
  - source: ../../../../../doc/languages-frameworks/texlive.xml
  - current html: https://nixos.org/nixpkgs/manual/#sec-language-texlive
*/
{ makeScopeWithSplicing, generateSplicesForMkScope
, lib, fetchurl, runCommand, recurseIntoAttrs
, ghostscript_headless, harfbuzz, biber
, tlpdb, tlpdbxzHash, src, texliveVersion, mirrors, useFixedHashes ? true, fixedHashes ? {}
}:
let
  texlive = makeScopeWithSplicing (generateSplicesForMkScope "texlive") (_extra: { }) (_keep: { }) (self:
    let
      callPackage = self.newScope {inherit tlpdb tlpdbxzHash src texliveVersion mirrors useFixedHashes fixedHashes; };
    in {

    inherit callPackage;

    # various binaries (compiled)
    bin = callPackage ./bin.nix {
      biber = biber.override { texlive = self; };
      ghostscript = ghostscript_headless;
      harfbuzz = harfbuzz.override {
        withIcu = true; withGraphite2 = true;
      };
    };

    # function for creating a working environment from a set of TL packages
    combine =#  let
      # tlpdbVersion = tlpdb."00texlive.config";

      # assertions = with lib;
      #   assertMsg (tlpdbVersion.year == texliveVersion.texliveYear) "TeX Live year in texlive does not match tlpdb.nix, refusing to evaluate" &&
      #   assertMsg (tlpdbVersion.frozen == texliveVersion.final) "TeX Live final status in texlive does not match tlpdb.nix, refusing to evaluate" &&
      #   (!useFixedHashes ||
      #     (let all = concatLists (catAttrs "pkgs" (attrValues self.texlivePackages));
      #       fods = filter (p: isDerivation p && p.tlType != "bin") all;
      #     in builtins.all (p: assertMsg (p ? outputHash) "The TeX Live package '${p.pname + lib.optionalString (p.tlType != "run") ("." + p.tlType)}' does not have a fixed output hash. Please read UPGRADING.md on how to build a new 'fixed-hashes.nix'.") fods));

      # in assert assertions;
        callPackage ./combine.nix {
        ghostscript = ghostscript_headless;
      };

    overrides = callPackage ./overrides.nix { tlpdbxz = self.tlpdb.xz; };

    texlivePackages = callPackage ./package-set.nix { };

    finalTlpdb = self.overrides tlpdb;

    tlpdb = rec {
      # nested in an attribute set to prevent them from appearing in search
      xz = fetchurl {
        urls = map (up: "${up}/tlpkg/texlive.tlpdb.xz") mirrors;
        hash = tlpdbxzHash;
      };

      nix = runCommand "tlpdb.nix" {
        tlpdbxz = xz;
        tl2nix = ./tl2nix.sed;
      }
      ''
        xzcat "$tlpdbxz" | sed -rn -f "$tl2nix" | uniq > "$out"
      '';
    };

    # Pre-defined combined packages for TeX Live schemes,
    # to make nix-env usage more comfortable and build selected on Hydra.
    combined = with lib;
      let
        # these license lists should be the sorted union of the licenses of the packages the schemes contain.
        # The correctness of this collation is tested by tests.texlive.licenses
        licenses = with lib.licenses; {
          scheme-basic = [ free gfl gpl1Only gpl2 gpl2Plus knuth lgpl21 lppl1 lppl13c mit ofl publicDomain ];
          scheme-context = [ bsd2 bsd3 cc-by-sa-40 free gfl gfsl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus knuth lgpl2 lgpl21
            lppl1 lppl13c mit ofl publicDomain x11 ];
          scheme-full = [ artistic1 artistic1-cl8 asl20 bsd2 bsd3 bsdOriginal cc-by-10 cc-by-40 cc-by-sa-10 cc-by-sa-20
            cc-by-sa-30 cc-by-sa-40 cc0 fdl13Only free gfl gfsl gpl1Only gpl1Plus gpl2 gpl2Plus gpl3 gpl3Plus isc knuth
            lgpl2 lgpl21 lgpl3 lppl1 lppl12 lppl13a lppl13c mit ofl publicDomain x11 ];
          scheme-gust = [ artistic1-cl8 asl20 bsd2 bsd3 cc-by-40 cc-by-sa-40 cc0 fdl13Only free gfl gfsl gpl1Only gpl2
            gpl2Plus gpl3 gpl3Plus knuth lgpl2 lgpl21 lppl1 lppl12 lppl13a lppl13c mit ofl publicDomain x11 ];
          scheme-infraonly = [ gpl2 lgpl21 ];
          scheme-medium = [ artistic1-cl8 asl20 bsd2 bsd3 cc-by-40 cc-by-sa-20 cc-by-sa-30 cc-by-sa-40 cc0 fdl13Only
            free gfl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus isc knuth lgpl2 lgpl21 lgpl3 lppl1 lppl12 lppl13a lppl13c mit ofl
            publicDomain x11 ];
          scheme-minimal = [ free gpl1Only gpl2 gpl2Plus knuth lgpl21 lppl1 lppl13c mit ofl publicDomain ];
          scheme-small = [ asl20 cc-by-40 cc-by-sa-40 cc0 fdl13Only free gfl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus knuth
            lgpl2 lgpl21 lppl1 lppl12 lppl13a lppl13c mit ofl publicDomain x11 ];
          scheme-tetex = [ artistic1-cl8 asl20 bsd2 bsd3 cc-by-40 cc-by-sa-10 cc-by-sa-20 cc-by-sa-30 cc-by-sa-40 cc0
            fdl13Only free gfl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus isc knuth lgpl2 lgpl21 lgpl3 lppl1 lppl12 lppl13a
            lppl13c mit ofl publicDomain x11];
        };
      in recurseIntoAttrs (
      mapAttrs
        (pname: attrs:
          addMetaAttrs rec {
            description = "TeX Live environment for ${pname}";
            platforms = lib.platforms.all;
            maintainers = with lib.maintainers;  [ veprbl ];
            license = licenses.${pname};
          }
          (self.combine {
            ${pname} = attrs;
            extraName = "combined" + lib.removePrefix "scheme" pname;
            extraVersion = with texliveVersion; if final then "-final" else ".${year}${month}${day}";
          })
        )
        { inherit (self.texlivePackages)
            scheme-basic scheme-context scheme-full scheme-gust scheme-infraonly
            scheme-medium scheme-minimal scheme-small scheme-tetex;
        }
    );
  });

  applyOverScope = f: scope: f (scope // {
    overrideScope = g: applyOverScope f (scope.overrideScope g);
  });

  # for backward compability
  compatFixups = scope:
    scope.texlivePackages // scope // {
      bin = scope.bin // {
        latexindent = lib.findFirst (p: p.tlType == "bin") scope.texlivePackages.latexindent.pkgs;
      };
    };

in applyOverScope compatFixups texlive
