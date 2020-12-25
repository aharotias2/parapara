project(
    'com.github.aharotias2.tatap',
    'vala', 'c',
    version: '1.0.0'
)

is_debug = get_option('DEBUG')
if is_debug
    add_project_arguments(['--define', 'DEBUG'], language: 'vala')
endif

i18n = import('i18n')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

executable(
    meson.project_name(),
    'src/Utils/PixbufUtils.vala',
    'src/Utils/TatapFileType.vala',
    'src/Utils/TatapFileUtils.vala',
    'src/Utils/TatapMathUtils.vala',
    'src/Utils/TatapStringUtils.vala',
    'src/Widgets/NavigationBox.vala',
    'src/Application.vala',
    'src/TatapFileList.vala',
    'src/TatapImage.vala',
    'src/TatapWindow.vala',
    dependencies: [
        dependency('gee-0.8'),
        dependency('gtk+-3.0'),
        dependency('gdk-3.0')
    ],
    install: true
)

i18n.merge_file(
    input: join_paths('data', 'tatap.desktop.in'),
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

subdir('po')
