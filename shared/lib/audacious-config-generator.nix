{ lib }:
with lib; generators.toINI {
  mkKeyValue = generators.mkKeyValueDefault
    {
      mkValueString = v:
        if v == true then ''TRUE''
        else if v == false then ''FALSE''
        else if isString v then ''${v}''
        else generators.mkValueStringDefault { } v;
    } "=";
}
