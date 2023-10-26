{
  # schemas
  htop_version = "3.2.2";
  config_reader_min_version = 3;
  # display options
  tree_view = 1;
  tree_view_always_by_pid = 0;
  all_branches_collapsed = 1;
  screen_tabs = 1;
  shadow_other_users = 0;
  hide_kernel_threads = 1;
  hide_userland_threads = 1;
  hide_running_in_container = 0;
  highlight_threads = 1;
  show_thread_names = 0;
  show_program_path = 0;
  highlight_base_name = 0;
  highlight_deleted_exe = 1;
  shadow_distribution_path_prefix = 0;
  show_merged_command = 0;
  find_comm_in_cmdline = 1;
  strip_exe_from_cmdline = 1;
  highlight_megabytes = 1;
  header_margin = 1;
  detailed_cpu_time = 0;
  cpu_count_from_one = 0;
  update_process_names = 0;
  account_guest_in_cpu_meter = 0;
  show_cpu_usage = 1;
  show_cpu_frequency = 0;
  show_cpu_temperature = 0;
  degree_fahrenheit = 0;
  enable_mouse = 1;
  delay = 15;
  highlight_changes = 0;
  highlight_changes_delay_secs = 5;
  hide_function_bar = 0;
  # meters
  column_meters_0 = [ "LeftCPUs4" "Memory" "Swap" "Uptime" "NetworkIO" ];
  column_meter_modes_0 = [ 1 1 1 2 2 ];
  column_meters_1 = [ "RightCPUs4" "LoadAverage" "ZFSARC" "DateTime" "Systemd" ];
  column_meter_modes_1 = [ 1 2 2 2 2 ];
}
