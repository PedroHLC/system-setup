{ lib }:
with lib; generators.toINI {
  mkKeyValue = generators.mkKeyValueDefault
    {
      mkValueString = v:
        if isBool v then
          if v then ''TRUE''
          else ''FALSE''
        else if isString v then ''${v}''
        else generators.mkValueStringDefault { } v;
    } "=";
}
