/*
 *  Copyright 2019-2020 Tanaka Takayuki (田中喬之) 
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

using Gtk, Gdk;

/**
 * TatapWindow is a customized gtk window class.
 * This is the main window of this program.
 */
public class TatapWindow : Gtk.Window {
    const IconSize ICON_SIZE = IconSize.SMALL_TOOLBAR;

    private const string title_format = "%s (%dx%d : %.2f%%)";
    
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

    private ScrolledWindow image_container;
    private TatapImage image;
    private Revealer message_revealer;
    private Label message_label;
    
    private Revealer toolbar_revealer;
    
    private TatapFileList? file_list = null;

    private bool button_pressed = false;
    private double x;
    private double y;

    public TatapWindow() {
        headerbar = new HeaderBar();
        {
            ButtonBox button_box2 = new ButtonBox(Orientation.HORIZONTAL);
            {
                image_prev_button = new Button.from_icon_name("go-previous-symbolic", ICON_SIZE);
                {
                    image_prev_button.valign = Align.CENTER;
                    image_prev_button.tooltip_text = _("Previous");
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
                    image_next_button.tooltip_text = _("Next");
                    image_next_button.get_style_context().add_class("image_button");
                    image_next_button.clicked.connect(() => {
                            if (file_list != null) {
                                File? next_file = file_list.get_next_file(image.fileref);
                                debug("next file: %s", next_file.get_basename());
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

            ButtonBox header_button_box_right = new ButtonBox(Orientation.HORIZONTAL);
            {
                ToggleButton toolbar_toggle_button = new ToggleButton();
                {
                    Image toggle_toolbar_icon = new Image.from_icon_name("view-more-symbolic", ICON_SIZE);

                    toolbar_toggle_button.tooltip_text = _("Menu");
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

        Overlay window_overlay = new Overlay();
        {
            image_container = new ScrolledWindow(null, null);
            {
                image = new TatapImage(true);
                {
                    image.get_style_context().add_class("image-view");
                }

                image_container.add(image);
                image_container.scroll_child.connect((a, b) => {
                        print("Scroll Event\n");
                        return false;
                    });
            }

            Box revealer_box = new Box(Orientation.VERTICAL, 0);
            {
                toolbar_revealer = new Revealer();
                {
                    Box toolbar_hbox = new Box(Orientation.HORIZONTAL, 0);
                    {
                        ButtonBox button_box1 = new ButtonBox(Orientation.HORIZONTAL);
                        {
                            open_button = new Button();
                            {
                                Image open_button_icon = new Image.from_icon_name("document-open-symbolic",
                                                                                ICON_SIZE);

                                open_button.tooltip_text = _("Open");
                                open_button.add(open_button_icon);
                                open_button.clicked.connect(() => {
                                        on_open_button_clicked();
                                    });
                            }

                            save_button = new Button.from_icon_name("document-save-symbolic", ICON_SIZE);
                            {
                                save_button.tooltip_text = _("Save as…");
                                save_button.clicked.connect(() => {
                                        on_save_button_clicked();
                                    });
                            }

                            button_box1.add(open_button);
                            button_box1.add(save_button);
                            button_box1.set_layout(ButtonBoxStyle.EXPAND);
                            button_box1.margin = 5;
                        }
            
                        ButtonBox button_box3 = new ButtonBox(Orientation.HORIZONTAL);
                        {
                            zoom_in_button = new Button.from_icon_name("zoom-in-symbolic", ICON_SIZE);
                            {
                                zoom_in_button.tooltip_text = _("Zoom in");
                                zoom_in_button.get_style_context().add_class("image_overlay_button");
                                zoom_in_button.clicked.connect(() => {
                                        image.zoom_in();
                                        set_title_label();
                                        zoom_fit_button.sensitive = true;
                                    });
                            }
            
                            zoom_out_button = new Button.from_icon_name("zoom-out-symbolic", ICON_SIZE);
                            {
                                zoom_out_button.tooltip_text = _("Zoom out");
                                zoom_out_button.get_style_context().add_class("image_overlay_button");
                                zoom_out_button.clicked.connect(() => {
                                        image.zoom_out();
                                        set_title_label();
                                        zoom_fit_button.sensitive = true;
                                    });
                            }
            
                            zoom_fit_button = new Button.from_icon_name("zoom-fit-best-symbolic", ICON_SIZE);
                            {
                                zoom_fit_button.tooltip_text = _("Fit to the page");
                                zoom_fit_button.get_style_context().add_class("image_overlay_button");
                                zoom_fit_button.clicked.connect(() => {
                                        image.fit_image_to_window();
                                        set_title_label();
                                        zoom_fit_button.sensitive = false;
                                    });
                            }
            
                            zoom_orig_button = new Button.from_icon_name("zoom-original-symbolic", ICON_SIZE);
                            {
                                zoom_orig_button.tooltip_text = _("100%");
                                zoom_orig_button.get_style_context().add_class("image_overlay_button");
                                zoom_orig_button.clicked.connect(() => {
                                        image.zoom_original();
                                        set_title_label();
                                        zoom_fit_button.sensitive = true;
                                    });
                            }
            
                            hflip_button = new Button.from_icon_name("object-flip-horizontal-symbolic", ICON_SIZE);
                            {
                                hflip_button.tooltip_text = _("Flip horizontally");
                                hflip_button.get_style_context().add_class("image_overlay_button");
                                hflip_button.clicked.connect(() => {
                                        image.hflip();
                                    });
                            }
            
                            vflip_button = new Button.from_icon_name("object-flip-vertical-symbolic", ICON_SIZE);
                            {
                                vflip_button.tooltip_text = _("Flip vertically");
                                vflip_button.get_style_context().add_class("image_overlay_button");
                                vflip_button.clicked.connect(() => {
                                        image.vflip();
                                    });
                            }
            
                            lrotate_button = new Button.from_icon_name("object-rotate-left-symbolic", ICON_SIZE);
                            {
                                lrotate_button.tooltip_text = _("Rotate to the left");
                                lrotate_button.get_style_context().add_class("image_overlay_button");
                                lrotate_button.clicked.connect(() => {
                                        image.rotate_left();
                                        set_title_label();
                                        zoom_fit_button.sensitive = true;
                                    });
                            }

                            rrotate_button = new Button.from_icon_name("object-rotate-right-symbolic", ICON_SIZE);
                            {
                                rrotate_button.tooltip_text = _("Rotate to the right");
                                rrotate_button.get_style_context().add_class("image_overlay_button");
                                rrotate_button.clicked.connect(() => {
                                        image.rotate_right();
                                        set_title_label();
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

                message_revealer = new Revealer();
                {
                    Box message_bar = new Box(Orientation.HORIZONTAL, 0);
                    {
                        message_label = new Label("");
                        {
                            message_label.get_style_context().add_class("message_label");
                            message_label.margin = 10;
                        }

                        message_bar.pack_start(message_label);
                        message_bar.valign = Align.END;
                        message_bar.hexpand = true;
                        message_bar.vexpand = false;
                        message_bar.get_style_context().add_class("message_bar");
                    }
                    
                    message_revealer.add(message_bar);
                    message_revealer.transition_type = RevealerTransitionType.SLIDE_UP;
                    message_revealer.transition_duration = 100;
                    message_revealer.reveal_child = false;
                }

                revealer_box.pack_start(toolbar_revealer, false, false);
                revealer_box.pack_end(message_revealer, false, false);
            }

            window_overlay.add(image_container);
            window_overlay.add_overlay(revealer_box);
            window_overlay.set_overlay_pass_through(revealer_box, true);
        }

        Idle.add(() => {
                if (file_list != null) {
                    if (file_list.size == 0) {
                        image_prev_button.sensitive = false;
                        image_next_button.sensitive = false;
                    } else {
                        image_prev_button.sensitive = !file_list.file_is_first(true);
                        image_next_button.sensitive = !file_list.file_is_last(true);
                    }
                }
                return Source.CONTINUE;
            });
        
        set_titlebar(headerbar);
        add(window_overlay);
        set_default_size(800, 600);
        event.connect((ev) => {
                return handle_events(ev);
            });
        configure_event.connect((cr) => {
                if (image.fit) {
                    debug("window::configure_event -> image.fit_image_to_window");
                    image.fit_image_to_window();
                    set_title_label();
                }
                return false;
            });
        destroy.connect(Gtk.main_quit);

        setup_css();
    }

    private bool handle_events(Event ev) {
        switch (ev.type) {
        case EventType.BUTTON_PRESS:
            button_pressed = true;
            x = ev.motion.x_root;
            y = ev.motion.y_root;
            break;
        case EventType.BUTTON_RELEASE:
            button_pressed = false;
            break;
        case EventType.MOTION_NOTIFY:
            if (button_pressed) {
                double new_x = ev.motion.x_root;
                double new_y = ev.motion.y_root;
                int x_move = (int) (new_x - x);
                int y_move = (int) (new_y - y);
                image_container.hadjustment.value -= x_move;
                image_container.vadjustment.value -= y_move;
                x = new_x;
                y = new_y;
            }
            break;
        case EventType.SCROLL:
            if (ev.scroll.state == ModifierType.CONTROL_MASK) {
                if (ev.scroll.direction == ScrollDirection.UP) {
                    image.zoom_out();
                } else if (ev.scroll.direction == ScrollDirection.DOWN) {
                    image.zoom_in();
                }
                return true;
            }
            break;
        }
        return false;
    }

    private void set_title_label() {
        if (image.has_image) {
            string title = title_format.printf(image.fileref.get_basename(),
                                               image.original_width,
                                               image.original_height,
                                               image.size_percent);
            headerbar.title = title;
        }
    }

    private void setup_css() {
        var css_provider = new CssProvider();
        css_provider.load_from_resource ("/com/github/aharotias2/tatap/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (),
                                                    css_provider,
                                                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
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
                file_list = new TatapFileList();
                file_list.directory_not_found.connect(() => {
                        DialogFlags flags = DialogFlags.MODAL;
                        MessageDialog alert = new MessageDialog(this, flags, MessageType.ERROR,
                                                      ButtonsType.OK, _("The directory does not found. Exiting."));
                        alert.run();
                        alert.close();
                        Gtk.main_quit();
                    });
                file_list.file_not_found.connect(() => {
                        DialogFlags flags = DialogFlags.MODAL;
                        MessageDialog alert = new MessageDialog(this, flags, MessageType.ERROR,
                                                      ButtonsType.OK, _("The file does not found."));
                        alert.run();
                        alert.close();
                    });
                file_list.make_list(image.fileref.get_parent().get_path());
            }
            file_list.set_current(image.fileref);
            image_prev_button.sensitive = !file_list.file_is_first(true);
            image_next_button.sensitive = !file_list.file_is_last(true);
            set_title_label();
        } catch (FileError e) {
            stderr.printf("Error: %s\n", e.message);
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
    }

    private void save_file(string filename) {
        debug("The file name for save: %s", filename);
        File file = File.new_for_path(filename);
        string full_path = file.get_path();
        if (FileUtils.test(full_path, FileTest.EXISTS)) {
            DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
            MessageDialog alert = new MessageDialog(this, flags, MessageType.INFO, ButtonsType.OK_CANCEL, _("File already exists. Do you want to overwrite it?"));
            int res = alert.run();
            alert.close();

            if (res != ResponseType.OK) {
                return;
            }
        }
        
        Pixbuf pixbuf = image.pixbuf;
        string[] tmp = full_path.split(".");
        try {
            string extension = tmp[tmp.length - 1];
            if (TatapFileType.is_valid_extension(extension)) {
                pixbuf.save(full_path, TatapFileType.to_pixbuf_type(extension)); // TODO other parameters will be required.
                Idle.add(() => {
                        message_label.label = _("The file is saved.");
                        message_revealer.reveal_child = true;
                        Timeout.add(2000, () => {
                                message_revealer.reveal_child = false;
                                return Source.REMOVE;
                            });
                        return Source.REMOVE;
                    });
            } else {
                throw new TatapError.INVALID_EXTENSION(extension);
            }
        } catch (TatapError e) {
            if (e is TatapError.INVALID_EXTENSION) {
                DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
                MessageDialog alert = new MessageDialog(this, flags, MessageType.WARNING, ButtonsType.OK, _("This has invalid extension (choose from jpg, png, bmp, or ico)"));
                alert.run();
                alert.close();
            }
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
    }
    
    private void on_open_button_clicked() {
        FileChooserDialog dialog = new FileChooserDialog(_("Choose file to open"), this, FileChooserAction.OPEN,
                                           _("Cancel"), ResponseType.CANCEL,
                                           _("Open"), ResponseType.ACCEPT);
        int res = dialog.run();
        if (res == ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            open_file(filename);
        }
        dialog.close();
    }

    private void on_save_button_clicked() {
        FileChooserDialog dialog = new FileChooserDialog(_("Save as…"), this, FileChooserAction.SAVE,
                                           _("Cancel"), ResponseType.CANCEL,
                                           _("Open"), ResponseType.ACCEPT);
        int res = dialog.run();
        if (res == ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            save_file(filename);
        }
        dialog.close();
    }
}
