icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
  install_data(
    join_paths('icons', i, meson.project_name() + '.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
  )
endforeach

tool_icons = [ 'read-left-to-right', 'read-right-to-left', 'move-one-page-left', 'move-one-page-right', 'move-two-page-left', 'move-two-page-right', 'orientation-horizontal', 'orientation-vertical' ]

foreach i : tool_icons
  install_data(
    join_paths('icons', 'symbolic', i + '-symbolic.svg'),
    install_dir: join_paths(get_option('datadir'), 'pixmaps')
  )
endforeach
