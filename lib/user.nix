let
  base = import ../user.nix;
  localPath = ../user.local.nix;
  local =
    if builtins.pathExists localPath
    then import localPath
    else {};
  normalizeGpuVendor = value: let
    normalized =
      builtins.replaceStrings
      [
        "A"
        "B"
        "C"
        "D"
        "E"
        "F"
        "G"
        "H"
        "I"
        "J"
        "K"
        "L"
        "M"
        "N"
        "O"
        "P"
        "Q"
        "R"
        "S"
        "T"
        "U"
        "V"
        "W"
        "X"
        "Y"
        "Z"
      ]
      [
        "a"
        "b"
        "c"
        "d"
        "e"
        "f"
        "g"
        "h"
        "i"
        "j"
        "k"
        "l"
        "m"
        "n"
        "o"
        "p"
        "q"
        "r"
        "s"
        "t"
        "u"
        "v"
        "w"
        "x"
        "y"
        "z"
      ]
      (toString value);
  in
    if
      builtins.elem normalized [
        "amd"
        "ati"
        "radeon"
      ]
    then "amd"
    else if normalized == "nvidia"
    then "nvidia"
    else if normalized == "intel"
    then "intel"
    else "generic";

  merged = base // local;
  dotroot =
    if local ? dotroot
    then local.dotroot
    else if base ? dotroot
    then base.dotroot
    else "/home/${merged.name}/Documents/MD4N";
  homemanager =
    if local ? homemanager
    then local.homemanager
    else if base ? homemanager
    then base.homemanager
    else "${dotroot}/home-manager";
in
  merged
  // {
    home =
      if local ? home
      then local.home
      else if base ? home
      then base.home
      else "/home/${merged.name}";
    inherit dotroot homemanager;
    cfg =
      if local ? cfg
      then local.cfg
      else if base ? cfg
      then base.cfg
      else "${homemanager}/config";
    app =
      if local ? app
      then local.app
      else if base ? app
      then base.app
      else "${homemanager}/applications";
    gpuVendor = normalizeGpuVendor (merged.gpuVendor or "generic");
  }
