{
  # Defaults to 96khz, but goes up-to 192kHz in the Focusrite
  services.pipewire.extraConfig.pipewire."99-playback-96khz" = {
    "context.properties" = {
      "default.clock.rate" = 96000;
      "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
    };
  };
}
