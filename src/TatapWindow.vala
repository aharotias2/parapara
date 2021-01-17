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
 *  Tanaka Takayuki <aharotias2@gmail.com>
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

    private HeaderButtons header_buttons;

    private ScrolledWindow image_container;
    public TatapImage image { get; private set; }
    private Revealer message_revealer;
    private Label message_label;
    private Stack stack;
    private ToolBarRevealer toolbar_revealer;

    public TatapFileList? file_list { get; private set; default = null; }

    private bool button_pressed = false;
    private double x;
    private double y;
    private uint? update_view;

    public TatapWindow() {
        /* previous, next, open, and save buttons at the left of the headerbar */
        header_buttons = new HeaderButtons(this);

        /* menu button at the right of the headerbar */
        var toggle_toolbar_icon = new Image.from_icon_name("view-more-symbolic", ICON_SIZE);
        var toolbar_toggle_button = new ToggleButton() {
            tooltip_text = _("Menu")
        };
        toolbar_toggle_button.add(toggle_toolbar_icon);
        toolbar_toggle_button.toggled.connect(() => {
            toolbar_revealer.reveal_child = toolbar_toggle_button.active;
        });

        var header_button_box_right = new ButtonBox(Orientation.HORIZONTAL) {
            layout_style = ButtonBoxStyle.EXPAND
        };
        header_button_box_right.add(toolbar_toggle_button);

        /* the headerbar itself */
        headerbar = new HeaderBar() {
            show_close_button = true
        };
        headerbar.pack_start(header_buttons);
        headerbar.pack_end(header_button_box_right);

        /* welcome screen */
        var welcome = new Granite.Widgets.Welcome(
            _("No Images Open"),
            _("Click 'Open Image' to get started.")
        );
        welcome.append("document-open", _("Open Image"), _("Show and edit your image."));
        welcome.activated.connect((i) => {
            if (i == 0) {
                on_open_button_clicked();
            }
        });

        /* image area in the center of the window */
        image = new TatapImage(true);
        image.get_style_context().add_class("image-view");

        image_container = new ScrolledWindow(null, null);
        image_container.add(image);
        image_container.scroll_child.connect((a, b) => {
            print("Scroll Event\n");
            return false;
        });

        /* switch welcome screen and image view */
        stack = new Stack() {
            transition_type = StackTransitionType.SLIDE_LEFT_RIGHT
        };
        stack.add(welcome);
        stack.add(image_container);

        image.container = stack;

        /* contain buttons that can be opened from the menu */
        toolbar_revealer = new ToolBarRevealer(this);

        /* revealer showing error messages */
        message_label = new Label("") {
            margin = 10
        };
        message_label.get_style_context().add_class("message_label");

        var message_bar = new Box(Orientation.HORIZONTAL, 0) {
            valign = Align.END,
            hexpand = true,
            vexpand = false
        };
        message_bar.pack_start(message_label);
        message_bar.get_style_context().add_class("message_bar");

        message_revealer = new Revealer() {
            transition_type = RevealerTransitionType.SLIDE_UP,
            transition_duration = 100,
            reveal_child = false
        };
        message_revealer.add(message_bar);

        var revealer_box = new Box(Orientation.VERTICAL, 0);
        revealer_box.pack_start(toolbar_revealer, false, false);
        revealer_box.pack_end(message_revealer, false, false);

        /* Add images and revealer into overlay */
        var window_overlay = new Overlay();
        window_overlay.add(stack);
        window_overlay.add_overlay(revealer_box);
        window_overlay.set_overlay_pass_through(revealer_box, true);

        add(window_overlay);

        update_view = Idle.add(() => {
            if (file_list == null || file_list.size == 0) {
                stack.visible_child = welcome;
                header_buttons.set_image_prev_button_sensitivity(false);
                header_buttons.set_image_next_button_sensitivity(false);
                header_buttons.set_save_button_sensitivity(false);
                toolbar_toggle_button.sensitive = false;
            } else {
                stack.visible_child = image_container;
                header_buttons.set_image_prev_button_sensitivity(!file_list.file_is_first(true));
                header_buttons.set_image_next_button_sensitivity(!file_list.file_is_last(true));
                header_buttons.set_save_button_sensitivity(true);
                toolbar_toggle_button.sensitive = true;
            }
            return true;
        });

        set_titlebar(headerbar);
        set_default_size(800, 600);
        event.connect((ev) => {
            return handle_events(ev);
        });
        add_events (Gdk.EventMask.SCROLL_MASK);
        configure_event.connect((cr) => {
            if (image.fit) {
                debug("window::configure_event -> image.fit_image_to_window");
                image.fit_image_to_window();
                set_title_label();
            }
            return false;
        });
        destroy.connect(() => {
            Source.remove(update_view);
            if (image.is_animation) {
                image.quit_animation();
            }
        });

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
                if (ModifierType.CONTROL_MASK in ev.scroll.state) {
                    if (ev.scroll.direction == ScrollDirection.UP) {
                        image.zoom_in();
                        set_title_label();
                        toolbar_revealer.set_zoom_fit_button_sensitivity(true);
                    } else if (ev.scroll.direction == ScrollDirection.DOWN) {
                        image.zoom_out();
                        set_title_label();
                        toolbar_revealer.set_zoom_fit_button_sensitivity(true);
                    }
                    return true;
                } else {
                    if (image_container.get_allocated_height() >= image_container.get_vadjustment().upper
                            && image_container.get_allocated_width() >= image_container.get_hadjustment().upper) {
                        if (ev.scroll.direction == ScrollDirection.UP) {
                            go_prev();
                        } else if (ev.scroll.direction == ScrollDirection.DOWN) {
                            go_next();
                        }
                    }
                }
                break;
            case EventType.KEY_PRESS:
                switch (ev.key.keyval) {
                    case Gdk.Key.Left:
                        go_prev();
                        return true;
                    case Gdk.Key.Right:
                        go_next();
                        return true;
                    case Gdk.Key.space:
                        if (image.is_animation) {
                            if (!image.paused) {
                                image.pause();
                                toolbar_revealer.animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                                toolbar_revealer.animation_forward_button.sensitive = true;
                            } else {
                                image.unpause();
                                toolbar_revealer.animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                                toolbar_revealer.animation_forward_button.sensitive = false;
                            }
                        }
                        break;
                    case Gdk.Key.O: case Gdk.Key.o:
                        on_open_button_clicked();
                        break;
                    case Gdk.Key.Q: case Gdk.Key.q:
                    case Gdk.Key.W: case Gdk.Key.w:
                        close();
                        break;
                }
                break;
            default:
                break;
        }
        return false;
    }

    public void set_title_label() {
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

    public void on_open_button_clicked() {
        var dialog = new Gtk.FileChooserDialog(_("Choose file to open"), this, Gtk.FileChooserAction.OPEN,
                                           _("Cancel"), Gtk.ResponseType.CANCEL,
                                           _("Open"), Gtk.ResponseType.ACCEPT);
        int res = dialog.run();
        if (res == Gtk.ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            open_file(filename);
        }
        dialog.close();
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
            header_buttons.set_image_prev_button_sensitivity(!file_list.file_is_first(true));
            header_buttons.set_image_next_button_sensitivity(!file_list.file_is_last(true));
            if (image.is_animation) {
                toolbar_revealer.animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                toolbar_revealer.animation_play_pause_button.sensitive = true;
            } else {
                toolbar_revealer.animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                toolbar_revealer.animation_play_pause_button.sensitive = false;
                toolbar_revealer.animation_forward_button.sensitive = false;
            }
            set_title_label();
        } catch (FileError e) {
            DialogFlags flags = DialogFlags.MODAL;
            MessageDialog alert = new MessageDialog(this, flags, MessageType.ERROR, ButtonsType.OK,
                    _("The file could not be opend (cause: %s)").printf(e.message));
            alert.run();
            alert.close();
        } catch (Error e) {
            DialogFlags flags = DialogFlags.MODAL;
            MessageDialog alert = new MessageDialog(this, flags, MessageType.ERROR, ButtonsType.OK,
                    _("The file could not be opend (cause: %s)").printf(e.message));
            alert.run();
            alert.close();
        }
    }

    public void save_file(string filename) {
        debug("The file name for save: %s", filename);
        File file = File.new_for_path(filename);
        string full_path = file.get_path();
        if (FileUtils.test(full_path, FileTest.EXISTS)) {
            DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
            MessageDialog alert = new MessageDialog(this, flags, MessageType.INFO, ButtonsType.OK_CANCEL,
                    _("File already exists. Do you want to overwrite it?"));
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
            pixbuf.save(full_path, TatapFileType.to_pixbuf_type(extension));
            Idle.add(() => {
                message_label.label = _("The file is saved.");
                message_revealer.reveal_child = true;
                Timeout.add(2000, () => {
                    message_revealer.reveal_child = false;
                    return Source.REMOVE;
                });
                return Source.REMOVE;
            });
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
    }

    public void go_prev() {
        if (file_list != null) {
            File? prev_file = file_list.get_prev_file(image.fileref);

            if (prev_file != null) {
                open_file(prev_file.get_path());
            }
        }
    }

    public void go_next() {
        if (file_list != null) {
            File? next_file = file_list.get_next_file(image.fileref);

            if (next_file != null) {
                open_file(next_file.get_path());
            }
        }
    }
}
