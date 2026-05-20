{
  # ctrlNearSpaceKeyMap and swap [\|] with ['"] to mimic OSX
  services.udev.extraHwdb = ''
    evdev:input:b0003v0C45p767E*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_700E0=key_leftalt
      KEYBOARD_KEY_700E3=key_leftmeta
      KEYBOARD_KEY_700E2=key_leftctrl
      KEYBOARD_KEY_70035=key_102nd
      KEYBOARD_KEY_70064=key_grave
  '';

}
