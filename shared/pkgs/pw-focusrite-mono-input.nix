{ pkgs, ... }:
let
  json = pkgs.formats.json { };
in
json.generate "focusrite-mono-input.conf" {
  "context.modules" = [
    {
      name = "libpipewire-module-loopback";
      args = {
        "node.description" = "Scarlett Solo (3rd Gen.) Pro Mic Input";
        "capture.props" = {
          "node.name" = "capture.P7AY7C60A16FA7-mic";
          "audio.position" = [ "FL" ];
          "node.target" = "alsa_input.usb-Focusrite_Scarlett_Solo_USB_P7AY7C60A16FA7-00.pro-input-0";
          "stream.dont-remix" = true;
          "node.passive" = true;
        };
        "playback.props" = {
          "node.name" = "P7AY7C60A16FA7-mic";
          "media.class" = "Audio/Source";
          "audio.position" = [ "MONO" ];
        };
      };
    }
    {
      name = "libpipewire-module-loopback";
      args = {
        "node.description" = "Scarlett Solo (3rd Gen.) Pro Instrument Input";
        "capture.props" = {
          "node.name" = "capture.P7AY7C60A16FA7-inst";
          "audio.position" = [ "FR" ];
          "node.target" = "alsa_input.usb-Focusrite_Scarlett_Solo_USB_P7AY7C60A16FA7-00.pro-input-0";
          "stream.dont-remix" = true;
          "node.passive" = true;
        };
        "playback.props" = {
          "node.name" = "P7AY7C60A16FA7-inst";
          "media.class" = "Audio/Source";
          "audio.position" = [ "MONO" ];
        };
      };
    }
  ];

  "context.properties" = {
    "default.configured.audio.source" = { name = "P7AY7C60A16FA7-mic"; };
  };
}
