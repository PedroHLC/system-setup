{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
  # Required
, aircrack-ng
, bash
, gawk
, iproute2
, iw
, pciutils
, procps
, tmux
  # Optionals
  # Missing: beef, hostapd-wpe, asleap 
, bully ? null
, crunch ? null
, dhcp ? null
, dnsmasq ? null
, ettercap ? null
, hashcat ? null
, hcxdumptool ? null
, hcxtools ? null
, hostapd ? null
, lighttpd ? null
, mdk4 ? null
, nftables ? null
, openssl ? null # I wonder which version is needed
, pixiewps ? null
, reaverwps ? null
, wireshark-cli ? null
}:
let
  deps = lib.lists.filter (x: x != null) [
    aircrack-ng
    bash
    gawk
    iproute2
    iw
    pciutils
    procps
    tmux
    bully
    crunch
    dhcp
    dnsmasq
    ettercap
    hashcat
    hcxdumptool
    hcxtools
    hostapd
    lighttpd
    mdk4
    nftables
    openssl
    pixiewps
    reaverwps
    wireshark-cli
  ];
  version = "11.01";
in
stdenv.mkDerivation {
  inherit version;
  pname = "airgeddon";

  src = fetchFromGitHub {
    owner = "v1s1t0r1sh3r3";
    repo = "airgeddon";
    rev = "v${version}";
    sha256 = "3TjaLEcerRk69Ys4kj7vOMCRUd0ifFJzL4MB5ifoK68=";
  };

  strictDeps = true;
  buildInputs = [ makeWrapper ];


  postPatch = ''
    patchShebangs airgeddon.sh
    sed -i '
      s|AIRGEDDON_AUTO_UPDATE=true|AIRGEDDON_AUTO_UPDATE=false|
      s|AIRGEDDON_AUTO_CHANGE_LANGUAGE=true|ARGEDDON_AUTO_CHANGE_LANGUAGE=false|
      s|AIRGEDDON_SILENT_CHECKS=false|AIRGEDDON_SILENT_CHECKS=true|
      s|AIRGEDDON_WINDOWS_HANDLING=xterm|AIRGEDDON_WINDOWS_HANDLING=tmux|
      ' .airgeddonrc

    sed -Ei '
      s|\$\(pwd\)|${placeholder "out"}/share/airgeddon;scriptfolder=${placeholder "out"}/share/airgeddon/|
      s|\$\{0\}|${placeholder "out"}/bin/airgeddon|
      s|tmux send-keys -t "([^"]+)" "|tmux send-keys -t "\1" "export PATH=\\"$PATH\\"; |
      ' airgeddon.sh
  '';

  # ATTENTION: No need to chdir around, we're removing the occurrences of "$(pwd)"
  postInstall = ''
    wrapProgram $out/bin/airgeddon \
      --prefix PATH : ${lib.makeBinPath deps} \
  '';

  installPhase = ''
    runHook preInstall
    install -Dm 755 airgeddon.sh "$out/bin/airgeddon"
    install -Dm 644 LICENSE "$out/share/licenses/airgeddon/LICENSE"
    install -dm 755 "$out/share/airgeddon"
    cp -dr --no-preserve='ownership' .airgeddonrc known_pins.db language_strings.sh plugins/ "$out/share/airgeddon/"
    runHook postInstall
  '';

  meta = {
    description = "Multi-use bash script to audit wireless networks. ";
    homepage = "https://github.com/v1s1t0r1sh3r3/airgeddon";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ]; # [ pedrohlc ];
    platforms = lib.platforms.linux;
  };
}
