/*
 *  Copyright 2019 Tanaka Takayuki (田中喬之) 
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Tanaka Takayuki <msg@gorigorilinux.net>
 */

using Gtk;

const IconSize ICON_SIZE = IconSize.SMALL_TOOLBAR;

// Environment variables
bool debugging_on;

/**
 * A C function that calls stat function and put the formatted file modification datetime
 * to char *result.
 *
 * @param path file path to read to
 * @param format datetime format
 * @param result formatted datetime of file modification datetime.
 */
extern void get_file_modification_date(string path, string format, char *result);

/**
 * The Program Entry Proint.
 * It initializes Gtk, and create a new window to start program.
 */
public class PvMain {
    public static int main(string[] args) {
        Gtk.init(ref args);
        env_setup();
        window_setup(args);
        Gtk.main();
        return 0;
    }

    private static PvWindow window;

    private static void env_setup() {
        string g_messages_debug = Environment.get_variable("G_MESSAGES_DEBUG");
        if (g_messages_debug == "all") {
            debugging_on = true;
        }
    }
    
    private static void window_setup(string[] args) {
        window = new PvWindow(first_file(args));
    }

    private static string? first_file(string[] args) {
        for (int i = 1; i < args.length; i++) {
            string path = File.new_for_path(args[i]).get_path();
            if (FileUtils.test(path, FileTest.IS_REGULAR)) {
                debug("Open file: %s", path);
                return path.dup();
            }
        }
        return null;
    }
}

/**
 * PvWindow is a customized gtk window class.
 * This is the main window of this program.
 * It contains toolbar, file tree, image viewer etc.
 */
public class PvWindow : Window {
    private Button hide_pane_button;
    private Image start_here_icon;
    private Image fullscreen_icon;
    
    private Button prev_button;
    private Button next_button;
    private Button open_button;
    private Button toggle_slide_button;
    
    private Revealer toolbar_revealer;
    private Button zoom_in_button;
    private Button zoom_out_button;
    private Button zoom_fit_button;
    private Button zoom_orig_button;
    private Button hflip_button;
    private Button vflip_button;
    private Button lrotate_button;
    private Button rrotate_button;

    private Paned tree_paned;
    private Revealer tree_revealer;
    private int tree_save_position;
    private PvTreeView tree;
    
    private Revealer slide_revealer;
    private Button slide_prev_button;
    private PvSlider slider;
    private Button slide_next_button;
    
    private ScrolledWindow image_scroll;
    private PvImage image;
    private PvFileList? file_list = null;
    private string? title_format;
    
    public PvWindow(string? filepath = null) {
        var headerbar = new HeaderBar();
        {
            start_here_icon = new Image.from_icon_name("start-here", ICON_SIZE);
            fullscreen_icon = new Image.from_icon_name("view-fullscreen", ICON_SIZE);
            
            hide_pane_button = new Button();
            hide_pane_button.image = fullscreen_icon;
            hide_pane_button.clicked.connect(() => {
                    if (hide_pane_button.image == fullscreen_icon) {
                        toolbar_revealer.reveal_child = false;
                        tree_revealer.reveal_child = false;
                        tree_save_position = tree_paned.position;
                        tree_paned.position = 0;
                        hide_pane_button.image = start_here_icon;
                    } else {
                        toolbar_revealer.reveal_child = true;
                        tree_revealer.reveal_child = true;
                        tree_paned.position = tree_save_position;
                        hide_pane_button.image = fullscreen_icon;
                    }
                });

            toggle_slide_button = new Button.from_icon_name("view-more", ICON_SIZE);
            toggle_slide_button.clicked.connect(() => {
                    slide_revealer.reveal_child = !slide_revealer.reveal_child;
                });

            headerbar.pack_start(hide_pane_button);
            headerbar.pack_start(toggle_slide_button);
            headerbar.show_close_button = true;
        }

        var toolbar_box = new Box(Orientation.VERTICAL, 0);
        {
            tree_paned = new Paned(Orientation.HORIZONTAL);
            {
                tree_revealer = new Revealer();
                {
                    var tree_scroll = new ScrolledWindow(null, null);
                    {
                        tree = new PvTreeView();
                        tree.open_image.connect((file) => {
                                bool dir_changed = slider_needs_update(file.get_path());
                                open_file(file.get_path());
                                if (dir_changed) {
                                    slider.reset(file_list);
                                }
                            });

                        tree_scroll.add(tree);
                    }

                    tree_revealer.add(tree_scroll);
                    tree_revealer.reveal_child = true;
                    tree_revealer.transition_type = RevealerTransitionType.SLIDE_RIGHT;
                    tree_revealer.hexpand = false;
                    tree_revealer.vexpand = true;
                }

                var main_box = new Box(Orientation.VERTICAL, 2);
                {
                    toolbar_revealer = new Revealer();
                    {
                        var toolbar = new Box(Orientation.HORIZONTAL, 2);
                        {
                            prev_button = new Button.from_icon_name("go-previous", ICON_SIZE);
                            prev_button.clicked.connect(() => {
                                    if (file_list != null) {
                                        File? prev_file = file_list.get_prev_file(image.fileref);
                                        if (prev_file != null) {
                                            open_file(prev_file.get_path());
                                        }
                                    }
                                });
            
                            next_button = new Button.from_icon_name("go-next", ICON_SIZE);
                            next_button.clicked.connect(() => {
                                    if (file_list != null) {
                                        File? next_file = file_list.get_next_file(image.fileref);
                                        if (next_file != null) {
                                            open_file(next_file.get_path());
                                        }
                                    }
                                });
            
                            open_button = new Button.from_icon_name("folder-open", ICON_SIZE);
                            open_button.clicked.connect(() => {
                                    on_open_button_clicked();
                                });

                            zoom_in_button = new Button.from_icon_name("zoom-in", ICON_SIZE);
                            zoom_in_button.clicked.connect(() => {
                                    image.zoom_in();
                                    zoom_fit_button.sensitive = true;
                                    title = title_format.printf(image.size_percent);
                                });
            
                            zoom_out_button = new Button.from_icon_name("zoom-out", ICON_SIZE);
                            zoom_out_button.clicked.connect(() => {
                                    image.zoom_out();
                                    zoom_fit_button.sensitive = true;
                                    title = title_format.printf(image.size_percent);
                                });
            
                            zoom_fit_button = new Button.from_icon_name("zoom-fit-best", ICON_SIZE);
                            zoom_fit_button.clicked.connect(() => {
                                    image.fit_image_to_window();
                                    zoom_fit_button.sensitive = false;
                                    title = title_format.printf(image.size_percent);
                                });
            
                            zoom_orig_button = new Button.from_icon_name("zoom-original", ICON_SIZE);
                            zoom_orig_button.clicked.connect(() => {
                                    image.zoom_original();
                                    zoom_fit_button.sensitive = true;
                                    title = title_format.printf(image.size_percent);
                                });
            
                            hflip_button = new Button.from_icon_name("object-flip-horizontal", ICON_SIZE);
                            hflip_button.clicked.connect(() => {
                                    image.hflip();
                                    title = title_format.printf(image.size_percent);
                                });
            
                            vflip_button = new Button.from_icon_name("object-flip-vertical", ICON_SIZE);
                            vflip_button.clicked.connect(() => {
                                    image.vflip();
                                    title = title_format.printf(image.size_percent);
                                });
        
                            lrotate_button = new Button.from_icon_name("object-rotate-left", ICON_SIZE);
                            lrotate_button.clicked.connect(() => {
                                    image.rotate_left();
                                    title = title_format.printf(image.size_percent);
                                    zoom_fit_button.sensitive = true;
                                });
            
                            rrotate_button = new Button.from_icon_name("object-rotate-right", ICON_SIZE);
                            rrotate_button.clicked.connect(() => {
                                    image.rotate_right();
                                    title = title_format.printf(image.size_percent);
                                    zoom_fit_button.sensitive = true;
                                });

                            toolbar.pack_start(prev_button, false, false);
                            toolbar.pack_start(next_button, false, false);
                            toolbar.pack_start(open_button, false, false);
                            toolbar.pack_start(zoom_in_button, false, false);
                            toolbar.pack_start(zoom_out_button, false, false);
                            toolbar.pack_start(zoom_fit_button, false, false);
                            toolbar.pack_start(zoom_orig_button, false, false);
                            toolbar.pack_start(hflip_button, false, false);
                            toolbar.pack_start(vflip_button, false, false);
                            toolbar.pack_start(lrotate_button, false, false);
                            toolbar.pack_start(rrotate_button, false, false);
                        }

                        toolbar_revealer.add(toolbar);
                        toolbar_revealer.reveal_child = true;
                        toolbar_revealer.transition_type = RevealerTransitionType.SLIDE_DOWN;
                        toolbar_revealer.hexpand = true;
                    }

                    image_scroll = new ScrolledWindow(null, null);
                    {
                        image = new PvImage(true);
                        image_scroll.add(image);
                        image_scroll.get_style_context().add_class("image");
                        image_scroll.overlay_scrolling = false;
                        image_scroll.shadow_type = ShadowType.IN;
                    }

                    slide_revealer = new Revealer();
                    {
                        var slide_box = new Box(Orientation.HORIZONTAL, 2);
                        {
                            slide_prev_button = new Button.from_icon_name("go-previous", IconSize.SMALL_TOOLBAR);
                            slide_prev_button.clicked.connect(() => {
                                    slider.step_prev();
                                });
                    
                            slider = new PvSlider();
                            slider.item_clicked.connect((file) => {
                                    open_file(file.get_path());
                                });
                    
                            slide_next_button = new Button.from_icon_name("go-next", IconSize.SMALL_TOOLBAR);
                            slide_next_button.clicked.connect(() => {
                                    slider.step_next();
                                });

                            slide_box.pack_start(slide_prev_button, false, false);
                            slide_box.pack_start(slider, true, true);
                            slide_box.pack_start(slide_next_button, false, false);
                            slide_box.vexpand = false;
                        }
                    
                        slide_revealer.add(slide_box);
                        slide_revealer.reveal_child = false;
                        slide_revealer.transition_type = RevealerTransitionType.SLIDE_DOWN;
                        slide_revealer.get_style_context().add_class("slide");
                    }
            
                    main_box.pack_start(slide_revealer, false, false);
                    main_box.pack_start(image_scroll, true, true);
                }

                tree_paned.add1(tree_revealer);
                tree_paned.add2(main_box);
                tree_paned.wide_handle = true;
                tree_paned.position = 200;
            }

            toolbar_box.pack_start(toolbar_revealer, false, false);
            toolbar_box.pack_start(tree_paned, true, true);
        }
        
        set_titlebar(headerbar);
        add(toolbar_box);
        set_default_size(800, 600);
        configure_event.connect((cr) => {
                if (image.fit) {
                    debug("window::configure_event -> image.fit_image_to_window");
                    image.fit_image_to_window();
                    title = title_format.printf(image.size_percent);
                }
                return false;
            });
        destroy.connect(Gtk.main_quit);
        show_all();

        if (filepath != null) {
            try {
                tree.expand_path(filepath);
                open_file(filepath);
                slider.reset(file_list);
            } catch (FileError e) {
                stderr.printf("Error: %s\n", e.message);
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
            }                
        }
    }

    private void open_file(string filename) {
        try {
            debug("try to open file %s", filename);
            image.open(filename);
            file_list = new PvFileList(image.fileref.get_parent().get_path());
            if (debugging_on) {
                file_list.print_all();
            }
            prev_button.sensitive = !file_list.file_is_first(image.fileref);
            next_button.sensitive = !file_list.file_is_last(image.fileref);
            title_format = make_title_format();
            title = title_format.printf(image.size_percent);
        } catch (FileError e) {
            stderr.printf("Error: %s\n", e.message);
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
    }

    private void on_open_button_clicked() {
        var dialog = new FileChooserDialog("ファイルを開く", this, FileChooserAction.OPEN,
                                               "キャンセル", ResponseType.CANCEL,
                                               "開く", ResponseType.ACCEPT);
        var res = dialog.run();
        if (res == ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            bool dir_changed = slider_needs_update(filename);
            try {
                tree.expand_path(filename);
            } catch (FileError e) {
                stderr.printf("FileError: %s\n", e.message);
            } catch (Error e) {
                stderr.printf("FileError: %s\n", e.message);
            }
            open_file(filename);
            if (dir_changed) {
                slider.reset(file_list);
            }
        }
        dialog.close();
    }

    private bool slider_needs_update(string filename) {
        if (file_list == null || file_list.size == 0) {
            debug("slider_needs_update: file_list is null");
            return true;
        }
        string path1 = file_list.get(0).get_parent().get_path();
        string path2 = File.new_for_path(filename).get_parent().get_path();
        debug("slider_needs_update (%s %s %s)", path1, path1.collate(path2) != 0 ? "!=" : "==", path2);
        return path1.collate(path2) != 0;
    }
    
    private string make_title_format() {
        string name = image.fileref.get_basename();
        int height = image.original_height;
        int width = image.original_width;
        string size = PvMathUtils.bytes_string(PvFileUtils.get_disk_usage(image.fileref));
        char time_data[20];
        get_file_modification_date(image.fileref.get_path(), "%Y/%m/%d %H:%M:%S", time_data);
        string time_string = PvStringUtils.convert_from_char(time_data);
        return "Pv | %s | %%.1f%%%% | %dx%d | %s | %s".printf(name, width, height, size, time_string);
    }
}

/**
 * PvTreeView is a custom GtkTreeView that can 
 * display a file tree.
 */
public class PvTreeView : Bin {
    TreeView view;
    TreeStore store;
    TreeViewColumn file_col;
    
    public signal void open_image(File? file);
    
    public PvTreeView() {
        setup_widgets();
    }

    public void expand_path(string path) throws FileError, Error {
        debug("PvTreeView::expand_path - start");
        if (Path.is_absolute(path)) {
            debug("PvTreeView::expand_path - path is absolute");
            string[] parts = path.substring(1).split("/");
            string tree_path = "0";
            TreeIter iter1;
            TreeIter iter2;
            store.get_iter_first(out iter1);
            debug("PvTreeView::expand_path - first child %s", get_basename(iter1));
            for (int i = 0; i < parts.length; i++) {
                string part = parts[i];
                debug("PvTreeView::expand_path - foreach: %s", get_basename(iter1));
                iter2 = iter1;
                int index = search_child_name(ref iter2, part);
                if (iter1 == iter2) {
                    debug("PvTreeView::expand_path - not found: %s", part);
                    return;
                } else {
                    debug("PvTreeView::expand_path - found: %s", get_basename(iter2));
                    expand_directory(iter1);
                    iter1 = iter2;
                }
                tree_path += ":" + index.to_string();
            }
            TreePath tpath = new TreePath.from_string(tree_path);
            debug("PvTreeView::expand_path - path : %s", tree_path);
            view.expand_to_path(tpath);
            view.set_cursor(tpath, file_col, false);
        }
        debug("PvTreeView::expand_path - end");
    }
    
    public string get_icon_name(TreeIter iter) {
        Value value;
        store.get_value(iter, 0, out value);
        return (string) value;
    }
    
    public string get_basename(TreeIter iter) {
        Value value;
        store.get_value(iter, 1, out value);
        return (string) value;
    }

    public string? get_dir_path(TreeIter iter) {
        Value? value;
        store.get_value(iter, 2, out value);
        File? parent = ((File) value).get_parent();
        if (parent != null) {
            return parent.get_path();
        } else {
            return null;
        }
    }

    public string get_file_path(TreeIter iter) {
        Value value;
        store.get_value(iter, 2, out value);
        return ((File) value).get_path();
    }
        
    public File get_file(TreeIter iter) {
        Value value;
        store.get_value(iter, 2, out value);
        return (File) value;
    }

    public FileInfo get_file_info(TreeIter iter) {
        Value value;
        store.get_value(iter, 3, out value);
        return (FileInfo) value;
    }

    public FileType get_file_type(TreeIter iter) {
        Value value;
        store.get_value(iter, 3, out value);
        return ((FileInfo) value).get_file_type();
    }

    public string get_content_type(TreeIter iter) {
        Value value;
        store.get_value(iter, 3, out value);
        return ((FileInfo) value).get_content_type();
    }

    private void setup_widgets() {
        view = new TreeView();
        {
            store = new TreeStore(4,
                                  typeof(string), // icon_name
                                  typeof(string), // file_name
                                  typeof(File),
                                  typeof(FileInfo)
                );
            {
                store.set_sort_column_id(1, SortType.ASCENDING);
                store.set_sort_func(1, (model, a, b) => get_basename(a).collate(get_basename(b)));
            }
            
            file_col = new TreeViewColumn();
            {
                var file_icon_cell = new CellRendererPixbuf();
                var file_name_cell = new CellRendererText();
                {
                    file_name_cell.family = "Sans-Serif";
                    file_name_cell.language = Environ.get_variable(Environ.get(), "LANG");
                }

                file_col.pack_start(file_icon_cell, false);
                file_col.pack_start(file_name_cell, true);
                file_col.add_attribute(file_icon_cell, "icon-name", 0);
                file_col.add_attribute(file_name_cell, "text", 1);
                file_col.set_title("label");
                file_col.sizing = TreeViewColumnSizing.AUTOSIZE;
            }

            view.model = store;
            view.append_column(file_col);
            view.activate_on_single_click = true;
            view.enable_grid_lines = TreeViewGridLines.NONE;
            view.enable_search = true;
            view.enable_tree_lines = true;
            view.headers_clickable = false;
            view.headers_visible = false;
            view.hover_expand = false;
            view.hover_selection = false;
            view.level_indentation = 1;
            view.reorderable = false;
            view.rubber_banding = false;
            view.search_column = 0;
            view.show_expanders = true;
            view.row_expanded.connect((iter, path) => {
                    try {
                        expand_directory(iter);
                        debug("expandation was finished: %s", get_file_path(iter));
                    } catch (FileError e) {
                        print("directory does not exists!\n");
                    } catch (Error e) {
                        print("directory does not exists!\n");
                    }
                });
            view.row_activated.connect((path, column) => {
                    TreeIter iter;
                    store.get_iter(out iter, path);
                    string mime_type = get_content_type(iter);
                    if (mime_type.split("/")[0] == "image") {
                        File image_file = get_file(iter);
                        open_image(image_file);
                    }
                });
            
            debug("view setup end");
            
            try {
                File root = File.new_for_path("/");
                TreeIter root_iter = append_node(root, null);
                debug("root was appended");
                append_children(root_iter);
                debug("append root end");
            } catch (FileError e) {
                print("root directory does not exists!\n");
            } catch (Error e) {
                print("root directory does not exists!\n");
            }
        }
        add(view);
    }

    private void expand_directory(TreeIter parent) throws FileError, Error {
        if (get_file_type(parent) == FileType.DIRECTORY) {
            if (store.iter_has_child(parent)) {
                TreeIter child_iter;
                store.iter_children(out child_iter, parent);
                do {
                    FileType type = get_file_type(child_iter);
                    if (type == FileType.DIRECTORY) {
                        try {
                            append_children(child_iter);
                        } catch (FileError e) {
                            if (e is FileError.ACCES) {
                            } else {
                                print("FileError: %s\n", e.message);
                            }
                        }
                    }
                } while (store.iter_next(ref child_iter));
            }
        }
    }

    private TreeIter? append_node(File file, TreeIter? parent) throws Error {
        FileInfo info = file.query_info("standard::*", 0);
        FileType file_type = info.get_file_type();
        string mime_type = info.get_content_type();
        string icon_name;

        if (file_type == FileType.DIRECTORY) {
            icon_name = "folder";
        } else if (mime_type.split("/")[0] == "image") {
            icon_name = "image-x-generic";
        } else {
            return null;
        }

        TreeIter? iter;
        store.append(out iter, parent);
        store.set(iter,
                  0, icon_name,
                  1, file.get_basename(),
                  2, file,
                  3, info
            );
        return iter;
    }

    
    private void append_children(TreeIter parent) throws Error {
        FileType file_type = get_file_type(parent);
        if (file_type == FileType.DIRECTORY) {
            if (store.iter_has_child(parent)) {
                remove_children(parent);
            }
            
            string dir_path = get_file_path(parent);

            debug("dir path: %s", dir_path);

            Dir dir = Dir.open(dir_path);

            debug("dir opened");
            
            string? name;
            while ((name = dir.read_name()) != null) {
                if (name == "." || name == "..") {
                    continue;
                }
                string child_path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);
                File child = File.new_for_path(child_path);
                var iter = append_node(child, parent);
                if (iter != null) {
                    debug("    append %s", child_path);
                }
            } 
        }
        debug("all children was appended");
    }

    private void remove_children(TreeIter parent) {
        if (store.iter_has_child(parent)) {
            TreeIter iter;
            while (store.iter_children(out iter, parent)) {
                store.remove(ref iter);
            }
        }
    }

    private int search_child_name(ref TreeIter iter, string name) {
        if (store.iter_has_child(iter)) {
            TreeIter child;
            store.iter_children(out child, iter);
            int i = 0;
            do {
                string child_name = get_basename(child);
                debug("%s %s %s", name, name == child_name ? "==" : "!=", child_name);
                if (name == child_name) {
                    iter = child;
                    return i;
                }
                i++;
            } while (store.iter_next(ref child));
        }
        return -1;
    }
}

/**
 * PvFileList is a custome Gee.ArrayList<File>.
 */
public class PvFileList : Gee.ArrayList<File> {
    public PvFileList(string dir_path) throws FileError {
        Dir dir = Dir.open(dir_path);
        string? name = null;
        while ((name = dir.read_name()) != null) {
            if (name != "." && name != "..") {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);
                if (FileUtils.test(path, FileTest.IS_REGULAR)) {
                    File file = File.new_for_path(path);
                    bool inserted = false;
                    for (int i = 0; i < size; i++) {
                        if (file.get_basename().collate(get(i).get_basename()) < 0) {
                            debug("[%d] name: %s", i, name);
                            insert(i, file);
                            inserted = true;
                            break;
                        }
                    }
                    if (!inserted) {
                        add(file);
                    }
                }
            }
        }
    }

    public bool file_is_first(File file) {
        return get(0).get_path() == file.get_path();
    }

    public bool file_is_last(File file) {
        return get(size - 1).get_path() == file.get_path();
    }

    public File? get_prev_file(File file) {
        for (int i = 1; i < size; i++) {
            if (get(i).get_path() == file.get_path()) {
                return get(i - 1);
            }
        }
        return null;
    }

    public File? get_next_file(File file) {
        for (int i = 0; i < size - 1; i++) {
            if (get(i).get_path() == file.get_path()) {
                return get(i + 1);
            }
        }
        return null;
    }
    
    public void print_all() {
        debug("PvFileList contains:\n");
        for (int i = 0; i < size; i++) {
            debug("    %s", get(i).get_basename());
        }
    }
}

/**
 * PvSlider displays image thumbnails horizontally and scrollable.
 */
public class PvSlider : Bin {
    private ScrolledWindow scroll;
    private Box? body = null;
    private int icon_size = 64;
    Gee.Iterator<File?>? iter;
    public signal void item_clicked(File file);
    
    public PvSlider() {
        scroll = new ScrolledWindow(null, null);
        {
            scroll.hscrollbar_policy = PolicyType.EXTERNAL;
            scroll.vscrollbar_policy = PolicyType.NEVER;
        }
        add(scroll);
    }

    public void reset(PvFileList? file_list = null, int position = -1) {
        if (file_list == null) {
            return;
        }
        if (body != null) {
            foreach (var child in scroll.get_children()) {
                child.destroy();
            }
            debug("PvSlider.scroll.remove(body)");
        }
        body = new Box(Orientation.HORIZONTAL, 4);
        {
            iter = file_list.iterator();
            Timeout.add(100, () => {
                    debug("PvSlider: Timeout start");
                    if (iter.has_next()) {
                        iter.next();
                        debug("PvSlider: iter has next");
                        File? file = iter.get();
                        debug("PvSlider: iter get file %s", file.get_basename());
                        if (file != null) {
                            debug("PvSlider: file is not null");
                            var pixbuf = get_pixbuf_from_file(file);
                            if (pixbuf != null) {
                                var item_button = new Button();
                                {
                                    var item = new Image();
                                    {
                                        item.pixbuf = PixbufUtils.scale_limited(pixbuf,
                                                                                icon_size);
                                        item.get_style_context().add_class("flat");
                                    }

                                    item_button.image = item;
                                    item_button.clicked.connect(() => {
                                            item_clicked(file);
                                        });
                                }

                                item_button.show_all();
                                body.pack_start(item_button, false, false);
                                debug("PvSlider: %s was added", file.get_basename());
                            }
                        }
                        return Source.CONTINUE;
                    } else {
                        return Source.REMOVE;
                    }
                }, Priority.DEFAULT);
            body.hexpand = true;
            body.show_all();
            debug("PvSlider.body show_all");
        }

        scroll.add(body);
    }

    public void step_next() {
        scroll.scroll_child(ScrollType.PAGE_FORWARD, true);
    }

    public void step_prev() {
        scroll.scroll_child(ScrollType.PAGE_BACKWARD, true);
    }

    private Gdk.Pixbuf? get_pixbuf_from_file(File? file) {
        try {
            FileInfo info = file.query_info("standard::*", 0);
            if (info.get_content_type().split("/")[0] == "image") {
                return new Gdk.Pixbuf.from_file(file.get_path());
            }
        } catch (FileError e) {
            debug("FileError: %s", e.message);
        } catch (Error e) {
            debug("Error: %s", e.message);
        }
        return null;
    }
}

/**
 * PvImage is a custome image widget
 * that has several image handling function
 * like zoom in/out, fit it to a parent widget, rotate, and flip.
 */
public class PvImage : Image {
    public static int[] zoom_level = {
        16, 32, 64, 125, 250, 500, 750, 800, 900, 1000, 1250, 1500, 1750, 1800, 1900, 2000, 2500, 3000
    };

    public PvImage(bool fit) {
        this.fit = fit;
    }

    public File? fileref { get; set; }
    public bool fit { get; set; }
    public double size_percent { get { return zoom_percent / 10.0; } }
    public int original_height { get { return original_pixbuf.height; } }
    public int original_width { get { return original_pixbuf.width; } }

    private Gdk.Pixbuf? original_pixbuf;
    private int zoom_percent = 1000;
    private int? original_max_size;
    private double? original_rate_x;
    private int save_width;
    private int save_height;
    
    public void open(string filename) throws FileError, Error {
        File file = File.new_for_path(filename);
        FileInfo info = file.query_info("standard::*", 0);
        string mime_type = info.get_content_type();
        if (info.get_file_type() == FileType.REGULAR && mime_type.split("/")[0] == "image") {
            fileref = file;
            original_pixbuf = new Gdk.Pixbuf.from_file(filename);
            original_max_size = int.max(original_pixbuf.width, original_pixbuf.height);
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            save_width = -1;
            save_height = -1;
            fit_image_to_window();
        } else {
            print("Warning: file type is invalid.\n");
        }
    }

    public void zoom_original() {
        if (original_pixbuf != null) {
            pixbuf = original_pixbuf;
            zoom_percent = 1000;
            fit = false;
        }
    }
    
    public void fit_image_to_window() {
        if (original_pixbuf != null) {
            fit = true;
            debug("PvImage::fit_image_to_window");
            int w0 = parent.get_allocated_width();
            int h0 = parent.get_allocated_height();
            double r0 = (double) w0 / (double) h0;
            double r1 = original_rate_x;
            if (r0 > r1) {
                scale_xy(-1, h0);
            } else if (r0 < r1) {
                scale_xy(w0, -1);
            }
        }
    }

    public void zoom_in() {
        if (original_pixbuf != null) {
            up_percent();
            scale((int) (original_max_size * zoom_percent / 1000));
            fit = false;
        }
    }

    public void zoom_out() {
        if (original_pixbuf != null) {
            down_percent();
            scale((int) (original_max_size * zoom_percent / 1000));
            fit = false;
        }
    }
    
    public void rotate_right() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.rotate_simple(Gdk.PixbufRotation.CLOCKWISE);
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            if (fit) {
                fit_image_to_window();
                adjust_zoom_percent();
            } else {
                scale(int.max(pixbuf.width, pixbuf.height));
            }
        }
    }

    public void rotate_left() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            if (fit) {
                fit_image_to_window();
                adjust_zoom_percent();
            } else {
                scale(int.max(pixbuf.width, pixbuf.height));
            }
        }
    }

    public void hflip() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.flip(true);
            scale(int.max(pixbuf.width, pixbuf.height));
        }
    }

    public void vflip() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.flip(false);
            scale(int.max(pixbuf.width, pixbuf.height));
        }
    }
    
    private void scale(int max_size) {
        if (original_pixbuf != null) {
            debug("PvImage::scale(%d)", max_size);
            if (max_size != int.max(save_width, save_height)) {
                pixbuf = PixbufUtils.scale_limited(original_pixbuf, max_size);
                if (fit) {
                    adjust_zoom_percent();
                }
            }
        }            
    }

    private void scale_xy(int width, int height) {
        if (original_pixbuf != null) {
            debug("PvImage::scale_xy(%d, %d)", width, height);
            if (width >= 0 && height < 0) {
                height = (int) (original_pixbuf.height * ((double) width / (double) original_pixbuf.width));
            } else if (width < 0 && height >= 0) {
                width = (int) (original_pixbuf.width * ((double) height / (double) original_pixbuf.height));
            }
            pixbuf = PixbufUtils.scale_xy(original_pixbuf, width, height);
            if (fit) {
                adjust_zoom_percent();
            }
        }
    }
    
    private void adjust_zoom_percent() {
        int original_size = int.max(original_pixbuf.height, original_pixbuf.width);
        int size = int.max(pixbuf.height, pixbuf.width);
        zoom_percent = size * 1000 / original_size;
        debug("zoom: %.1f%%", (double) zoom_percent / 10.0);
    }

    private void up_percent() {
        for (int i = 0; i < zoom_level.length; i++) {
            if (zoom_percent < zoom_level[i]) {
                zoom_percent = zoom_level[i];
                debug("zoom: %.1f%%", ((double) zoom_percent) / 10.0);
                return;
            }
        }
    }

    private void down_percent() {
        int i = 0;
        int temp = zoom_percent;
        while (zoom_level[i] < zoom_percent && i < zoom_level.length) {
            temp = zoom_level[i];
            i++;
        }
        zoom_percent = temp;
        debug("zoom: %.1f%%", ((double) zoom_percent) / 10.0);
    }
}

/**
 * PixbufUtils is used by PvImage.
 * This contains image scale function.
 */
public class PixbufUtils {
    public static Gdk.Pixbuf scale_limited(Gdk.Pixbuf pixbuf, int size) {
        size = int.max(10, size);
        if (pixbuf.width > pixbuf.height) {
            return scale_xy(pixbuf, size, (int) (size * ((double) pixbuf.height / pixbuf.width)));
        } else if (pixbuf.width < pixbuf.height) {
            return scale_xy(pixbuf, (int) (size * ((double) pixbuf.width / pixbuf.height)), size);
        } else {
            return scale_xy(pixbuf, size, size);
        }            
    }

    public static Gdk.Pixbuf scale_xy(Gdk.Pixbuf pixbuf, int width, int height) {
        debug("PixbufUtils.scale_xy(%d, %d -> %d, %d)", pixbuf.width, pixbuf.height, width, height);
        return pixbuf.scale_simple(width, height, Gdk.InterpType.BILINEAR);
    }
}

/**
 * PvFileUtils contains file utility functions.
 */
public class PvFileUtils {
    public static uint64 get_disk_usage(File file) {
        try {
            uint64 disk_usage;
            uint64 num_dirs;
            uint64 num_files;
            bool res = file.measure_disk_usage(FileMeasureFlags.APPARENT_SIZE, null, null,
                                               out disk_usage, out num_dirs, out num_files);
            if (res) {
                return disk_usage;
            }
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
        return 0;
    }

    public static List<File> get_files_in_same_dir(File in_file) throws FileError {
        GLib.List<File> list = new GLib.List<File>();
        string dir_path = in_file.get_parent().get_path();
        Dir dir = Dir.open(dir_path);
        string? name = null;
        while ((name = dir.read_name()) != null) {
            if (name != "." && name != "..") {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);
                File file = File.new_for_path(path);
                list.append(file);
            }
        }
        list.sort((a, b) => a.get_basename().collate(b.get_basename()));
        return list;
    }

    public static bool file_is_first(File file, List<File> list) {
        return list.nth_data(0).get_path() == file.get_path();
    }

    public static bool file_is_last(File file, List<File> list) {
        return list.nth_data(list.length() - 1).get_path() == file.get_path();
    }
}

/**
 * PvMathUtils contains functions that needs mathmatic 
 * calculation task.
 */
public class PvMathUtils {
    public static string bytes_string(uint64 n) {
        if (n < 1024) {
            return "%dBytes".printf((int) n);
        }
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fKB".printf(n2);
        }
        n = n / 1024;
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fMB".printf(n2);
        }
        n = n / 1024;
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fGB".printf(n2);
        }
        n = n / 1024;
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fTB".printf(n2);
        }
        return "%uBytes".printf((uint) n);
    }
}

/**
 * PvStringUtils contains functions that work with strings.
 */
public class PvStringUtils {
    public static string convert_from_char(char[] data) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < data.length; i++) {
            sb.append_c(data[i]);
        }
        return sb.str;
    }
}

