{ fetchzip }:
# This is my favorite skin for Audacious, a clone of the classic Winamp
let
  fileId = "1460751560";
  fileName = "135799-winamp_classic.wsz";
in
fetchzip {
  #url = "https://dl.opendesktop.org/api/files/download/id/${fileId}/${fileName}";
  url = "mirror://sourceforge/anitaos/Anitaos/Multimedia/Audacious%20classic%20skins/135799-winamp_classic.wsz";
  sha256 = "cAXw2J56Bx1sexj1rSxbTGUxN92lPXRi3OKouwFOqeM=";
  extension = "zip";
  stripRoot = false;
}
