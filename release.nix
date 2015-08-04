with import <nixpkgs/lib>;

let
  libhttpseverywhere = pkgs: with pkgs; stdenv.mkDerivation rec {
    name = "libhttpseverywhere-${version}";
    version = "0.0.2";
    src = fetchgit {
        url = "https://github.com/grindhold/libhttpseverywhere/";
        sha256 = "0hp9szklp8g5bkcm47vbkhspwjdm5x4ghhgwp9yd201s2qkl0hsq";
        rev = "5827c6bca6891a136e4f93768f642f57b5d1cbd9"; # Version 0.0.2
        fetchSubmodules = true;
    };
    patches = [ ./libhttpseverywhere_no_rulesets_target.patch ];
    dontUseCmakeBuildDir = true;
    buildInputs = [
      cmake vala_0_28 pkgconfig glib gtk3 gnome3.libgee libxml2 git
    ];
  };

  rainbowLollipop = pkgs: with pkgs; stdenv.mkDerivation rec {
    name = "rainbow-lollipop-${version}";
    version = "0.0.1";
    src = ./.;

    dontUseCmakeBuildDir = true;
    buildInputs = [
      cmake vala_0_28 zeromq pkgconfig glib gtk3 clutter_gtk webkitgtk
      gnome3.libgee sqlite gettext epoxy (libhttpseverywhere pkgs)
    ] ++ optionals (!(stdenv ? cross)) [
      udev xorg.libpthreadstubs xorg.libXdmcp xorg.libxshmfence libxkbcommon
    ];
  };

  supportedSystems = [
    "i686-linux" "x86_64-linux" "i686-w64-mingw32" "x86_64-w64-mingw32"
  ];

  getSysAttrs = system: if hasSuffix "-w64-mingw32" system then {
    crossSystem = let
      is64 = hasPrefix "x86_64" system;
    in {
      config = system;
      arch = if is64 then "x86_64" else "x86";
      libc = "msvcrt";
      platform = {};
      openssl.system = "mingw${optionalString is64 "64"}";
    };
  } else {
    inherit system;
  };

  withSystem = system: let
    sysAttrs = getSysAttrs system;
    pkgs = import <nixpkgs> sysAttrs;
    result = rainbowLollipop pkgs;
  in if sysAttrs ? crossSystem then result.crossDrv else result;

in {
  build = genAttrs supportedSystems withSystem;
}
