{
  # Up-to 192kHz in the Focusrite (thanks to https://another.maple4ever.net/archives/2994/)
  # and virtualization MSRS
  boot.extraModprobeConfig = ''
    options snd_usb_audio vid=0x1235 pid=0x8211 device_setup=1 quirk_flags=0x1
    options kvm ignore_msrs=1
  '';
}
