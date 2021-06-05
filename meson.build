project(
    'com.github.aharotias2.parapara',
    'vala', 'c',
    version: '1.0.0'
)

is_debug = get_option('DEBUG')
if is_debug
    add_project_arguments(['--define', 'DEBUG'], language: 'vala')
endif

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

asresources = gnome.compile_resources(
    'as-resources',
    join_paths('data', 'parapara.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

executable(
    meson.project_name(),
    asresources,
    'src/ThreadData/FileListThreadData.vala',
    'src/Application.vala',
    'src/Utils/StringUtils.c',
    'src/Utils/PixbufUtils.vala',
    'src/Utils/FileUtils.vala',
    'src/Utils/FileType.vala',
    'src/Utils/StringUtils.vala',
    'src/Utils/WidgetUtils.vala',
    'src/Model/SortOrder.vala',
    'src/Model/ViewMode.vala',
    'src/Model/Error.vala',
    'src/Model/FileList.vala',
    'src/Model/FileListIter.vala',
    'src/Model/SingleFileAccessor.vala',
    'src/Model/DualFileAccessor.vala',
    'src/Model/SlideFileAccessor.vala',
    'src/Widgets/ImageView.vala',
    'src/Widgets/Window.vala',
    'src/Widgets/ResizeDialog.vala',
    'src/Widgets/ToolBar.vala',
    'src/Widgets/SingleImageView.vala',
    'src/Widgets/DualImageView.vala',
    'src/Widgets/SlideImageView.vala',
    'src/Widgets/Image.vala',
    'src/Widgets/ActionButton.vala',
    dependencies: [
        dependency('gee-0.8'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('gdk-3.0')
    ],
    install: true
)

i18n.merge_file(
    input: join_paths('data', 'parapara.desktop.in'),
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

subdir('po')
subdir('data')

meson.add_install_script('meson/post_install.py')
