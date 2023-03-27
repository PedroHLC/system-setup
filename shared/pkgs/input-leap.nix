{ barrier, input-leap-git-src, qttools, pkg-config, gtest, ghc_filesystem }:

# Latest input-leap through barrier
barrier.overrideAttrs (pa: {
  src = input-leap-git-src;
  nativeBuildInputs = pa.nativeBuildInputs ++ [
    pkg-config
    gtest
    ghc_filesystem
  ];
  buildInputs = pa.buildInputs ++ [
    qttools
  ];
  patches = [ ];
  cmakeFlags = [ "-DINPUTLEAP_USE_EXTERNAL_GTEST=ON" ];
  postFixup = ''
    substituteInPlace "$out/share/applications/input-leap.desktop" --replace "Exec=input-leap" "Exec=$out/bin/input-leap"
  '';
})
