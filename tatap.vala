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

public errordomain TatapError {
    INVALID_FILE,
    INVALID_EXTENSION
}

public enum TatapFileType {
    JPEG, PNG, BMP, ICO;

    public string? to_string() {
        switch (this) {
        case JPEG: return "jpg";
        case PNG: return "png";
        case BMP: return "bmp";
        case ICO: return "ico";
        default: return null;
        }
    }

    public static string? to_pixbuf_type(string extension) {
        switch (extension) {
        case "jpeg": case "jpg": case "JPG": case "JPEG":
        default:
            return "jpeg";
        case "png": case "PNG":
            return "png";
        case "bmp": case "BMP":
            return "bmp";
        case "ico": case "ICO":
            return "ico";
        }
    }
    
    public static bool is_valid_extension(string extension) {
        switch (extension) {
        case "jpeg": case "jpg": case "JPG": case "JPEG":
        case "png": case "PNG":
        case "bmp": case "BMP":
        case "ico": case "ICO":
            return true;
        default:
            return false;
        }
    }
}

const IconSize ICON_SIZE = IconSize.SMALL_TOOLBAR;

const string stylesheet = """
.image-view {
    background-color: #24140e;
}

.toolbar {
    background-color: @theme_bg_color;
}
""";

/**
 * The Program Entry Proint.
 * It initializes Gtk, and create a new window to start program.
 */
void main(string[] args) {
    Gtk.init(ref args);
    var window = new TatapWindow();

    if (args.length > 1) {
        File file = File.new_for_path(args[1]);
        string? filepath = file.get_path();
        string mimetype = TatapFileUtils.get_mime_type_from_file(file);

        stdout.printf("The first argument is a file path: %s (%s)\n", filepath,
                      mimetype != null ? "unknown type" : "");

        if (mimetype != null && mimetype.split("/")[0] == "image") {
            window.open_file(filepath);
        } else {
            stderr.printf("The argument is not a image file!\n");
        }
    }
        
    Gtk.main();
}

/**
 * TatapWindow is a customized gtk window class.
 * This is the main window of this program.
 */
public class TatapWindow : Gtk.Window {
    private HeaderBar headerbar;
    private Button open_button;
    private Button save_button;
    
    private Button image_prev_button;
    private Button image_next_button;

    private Button zoom_in_button;
    private Button zoom_out_button;
    private Button zoom_fit_button;
    private Button zoom_orig_button;
    private Button hflip_button;
    private Button vflip_button;
    private Button lrotate_button;
    private Button rrotate_button;

    private TatapImage image;

    private Revealer toolbar_revealer;
    
    private TatapFileList? file_list = null;

    public TatapWindow() {
        headerbar = new HeaderBar();
        {
            var button_box2 = new ButtonBox(Orientation.HORIZONTAL);
            {
                image_prev_button = new Button.from_icon_name("go-previous-symbolic", ICON_SIZE);
                {
                    image_prev_button.valign = Align.CENTER;
                    image_prev_button.get_style_context().add_class("image_button");
                    image_prev_button.clicked.connect(() => {
                            if (file_list != null) {
                                File? prev_file = file_list.get_prev_file(image.fileref);
                                if (prev_file != null) {
                                    open_file(prev_file.get_path());
                                }
                            }
                        });
                }

                image_next_button = new Button.from_icon_name("go-next-symbolic", ICON_SIZE);
                {
                    image_next_button.valign = Align.CENTER;
                    image_next_button.get_style_context().add_class("image_button");
                    image_next_button.clicked.connect(() => {
                            if (file_list != null) {
                                File? next_file = file_list.get_next_file(image.fileref);
                                if (next_file != null) {
                                    open_file(next_file.get_path());
                                }
                            }
                        });
                }

                button_box2.add(image_prev_button);
                button_box2.add(image_next_button);
                button_box2.set_layout(ButtonBoxStyle.EXPAND);
            }

            var header_button_box_right = new ButtonBox(Orientation.HORIZONTAL);
            {
                var toolbar_toggle_button = new ToggleButton();
                {
                    var toggle_toolbar_icon = new Image.from_icon_name("view-more-symbolic", ICON_SIZE);

                    toolbar_toggle_button.add(toggle_toolbar_icon);
                    toolbar_toggle_button.toggled.connect(() => {
                            toolbar_revealer.reveal_child = toolbar_toggle_button.active;
                        });
                }

                header_button_box_right.add(toolbar_toggle_button);
                header_button_box_right.set_layout(ButtonBoxStyle.EXPAND);
            }
            
            headerbar.pack_start(button_box2);
            headerbar.pack_end(header_button_box_right);
            headerbar.show_close_button = true;
        }

        var window_overlay = new Overlay();
        {
            toolbar_revealer = new Revealer();
            {
                var toolbar_hbox = new Box(Orientation.HORIZONTAL, 0);
                {
                    var button_box1 = new ButtonBox(Orientation.HORIZONTAL);
                    {
                        open_button = new Button();
                        {
                            var open_button_icon = new Image.from_icon_name("document-open-symbolic",
                                                                            ICON_SIZE);

                            open_button.add(open_button_icon);
                            open_button.clicked.connect(() => {
                                    on_open_button_clicked();
                                });
                        }

                        save_button = new Button.from_icon_name("document-save-symbolic", ICON_SIZE);
                        {
                            save_button.clicked.connect(() => {
                                    on_save_button_clicked();
                                });
                        }
                        
                        button_box1.add(open_button);
                        button_box1.add(save_button);
                        button_box1.set_layout(ButtonBoxStyle.EXPAND);
                        button_box1.margin = 5;
                    }
            
                    var button_box3 = new ButtonBox(Orientation.HORIZONTAL);
                    {
                        zoom_in_button = new Button.from_icon_name("zoom-in-symbolic", ICON_SIZE);
                        {
                            zoom_in_button.get_style_context().add_class("image_overlay_button");
                            zoom_in_button.clicked.connect(() => {
                                    image.zoom_in();
                                    zoom_fit_button.sensitive = true;
                                });
                        }
            
                        zoom_out_button = new Button.from_icon_name("zoom-out-symbolic", ICON_SIZE);
                        {
                            zoom_out_button.get_style_context().add_class("image_overlay_button");
                            zoom_out_button.clicked.connect(() => {
                                    image.zoom_out();
                                    zoom_fit_button.sensitive = true;
                                });
                        }
            
                        zoom_fit_button = new Button.from_icon_name("zoom-fit-best-symbolic", ICON_SIZE);
                        {
                            zoom_fit_button.get_style_context().add_class("image_overlay_button");
                            zoom_fit_button.clicked.connect(() => {
                                    image.fit_image_to_window();
                                    zoom_fit_button.sensitive = false;
                                });
                        }
            
                        zoom_orig_button = new Button.from_icon_name("zoom-original-symbolic", ICON_SIZE);
                        {
                            zoom_orig_button.get_style_context().add_class("image_overlay_button");
                            zoom_orig_button.clicked.connect(() => {
                                    image.zoom_original();
                                    zoom_fit_button.sensitive = true;
                                });
                        }
            
                        hflip_button = new Button.from_icon_name("object-flip-horizontal-symbolic", ICON_SIZE);
                        {
                            hflip_button.get_style_context().add_class("image_overlay_button");
                            hflip_button.clicked.connect(() => {
                                    image.hflip();
                                });
                        }
            
                        vflip_button = new Button.from_icon_name("object-flip-vertical-symbolic", ICON_SIZE);
                        {
                            vflip_button.get_style_context().add_class("image_overlay_button");
                            vflip_button.clicked.connect(() => {
                                    image.vflip();
                                });
                        }
            
                        lrotate_button = new Button.from_icon_name("object-rotate-left-symbolic", ICON_SIZE);
                        {
                            lrotate_button.get_style_context().add_class("image_overlay_button");
                            lrotate_button.clicked.connect(() => {
                                    image.rotate_left();
                                    zoom_fit_button.sensitive = true;
                                });
                        }
            
                        rrotate_button = new Button.from_icon_name("object-rotate-right-symbolic", ICON_SIZE);
                        {
                            rrotate_button.get_style_context().add_class("image_overlay_button");
                            rrotate_button.clicked.connect(() => {
                                    image.rotate_right();
                                    zoom_fit_button.sensitive = true;
                                });
                        }

                        button_box3.pack_start(zoom_in_button);
                        button_box3.pack_start(zoom_out_button);
                        button_box3.pack_start(zoom_fit_button);
                        button_box3.pack_start(zoom_orig_button);
                        button_box3.pack_start(hflip_button);
                        button_box3.pack_start(vflip_button);
                        button_box3.pack_start(lrotate_button);
                        button_box3.pack_start(rrotate_button);
                        button_box3.set_layout(ButtonBoxStyle.EXPAND);
                        button_box3.margin = 5;
                    }
                    
                    toolbar_hbox.pack_start(button_box1, false, false);
                    toolbar_hbox.pack_start(button_box3, false, false);
                    toolbar_hbox.vexpand = false;
                    toolbar_hbox.valign = Align.START;
                    toolbar_hbox.get_style_context().add_class("toolbar");
                }
                
                toolbar_revealer.add(toolbar_hbox);
                toolbar_revealer.transition_type = RevealerTransitionType.SLIDE_DOWN;
            }
            
            var image_container = new ScrolledWindow(null, null);
            {
                image = new TatapImage(true);
                {
                    image.get_style_context().add_class("image-view");
                }
            
                image_container.add(image);
            }

            window_overlay.add(image_container);
            window_overlay.add_overlay(toolbar_revealer);
            window_overlay.set_overlay_pass_through(toolbar_revealer, true);
        }
        
        set_titlebar(headerbar);
        add(window_overlay);
        set_default_size(800, 600);
        configure_event.connect((cr) => {
                if (image.fit) {
                    debug("window::configure_event -> image.fit_image_to_window");
                    image.fit_image_to_window();
                }
                return false;
            });
        destroy.connect(Gtk.main_quit);
        show_all();

        setup_css();
    }

    private void setup_css() {
        Gdk.Screen win_screen = get_screen();
        CssProvider css_provider = new CssProvider();
        try {
            css_provider.load_from_data(stylesheet);
            Gtk.StyleContext.add_provider_for_screen(win_screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (Error e) {
            stderr.printf("CssProvider loading failed!\n");
        }
    }
    
    public void open_file(string filename) {
        string? old_file_dir = null;
        if (image.fileref != null) {
            old_file_dir = image.fileref.get_parent().get_path();
        }
        
        try {
            image.open(filename);
            string new_file_dir = image.fileref.get_parent().get_path();
            if (old_file_dir == null || old_file_dir != new_file_dir) {
                file_list = new TatapFileList(image.fileref.get_parent().get_path());
            }
            file_list.set_current(image.fileref);
            image_prev_button.sensitive = !file_list.file_is_first();
            image_next_button.sensitive = !file_list.file_is_last();
            headerbar.title = image.fileref.get_basename();
        } catch (FileError e) {
            stderr.printf("Error: %s\n", e.message);
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
    }

    private void save_file(string filename) {
        debug("The file name for save: %s", filename);
        File file = File.new_for_path(filename);
        if (FileUtils.test(filename, FileTest.EXISTS)) {
            DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
            var alert = new MessageDialog(this, flags, MessageType.INFO, ButtonsType.OK_CANCEL, Text.FILE_EXISTS);
            var res = alert.run();
            alert.close();

            if (res != ResponseType.OK) {
                return;
            }
        }
        
        Gdk.Pixbuf pixbuf = image.pixbuf;
        string[] tmp = filename.split(".");
        try {
            string extension = tmp[tmp.length - 1];
            if (TatapFileType.is_valid_extension(extension)) {
                pixbuf.save(filename, TatapFileType.to_pixbuf_type(extension)); // TODO other parameters will be required.
            } else {
                throw new TatapError.INVALID_EXTENSION(extension);
            }
        } catch (TatapError e) {
            if (e is TatapError.INVALID_EXTENSION) {
                DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
                var alert = new MessageDialog(this, flags, MessageType.WARNING, ButtonsType.OK, Text.INVALID_EXTENSION);
                alert.run();
                alert.close();
            }
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
    }
    
    private void on_open_button_clicked() {
        var dialog = new FileChooserDialog(Text.FILE_CHOOSER, this, FileChooserAction.OPEN,
                                           Text.CANCEL, ResponseType.CANCEL,
                                           Text.OPEN, ResponseType.ACCEPT);
        var res = dialog.run();
        if (res == ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            open_file(filename);
        }
        dialog.close();
    }

    private void on_save_button_clicked() {
        var dialog = new FileChooserDialog(Text.FILE_CHOOSER, this, FileChooserAction.SAVE,
                                           Text.CANCEL, ResponseType.CANCEL,
                                           Text.OPEN, ResponseType.ACCEPT);
        var res = dialog.run();
        if (res == ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            save_file(filename);
        }
        dialog.close();
    }
}

/**
 * TatapFileList is a custome Gee.LinkedList<File>.
 */
public class TatapFileList : Gee.LinkedList<File> {
    private int current_index;
    
    public TatapFileList(string dir_path) throws FileError {
        if (dir_path == null) {
            return;
        }
        
        Dir dir = Dir.open(dir_path);
        current_index = 0;

        string? result = null;
        do {
            result = add_file_from_dir(dir, dir_path);
        } while (result != null);
    }

    public string? add_file_from_dir(Dir? dir, string dir_path) {
        string? name = dir.read_name();
        if (name == null) {
            return null;
        }
        
        string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);

        if (name == "." || name == ".." || !FileUtils.test(path, FileTest.IS_REGULAR)) {
            return "";
        }
            
        File file = File.new_for_path(path);
        add_file(file);
        return name;
    }

    public void add_file(File file) {
        string mimetype = TatapFileUtils.get_mime_type_from_file(file);

        if (mimetype == null || mimetype.split("/")[0] != "image") {
            return;
        }
            
        bool inserted = false;

        for (int i = 0; i < size; i++) {
            if (file.get_basename().collate(get(i).get_basename()) < 0) {
                debug("[%d] name: %s", i, file.get_basename());
                insert(i, file);
                inserted = true;
                return;
            }
        }

        add(file);
    }
    
    public void set_current(File file) {
        for (int i = 1; i < size; i++) {
            if (get(i).get_path() == file.get_path()) {
                current_index = i;
                return;
            }
        }
    }

    public bool file_is_first() {
        return current_index == 0;
    }

    public bool file_is_last() {
        return current_index == size - 1;
    }

    public File? get_prev_file(File file) {
        if (current_index > 0) {
            current_index--;
            return get(current_index);
        } else {
            return null;
        }
    }

    public File? get_next_file(File file) {
        if (current_index < size - 1) {
            current_index++;
            return get(current_index);
        } else {
            return null;
        }
    }
}

/**
 * TatapImage is a custome image widget
 * that has several image handling function
 * like zoom in/out, fit it to a parent widget, rotate, and flip.
 */
public class TatapImage : Image {
    public static int[] zoom_level = {
        16, 24, 32, 48, 52, 64, 72, 82, 96, 100, 120, 140, 160, 180, 200,
        220, 240, 260, 280, 300, 320, 340, 360, 380, 400, 440, 480, 520,
        560, 600, 640, 680, 720, 760, 800, 880, 960, 1040, 1120, 1200, 1280,
        1360, 1440, 1520, 1600, 1700, 1800, 1900, 2000, 2100, 2200, 2300,
        2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400,
        3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4300, 4400, 4500,
        4600, 4700, 4800, 4900, 5000, 5100, 5200, 5300, 5400, 5500, 5600,
        5700, 5800, 5900, 6000
    };
    public File? fileref { get; set; }
    public bool fit { get; set; }
    public double size_percent { get { return zoom_percent / 10.0; } }
    public int original_height { get { return original_pixbuf.height; } }
    public int original_width { get { return original_pixbuf.width; } }
    public bool has_image { get; set; }
    private Gdk.Pixbuf? original_pixbuf;
    private int zoom_percent = 1000;
    private int? original_max_size;
    private double? original_rate_x;
    private int save_width;
    private int save_height;

    public TatapImage(bool fit) {
        this.fit = fit;
        has_image = false;
    }

    public void open(string filename) throws FileError, Error {
        try {
            File file = File.new_for_path(filename);
            FileInfo info = TatapFileUtils.get_file_info_from_file(file);
            if (info == null || info.get_file_type() != FileType.REGULAR) {
                throw new TatapError.INVALID_FILE(null);
            }
                
            string mime_type = info.get_content_type();

            if (mime_type.split("/")[0] != "image") {
                throw new TatapError.INVALID_FILE(null);
            }

            fileref = file;
            var pixbuf = new Gdk.Pixbuf.from_file(filename);
            original_pixbuf = pixbuf;
            original_max_size = int.max(original_pixbuf.width, original_pixbuf.height);
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            save_width = -1;
            save_height = -1;
            fit_image_to_window();
            has_image = true;
        } catch (TatapError e) {
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
            debug("TatapImage::fit_image_to_window");
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
            debug("TatapImage::scale(%d)", max_size);
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
            debug("TatapImage::scale_xy(%d, %d)", width, height);
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
 * PixbufUtils is used by TatapImage.
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
 * TatapMathUtils contains functions that needs mathmatic 
 * calculation task.
 */
public class TatapMathUtils {
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

public class TatapFileUtils {
    public static FileInfo? get_file_info_from_file(File? file) {
        if (file == null) {
            return null;
        }
        
        try {
            return file.query_info("standard::*", 0);
        } catch (Error e) {
            return null;
        }
    }

    public static string? get_mime_type_from_file(File? file) {
        FileInfo? info = get_file_info_from_file(file);
        if (info != null) {
            return info.get_content_type();
        }
        return null;
    }
}

/**
 * TatapStringUtils contains functions that work with strings.
 */
public class TatapStringUtils {
    public static string convert_from_char(char[] data) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < data.length; i++) {
            sb.append_c(data[i]);
        }
        return sb.str;
    }
}

namespace Text {
#if LANGUAGE_JA
    const string FILE_CHOOSER = "ファイルを開く";
    const string CANCEL = "キャンセル";
    const string OPEN = "開く";
    const string INVALID_EXTENSION = "拡張子の種類が不正です。(jpg, png, bmp, icoから選択して下さい)";
    const  string FILE_EXISTS = "ファイルは既に存在します。上書きしてよろしいですか？";
#else
    const string FILE_CHOOSER = "File Chooser";
    const string CANCEL = "Cancel";
    const string OPEN = "Open";
    const string INVALID_EXTENSION = "This has invalid extension (choose from jpg, png, bmp, or ico)";
    const string FILE_EXISTS = "File is already exists. Do you want to overwrite it?";
#endif    
}
