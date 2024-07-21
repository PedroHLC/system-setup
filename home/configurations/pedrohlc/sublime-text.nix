utils: with utils;

{
  xdg.configFile = {
    sublimePreferences =
      let
        # This will result in a lot of errors until Catppuccin and Colorsublime loads.
        catppuccinScheme = flavor: "Packages/Catppuccin color schemes/Catppuccin ${flavor}.sublime-color-scheme";
        colorSublimeThemes = theme: "Packages/Colorsublime - Themes/cache/Colorsublime-Themes-master/themes/${theme}.tmTheme";
      in
      {
        target = "sublime-text/Packages/home-manager/Preferences.sublime-settings";
        text = generators.toJSON { } {
          hardware_acceleration = "opengl";
          close_windows_when_empty = false;
          rulers = [ 45 90 ];
          spell_check = false;
          lsp_format_on_save = false; # S|_|cks a lot, I prefer plugins with REAL language support

          font_face = "Borg Sans Mono";
          font_options = [ "subpixel_antialias" ];
          font_size = 8;
          fonts_list = [ "Borg Sans Mono" "DroidSansMono Nerd Font" "Fira Code" "JetBrains Mono" ]; # For FontCycler

          # Have both dark & light themes
          color_scheme = "auto";
          dark_color_scheme = colorSublimeThemes "Rebecca-dark";
          light_color_scheme = catppuccinScheme "Latte";
          theme = "auto";
          dark_theme = "Darkmatter.sublime-theme";
          light_theme = "Adaptive.sublime-theme";

          # Constraint NeoVintageous to a much smaller keybindings set
          vintageous_use_ctrl_keys = null;
          vintageous_use_super_keys = null;
        };
      };
    sublimeTerminus = {
      target = "sublime-text/Packages/home-manager/Terminus.sublime-settings";
      text = generators.toJSON { } {
        default_config = {
          linux = "Fish";
        };
        shell_configs = [
          {
            name = "Fish";
            cmd = [ "${fish}" "--login" ];
            env = { };
            enable = true;
            platforms = [ "linux" "osx" ];
          }
        ];
      };
    };
    sublimeKeybindings = {
      target = "sublime-text/Packages/home-manager/Default (Linux).sublime-keymap";
      text = generators.toJSON { } [
        { keys = [ "ctrl+k" "ctrl+z" ]; command = "zoom_pane"; args = { "fraction" = 0.9; }; }
        { keys = [ "ctrl+k" "ctrl+shift+z" ]; command = "unzoom_pane"; args = { }; }
        { keys = [ "ctrl+shift+m" ]; command = "new_window_for_project"; }
        { keys = [ "ctrl+'" ]; command = "show_panel"; args = { panel = "console"; toggle = true; }; }
        {
          keys = [ "ctrl+alt+t" ];
          command = "terminus_open";
          args = {
            post_window_hooks = [
              [ "carry_file_to_pane" { direction = "down"; } ]
            ];
          };
        }
      ];
    };
    sublimePackages = {
      target = "sublime-text/Packages/User/Package Control.sublime-settings";
      text = generators.toJSON { } {
        # As this list is being updated since 2014, it may contain some obsolete packages.
        installed_packages = [
          "A File Icon" # Proper icons in the sidebar
          "Babel" # React JSX syntax
          "Clang Format" # Format C/C++
          "CMake" # CMake syntax
          "Catppuccin color schemes" # Modern color scheme
          "Color Convert" # RGB to/from HEX
          "Colorsublime" # Extra colorschemes
          "Dockerfile Syntax Highlighting" # Dockerfile syntax
          "EditorConfig" # Per-project cross-IDE preferences
          "ElixirSyntax" # Elixir syntax
          "Elm Format on Save" # Format Elm
          "Elm Syntax Highlighting" # Elm syntax
          "Focus File on Sidebar"
          "FontCycler" # Fast-change fonts
          "GitGutter" # Git blame and diff
          "GraphQL" # Graphql syntax
          "HexViewer" # View binary files
          "i3 wm" # i3 and sway syntax
          "INI" # Ini files syntax
          "LaTeXTools" # Texlive recommended companion
          "LDIF Syntax Highlighting" # LDAP files syntax
          "LSP" # I really hate having a socket-server that duplicates the entire editor's state, but...
          "LSP-Deno" # ...urgh, no alternative
          "LSP-elixir" # ...damm, I really need this dialyzer integration
          "MasmAssembly" # MASM syntax
          "MDX Syntax Highlighting" # MDX (JSX on Markdown) syntax
          "MIPS Syntax" # MIPS syntax 
          "MouseEventListener" # Dependency of some other plugin
          "NeoVintageous" # Vim modes for sublime
          "Nix" # Nix syntax
          "Nushell" # Nushell syntax
          "Origami" # Easy split windows into panes
          "Package Control" # Required for having all the other
          "PKGBUILD" # Arch's PKGBUILDs syntax
          "ProjectManager" # Fast-change projects
          "Prolog" # Prolog syntax
          "QML" # Qt's QML syntax
          "rainbow_csv" # See columns in CSV through coloring
          "RecentTabSort" # Re-sort tabs
          "RustFmt" # Format Rust
          "Sass" # Sass syntax
          "SideBarEnhancements" # Useful commands in the sidebar
          "SublimeLinter" # Generic linter
          "Tabnine" # AI-powered auto-complete
          "Terminus" # Real terminal inside sublime
          "Terraform" # Terraform syntax
          "Theme - Darkmatter" # The dark theme I use
          "Themes Menu Switcher"
          "Toggle Dark Mode" # Fast-change theme
          "TOML" # Toml syntax
          "VimModelines" # Consider "# vim set:" lines
        ];

        # Auto generated by sublime, keeping it here otherwise it will recreate the file.
        bootstrapped = true;
        in_process_packages = [ ];
      };
    };
  };
}
