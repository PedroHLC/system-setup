let
  unicode = code: builtins.fromJSON ''"\u${code}"'';
in
[
  {
    key = "At";
    mods = "Control";
    chars = "@";
  }
  {
    key = "A";
    mods = "Control";
    chars = "a";
  }
  {
    key = "B";
    mods = "Control";
    chars = "b";
  }
  {
    key = "C";
    mods = "Control";
    action = "Copy";
  }
  {
    key = "D";
    mods = "Control";
    chars = "d";
  }
  {
    key = "E";
    mods = "Control";
    chars = "e";
  }
  {
    key = "F";
    mods = "Control";
    action = "SearchForward";
  }
  {
    key = "F";
    mods = "Control";
    mode = "~Search";
    action = "SearchForward";
  }
  {
    key = "F";
    mods = "Control|Shift";
    action = "SearchBackward";
  }
  {
    key = "F";
    mods = "Control|Shift";
    mode = "~Search";
    action = "SearchBackward";
  }
  {
    key = "G";
    mods = "Control";
    chars = "g";
  }
  {
    key = "H";
    mods = "Control";
    chars = "h";
  }
  {
    key = "I";
    mods = "Control";
    chars = "i";
  }
  {
    key = "J";
    mods = "Control";
    chars = "j";
  }
  {
    key = "K";
    mods = "Control";
    chars = "k";
  }
  {
    key = "L";
    mods = "Control";
    chars = "l";
  }
  {
    key = "M";
    mods = "Control";
    chars = "m";
  }
  {
    key = "N";
    mods = "Control";
    action = "CreateNewWindow";
  }
  {
    key = "O";
    mods = "Control";
    chars = "o";
  }
  {
    key = "P";
    mods = "Control";
    chars = "p";
  }
  {
    key = "Q";
    mods = "Control";
    action = "Quit";
  }
  {
    key = "R";
    mods = "Control";
    chars = "r";
  }
  {
    key = "S";
    mods = "Control";
    chars = "s";
  }
  {
    key = "T";
    mods = "Control";
    chars = "t";
  }
  {
    key = "U";
    mods = "Control";
    chars = "u";
  }
  {
    key = "V";
    mods = "Control";
    action = "Paste";
  }
  {
    key = "W";
    mods = "Control";
    action = "Quit";
  }
  {
    key = "X";
    mods = "Control";
    chars = "Cut";
  }
  {
    key = "Y";
    mods = "Control";
    chars = "y";
  }
  {
    key = "Z";
    mods = "Control";
    chars = "z";
  }
  {
    key = "LBracket";
    mods = "Control";
    chars = "[";
  }
  {
    key = "Backslash";
    mods = "Control";
    chars = "\\\\";
  }
  {
    key = "RBracket";
    mods = "Control";
    chars = "]";
  }
  #{
  #  key = "At";
  #  mods = "Alt";
  #  chars = unicode "0000";
  #}
  {
    key = "A";
    mods = "Alt";
    chars = unicode "0001";
  }
  {
    key = "B";
    mods = "Alt";
    chars = unicode "0002";
  }
  {
    key = "C";
    mods = "Alt";
    chars = unicode "0003";
  }
  {
    key = "D";
    mods = "Alt";
    chars = unicode "0004";
  }
  {
    key = "E";
    mods = "Alt";
    chars = unicode "0005";
  }
  {
    key = "F";
    mods = "Alt";
    chars = unicode "0006";
  }
  {
    key = "G";
    mods = "Alt";
    chars = unicode "0007";
  }
  {
    key = "H";
    mods = "Alt";
    chars = "\b";
  }
  {
    key = "I";
    mods = "Alt";
    chars = "\t";
  }
  {
    key = "J";
    mods = "Alt";
    chars = "\n";
  }
  {
    key = "K";
    mods = "Alt";
    chars = unicode "000b";
  }
  {
    key = "L";
    mods = "Alt";
    chars = "\f";
  }
  {
    key = "M";
    mods = "Alt";
    chars = "\r";
  }
  {
    key = "N";
    mods = "Alt";
    chars = unicode "000e";
  }
  {
    key = "O";
    mods = "Alt";
    chars = unicode "000f";
  }
  {
    key = "P";
    mods = "Alt";
    chars = unicode "0010";
  }
  {
    key = "Q";
    mods = "Alt";
    chars = unicode "0011";
  }
  {
    key = "R";
    mods = "Alt";
    chars = unicode "0012";
  }
  {
    key = "S";
    mods = "Alt";
    chars = unicode "0013";
  }
  {
    key = "T";
    mods = "Alt";
    chars = unicode "0014";
  }
  {
    key = "U";
    mods = "Alt";
    chars = unicode "0015";
  }
  {
    key = "V";
    mods = "Alt";
    chars = unicode "0016";
  }
  {
    key = "W";
    mods = "Alt";
    chars = unicode "0017";
  }
  {
    key = "X";
    mods = "Alt";
    chars = unicode "0018";
  }
  {
    key = "Y";
    mods = "Alt";
    chars = unicode "0019";
  }
  {
    key = "Z";
    mods = "Alt";
    chars = unicode "001a";
  }
  {
    key = "LBracket";
    mods = "Alt";
    chars = unicode "001b";
  }
  {
    key = "Backslash";
    mods = "Alt";
    chars = unicode "001c";
  }
  {
    key = "RBracket";
    mods = "Alt";
    chars = unicode "001d";
  }
]
