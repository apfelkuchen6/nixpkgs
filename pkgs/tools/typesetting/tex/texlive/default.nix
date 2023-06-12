/* TeX Live user docs
  - source: ../../../../../doc/languages-frameworks/texlive.xml
  - current html: https://nixos.org/nixpkgs/manual/#sec-language-texlive
*/
{ lib, newScope
, fetchurl
, ghostscript_headless, harfbuzz
, tlpdb, version, fixedHashes, urlPrefixes, tlpdbxzHash, src, useFixedHashes
}@args:

lib.makeScope newScope (self: with self; {

  # various binaries (compiled)
  bin = assert assertions; self.callPackage ./bin.nix {
    ghostscript = ghostscript_headless;
    harfbuzz = harfbuzz.override { withIcu = true; withGraphite2 = true; };
    inherit useFixedHashes;
    # version specific stuff
    inherit src;
    year = version.texliveYear;
  };

  # function for creating a working environment from a set of TL packages
  combine = assert assertions; self.callPackage ./combine.nix {
    ghostscript = ghostscript_headless;
  };

  # the set of TeX Live packages, collections, and schemes; using upstream naming
  texlivePackages = self.callPackage  ./make-texlive-packages.nix {
    inherit (args) useFixedHashes fixedHashes tlpdb urlPrefixes;
    tlpdbxz = self.tlpdb.tlpdbxz;
  };

  # nested in an attribute set to prevent them from appearing in search
  tlpdb = {
    tlpdbxz = fetchurl {
      url = (up: "${up}/tlpkg/texlive.tlpdb.xz") (lib.last urlPrefixes);
      hash = tlpdbxzHash;
    };

    tlpdbNix = runCommand "tlpdb.nix" {
      inherit tlpdbxz;
      tl2nix = ./tl2nix.sed;
    }
    ''
      xzcat "$tlpdbxz" | sed -rn -f "$tl2nix" | uniq > "$out"
    '';
  };

  combined = with lib; recurseIntoAttrs (
    mapAttrs
      (pname: attrs:
        addMetaAttrs rec {
          description = "TeX Live environment for ${pname}";
          platforms = lib.platforms.all;
          maintainers = with lib.maintainers;  [ veprbl ];
        }
        (self.combine {
          ${pname} = attrs;
          extraName = "combined" + lib.removePrefix "scheme" pname;
          extraVersion = with version; if final then "-final" else ".${year}${month}${day}";
        })
      )
      { inherit (self.texlivePackages)
          scheme-basic scheme-context scheme-full scheme-gust scheme-infraonly
          scheme-medium scheme-minimal scheme-small scheme-tetex;
      }
  );

  assertions = let tlpdbVersion = tlpdb."00texlive.config"; in with lib;
    assertMsg (tlpdbVersion.year == version.texliveYear) "TeX Live year in texlive does not match tlpdb.nix, refusing to evaluate" &&
    assertMsg (tlpdbVersion.frozen == version.final) "TeX Live final status in texlive does not match tlpdb.nix, refusing to evaluate" &&
    (!useFixedHashes ||
     (let all = concatLists (catAttrs "pkgs" (attrValues (filterAttrs (n: isDerivation) self.texlivePackages)));
         fods = filter (p: isDerivation p && p.tlType != "bin") all;
      in builtins.all (p: assertMsg (p ? outputHash) "The TeX Live package '${p.pname + lib.optionalString (p.tlType != "run") ("." + p.tlType)}' does not have a fixed output hash. Please read UPGRADING.md on how to build a new 'fixed-hashes.nix'.") fods));
})
