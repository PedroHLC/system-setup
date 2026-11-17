# Import this module into vps-lab; activation is a separate operator step.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.nihongo;
  appLocation = learner: {
    alias = "${cfg.webRoot}/";
    index = "index.html";
    extraConfig = ''
      auth_basic "Nihongo ${learner}";
      auth_basic_user_file ${cfg.passwordFiles.${learner}};
    '';
  };
  progressLocation = learner: {
    alias = "${cfg.stateDirectory}/${learner}/";
    extraConfig = ''
      auth_basic "Nihongo ${learner}";
      auth_basic_user_file ${cfg.passwordFiles.${learner}};
      autoindex on;
      autoindex_format json;
      index __no_index__;
      dav_methods PUT;
      create_full_put_path off;
      dav_access user:rw;
      client_max_body_size 16k;
      client_body_temp_path ${cfg.stateDirectory}/upload;
      add_header Cache-Control "no-store" always;
      limit_except GET PUT { deny all; }
      # Only a directory listing or one UUID JSON record may reach DAV.
      if ($uri !~ "^/nihongo/${learner}/progress/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\.json)?$") { return 404; }
    '';
  };
in {
  options.services.nihongo = {
    enable = lib.mkEnableOption "Japanese travel practice";
    hostName = lib.mkOption { type = lib.types.str; default = "lab.pedrohlc.com"; };
    webRoot = lib.mkOption { type = lib.types.str; default = "/srv/http/nihongo"; };
    stateDirectory = lib.mkOption { type = lib.types.str; default = "/var/lib/nihongo"; };
    passwordFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { pedro = "/var/persistent/secrets/nihongo/pedro.htpasswd"; melina = "/var/persistent/secrets/nihongo/melina.htpasswd"; };
      description = "Separate runtime htpasswd files, each with username 1 and that learner's unique password.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [{ assertion = cfg.passwordFiles ? pedro && cfg.passwordFiles ? melina;
      message = "Provide separate Pedro and Melina htpasswd files."; }];
    services.nginx.enable = true;
    services.nginx.virtualHosts.${cfg.hostName}.locations = {
      "= /nihongo".return = "404";
      "= /nihongo/".return = "404";
      "= /nihongo/pedro".return = "308 /nihongo/pedro/";
      "= /nihongo/melina".return = "308 /nihongo/melina/";
      "/nihongo/pedro/progress/" = progressLocation "pedro";
      "/nihongo/melina/progress/" = progressLocation "melina";
      "/nihongo/pedro/" = appLocation "pedro";
      "/nihongo/melina/" = appLocation "melina";
      "/nihongo/".extraConfig = "return 404;";
    };
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDirectory} 0700 ${config.services.nginx.user} ${config.services.nginx.group} -"
      "d ${cfg.stateDirectory}/pedro 0700 ${config.services.nginx.user} ${config.services.nginx.group} -"
      "d ${cfg.stateDirectory}/melina 0700 ${config.services.nginx.user} ${config.services.nginx.group} -"
      "d ${cfg.stateDirectory}/upload 0700 ${config.services.nginx.user} ${config.services.nginx.group} -"
    ];
  };
}
