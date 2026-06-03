utils: with utils;

{
  programs = {
    # My favorite and simple terminal
    alacritty = {
      enable = hasSeat;
      package = pkgs.alacritty;
      settings = {
        window.opacity = mkForce 0.9;

        terminal.shell = {
          program = "${bin.tmux}";
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
                  args = [ "-e" "${pkgs.fish}/bin/fish" "-l" ];
                };
              };
          in
          base ++ [ newWithoutTmux ];
      };
    };
  };

  xdg.configFile."alacritty/alacritty.toml" =
    let
      cfg = config.programs.alacritty;
      tomlFormat = pkgs.formats.toml { };
    in
    mkIf hasSeat {
      # https://github.com/NixOS/nixpkgs/pull/513796#issuecomment-4608008199
      source = mkForce (tomlFormat.generate "alacritty.toml" cfg.settings);
    };
}
