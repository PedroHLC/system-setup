{ pkgs, ... }:

let
  head = pkgs.writeText "head.html" ''
    <meta name="viewport" content="width=device-width initial-scale=1.0"/>
  '';

  settings = {
    css = "/bucket/cgit.css";
    logo = "/git/cgit.png";
    root-title = "Pedro's Git Archive";
    root-desc = "These are my personal, automated backups of public git repositories.";
    head-include = builtins.toString head;
    section-from-path = "2";
    source-filter = "${package}/lib/cgit/filters/syntax-highlighting.py";
  };

  package = pkgs.cgit-pink;
in
{
  services.cgit = {
    public = {
      enable = true;
      inherit settings package;
      nginx = {
        location = "/git";
        virtualHost = "lab.pedrohlc.com";
      };
      scanPath = "/var/public-git";
    };
    private = {
      enable = true;
      inherit package;
      settings = settings // {
        root-title = "Pedro's Private Git Archive";
        root-desc = "These are my private, automated backups of git repositories. Third parties are not allowed to see this! Public archive can be found in https://lab.pedrohlc.com/git";
      };
      nginx = {
        location = "/YOU_ARE_NOT_ALLOWED_TO_VISIT_THIS_URL/git";
        virtualHost = "lab.pedrohlc.com";
      };
      scanPath = "/var/private-git";
    };
  };
}
