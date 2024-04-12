{ lib, config, ... }:

lib.mkIf (config.focusMode) {
  # Stuff that I should not open in the workstation
  networking.extraHosts = ''
    0.0.0.0 web.telegram.org
    0.0.0.0 discord.com
    0.0.0.0 web.whatsapp.com
    0.0.0.0 app.element.io
    0.0.0.0 youtube.com
    0.0.0.0 instagram.com
    0.0.0.0 twitter.com x.com
  '';

  # Only work projects
  environment.persistence."/var/persistent".users.pedrohlc.directories = [
    "Projects/co.timeline"
  ];
}
