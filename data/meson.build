icon_sizes = ['48', '64', '128']

foreach i : icon_sizes
  install_data(
    join_paths('icons', i, 'icons.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
  )
endforeach
