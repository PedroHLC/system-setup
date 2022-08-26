{ lib, stdenv, fetchzip }:
let
  modversion = "4.0";
in
stdenv.mkDerivation (rec {
  version = "${modversion}.1";
  pname = "anime4k";

  src = fetchzip {
    #url = "https://dl.opendesktop.org/api/files/download/id/${fileId}/${fileName}";
    url = "https://github.com/bloc97/Anime4K/releases/download/v${version}/Anime4K_v${modversion}.zip";
    hash = "sha256-9B6U+KEVlhUIIOrDauIN3aVUjZ/gQHjFArS4uf/BpaM=";
    #stripRoot = false;
  };

  dontBuild = true;
  sourceRoot = ".";

  installPhase = ''
    mkdir "$out"
    cp -dr source/* "$out/"
  '';

  meta = {
    description = " A High-Quality Real Time Upscaler for Anime Video ";
    homepage = "https://bloc97.github.io/Anime4K/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
