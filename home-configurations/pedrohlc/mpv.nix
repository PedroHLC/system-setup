utils: with utils;
{
  programs.mpv =
    if hasAppleSeat then {
      enable = true;
      config = {
        hwdec = "auto";
      };
    } else {
      enable = hasLinuxSeat;
      # For watching animes in 60fps
      package = pkgs.mpv-vapoursynth;
      config = {
        # Temporary & lossless screenshots
        screenshot-format = "png";
        screenshot-directory = "/tmp";
        # for Pipewire (Let's pray for MPV native solution)
        ao = "openal";
        # I don't usually plug my PC in a home-theater
        audio-channels = "stereo";

        # So dual-audio anime don't go crazy;
        alang = "jpn,eng";
        slang = "eng";

        # GPU & Wayland
        hwdec = "${videoAcceleration}";
        vo = "gpu";
        gpu-context = "waylandvk";
        gpu-api = "vulkan";

        # YouTube quality
        ytdl-format =
          if seat.displayHeight <= 1080 then
            "bestvideo[height<=?1440]+bestaudio/best"
          else
            "bestvideo[height<=?2160]+bestaudio/best";

      };
      profiles = {
        # For when I plug the optical-cable
        "toslink" = {
          audio-channels = "auto";
          af = "lavcac3enc";
          audio-spdif = "ac3";
        };
        "hq" = {
          profile = "gpu-hq";
          scale = "ewa_lanczossharp";
          cscale = "ewa_lanczossharp";
          tscale = "oversample";
        };
        "live" = {
          profile = "low-latency";

          cache = "no";
          cache-secs = 0;
          demuxer-max-back-bytes = 0;
          demuxer-max-bytes = "1000KiB";
          demuxer-readahead-secs = 0;
          stream-buffer-size = "4KiB";
          framedrop = "vo";
          untimed = "yes";

          demuxer-lavf-o = "live_start_index=-1";
          hls-bitrate = "max";

          rtsp-transport = "udp";

          ytdl-raw-options = "cookies-from-browser=firefox";
          #ytdl-format = "bestvideo[protocol^=m3u8_native]+bestaudio[protocol^=m3u8_native]/best";
          ytdl-format = "bestvideo[protocol^=http_dash_segments]+bestaudio[protocol^=http_dash_segments]/best";

          speed = 1.2;
          audio-buffer = 0.01;

          ao-mute-on-ambience-volume = "no";
          ad-lavc-downmix = "no";
          video-sync = "display-desync";
          audio-stream-silence = "yes";
        };
      };
      bindings = {
        # Subtitle scalers
        "P" = "add sub-scale +0.1";
        "Ctrl+p" = "add sub-scale -0.1";

        # Window helpers
        "Alt+3" = "set window-scale 0.5";
        "Alt+4" = "cycle border";

        # For watching animes in 60fps
        "K" = "vf toggle vapoursynth=${../../assets/motioninterpolation.vpy}";

        # For anime 4k
        "CTRL+1" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A (HQ)"'';
        "CTRL+2" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_Soft_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B (HQ)"'';
        "CTRL+3" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C (HQ)"'';
        "CTRL+4" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_M.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A+A (HQ)"'';
        "CTRL+5" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_Soft_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_Soft_M.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B+B (HQ)"'';
        "CTRL+6" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_M.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C+A (HQ)"'';
        "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "GLSL shaders cleared"'';
      };
    };

  home.packages =
    lists.optional hasLinuxSeat pseudoPkgs.mpv-hq-entry;
}
