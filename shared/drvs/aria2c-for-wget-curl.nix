{ fetchFromGitHub, aria2, curl, wget, python3, stdenvNoCC }:

stdenvNoCC.mkDerivation rec {
  pname = "aria2c-for-wget-curl";
  version = "2020-06-22";

  src = fetchFromGitHub {
    owner = "SaiHarshaK";
    repo = "aria2c-for-wget-curl";
    rev = "605ed893a482687f87eb36a52227701f01dbadbd";
    hash = "sha256-uiyzwYypvtGIb1TylQJYbrF/ATV6MIGLzks1KtNZiwU=";
    sparseCheckout = [
      "curl"
      "wget"
    ];
  };

  dontBuild = true;

  nativeBuildInputs = [ python3 ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    mv wget/__main__.py $out/bin/wget
    mv curl/__main__.py $out/bin/curl
    chmod +x $out/bin/*

    patchShebangs $out/bin/*

    substituteInPlace $out/bin/curl \
      --replace-fail "cmd.append('curl-orig')" "cmd.append('${curl}/bin/curl')" \
      --replace-fail 'cmd.append("aria2c")' "cmd.append('${aria2}/bin/aria2c')"

    substituteInPlace $out/bin/wget \
      --replace-fail "cmd.append('wget-orig')" "cmd.append('${wget}/bin/wget')" \
      --replace-fail 'cmd.append("aria2c")' "cmd.append('${aria2}/bin/aria2c')"

    runHook postInstall
  '';
}
