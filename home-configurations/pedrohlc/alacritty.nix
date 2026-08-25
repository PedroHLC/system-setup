utils: with utils;

let
  cfg = config.programs.alacritty;
  tomlFormat = pkgs.formats.toml { };

  configFile =
    # https://github.com/NixOS/nixpkgs/pull/513796#issuecomment-4608008199
    tomlFormat.generate "tty.toml" cfg.settings;
in
{
  programs = {
    # My favorite and simple terminal
    alacritty = {
      enable = hasSeat;
      package = pkgs.cutty_git;
      settings = {
        window.opacity = mkForce 0.9;

        terminal.shell = {
          program = bin.tmux;
          args = [ "-l" ];
        };

        keyboard.bindings =
          let
            base =
              if ctrlNearSpaceKeyMap
              then import ../../common/alacritty-apple-mods.nix
              else [ ];

            newWithoutTmux =
              {
                key = "N";
                mods = if isMacOS then "Command|Shift" else "Control|Shift";
                command = {
                  program = bin.terminal;
                  args = [ "-e" bin.fish "-l" ];
                };
              };
          in
          base ++ [ newWithoutTmux ];
      };
    };
  };

  xdg.configFile = mkIf hasSeat {
    "alacritty/alacritty.toml".source = mkForce configFile;
    "cutty/cutty.toml".source = configFile;
  };
}
