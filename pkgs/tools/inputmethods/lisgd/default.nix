{ lib
, stdenv
, fetchFromSourcehut
, writeText
, libinput
, libX11
, wayland
, conf ? null
, patches ? [ ]
}:

stdenv.mkDerivation rec {
  pname = "lisgd";
  version = "0.3.5";

  src = fetchFromSourcehut {
    owner = "~mil";
    repo = "lisgd";
    rev = version;
    hash = "sha256-NnZhOQ/I7wbGlWkSXFXEV96UfG+GPMz1VSiEc9TwI6Y=";
  };

  inherit patches;

  postPatch = let
    configFile = if lib.isDerivation conf || lib.isPath conf then
      conf
    else
      writeText "config.def.h" conf;
  in lib.optionalString (conf != null) ''
    cp ${configFile} config.def.h
  '';

  buildInputs = [
    libinput
    libX11
    wayland
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    description = "Bind gestures via libinput touch events";
    homepage = "https://git.sr.ht/~mil/lisgd";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ dotlambda ];
  };
}
