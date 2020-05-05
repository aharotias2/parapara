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

const string stylesheet = """
.image-view {
    background-color: #24140e;
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
    private Button open_button;
    
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
    
    private TatapFileList? file_list = null;

    public TatapWindow() {
        var headerbar = new HeaderBar();
        {
            var button_box1 = new ButtonBox(Orientation.HORIZONTAL);
            {
                open_button = new Button();
                {
                    var open_button_icon = new Image.from_icon_name("document-open-symbolic", ICON_SIZE);

                    open_button.add(open_button_icon);
                    open_button.clicked.connect(() => {
                            on_open_button_clicked();
                        });
                }

                button_box1.add(open_button);
                button_box1.set_layout(ButtonBoxStyle.EXPAND);
            }
            
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
            }
            
            headerbar.pack_start(button_box1);
            headerbar.pack_start(button_box2);
            headerbar.pack_start(button_box3);
            headerbar.show_close_button = true;
        }

        var image_container = new ScrolledWindow(null, null);
        {
            image = new TatapImage(true);
            {
                image.get_style_context().add_class("image-view");
            }
            
            image_container.add(image);
        }
        
        set_titlebar(headerbar);
        add(image_container);
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
        } catch (FileError e) {
            stderr.printf("Error: %s\n", e.message);
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
}

/**
 * TatapFileList is a custome Gee.LinkedList<File>.
 */
public class TatapFileList : Gee.LinkedList<File> {
    private int current_index;
    
    public TatapFileList(string dir_path) throws FileError {
        Dir dir = Dir.open(dir_path);
        string? name = null;
        current_index = 0;

        while ((name = dir.read_name()) != null) {
            if (name != "." && name != "..") {
                continue;
            }

            string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);

            if (!FileUtils.test(path, FileTest.IS_REGULAR)) {
                continue;
            }
            
            File file = File.new_for_path(path);
            string mimetype = TatapFileUtils.get_mime_type_from_file(file);

            if (mimetype == null || mimetype.split("/")[0] != "image") {
                continue;
            }
            
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
    
    public void print_all() {
        debug("TatapFileList contains:\n");
        for (int i = 0; i < size; i++) {
            debug("    %s", get(i).get_basename());
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
        16, 32, 64, 125, 250, 500, 750, 800, 900, 1000, 1250, 1500, 1750, 1800, 1900, 2000, 2500, 3000
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
        File file = File.new_for_path(filename);
        FileInfo info = TatapFileUtils.get_file_info_from_file(file);
        if (info != null && info.get_file_type() == FileType.REGULAR) {
            string mime_type = info.get_content_type();
            if (mime_type.split("/")[0] == "image") {
                fileref = file;
                original_pixbuf = new Gdk.Pixbuf.from_file(filename);
                original_max_size = int.max(original_pixbuf.width, original_pixbuf.height);
                original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
                save_width = -1;
                save_height = -1;
                fit_image_to_window();
                has_image = true;
                return;
            }
        }
        print("Warning: file type is invalid.\n");
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
#else
    const string FILE_CHOOSER = "File Chooser";
    const string CANCEL = "Cancel";
    const string OPEN = "Open";
#endif    
}
