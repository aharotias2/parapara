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
    private const IconSize ICON_SIZE = IconSize.SMALL_TOOLBAR;
    private const string title_format = "%s (%dx%d : %.2f%%)";

    public signal void require_new_window();
    public signal void require_quit();

    private HeaderBar headerbar;
    private HeaderButtons header_buttons;
    private ToggleButton toolbar_toggle_button;
    private ScrolledWindow image_container;
    public TatapImage image { get; private set; }
    private Revealer message_revealer;
    private Label message_label;
    private Stack stack;
    private Granite.Widgets.Welcome welcome;
    private TatapToolBar toolbar;
    private Revealer toolbar_revealer_above;
    private Revealer toolbar_revealer_below;
    public TatapFileList? file_list { get; private set; default = null; }
    private bool button_pressed = false;
    private double x;
    private double y;

    construct {
        /* previous, next, open, and save buttons at the left of the headerbar */
        header_buttons = new HeaderButtons(this);

        /* menu button at the right of the headerbar */
        var toggle_toolbar_icon = new Image.from_icon_name("view-more-symbolic", ICON_SIZE);
        toolbar_toggle_button = new ToggleButton() {
            tooltip_markup = Granite.markup_accel_tooltip({"<control>m"}, _("Menu")),
            relief = Gtk.ReliefStyle.NONE,
            sensitive = false
        };

        toolbar_toggle_button.add(toggle_toolbar_icon);
        toolbar_toggle_button.toggled.connect(() => {
            toolbar_revealer_above.reveal_child = toolbar_toggle_button.active;
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
        welcome = new Granite.Widgets.Welcome(
            _("No Images Open"),
            _("Click 'Open Image' to get started.")
        );
        welcome.append("document-open", _("Open Image"), _("Show and edit your image."));
        welcome.activated.connect((i) => {
            if (i == 0) {
                on_open_button_clicked();
            }
        });

        /* contain buttons that can be opened from the menu */
        toolbar = new TatapToolBar(this);
        toolbar.sort_order_changed.connect(() => {
            set_next_image_button_sensitivity_conditionally();
            set_prev_image_button_sensitivity_conditionally();
        });
        toolbar.stick_button_clicked.connect((sticked) => {
            if (sticked) {
                toolbar_revealer_above.remove(toolbar);
                toolbar_revealer_below.add(toolbar);
                toolbar_revealer_above.reveal_child = false;
                toolbar_revealer_below.reveal_child = true;
                toolbar_toggle_button.sensitive = false;
            } else {
                toolbar_revealer_below.remove(toolbar);
                toolbar_revealer_above.add(toolbar);
                toolbar_revealer_above.reveal_child = true;
                toolbar_revealer_below.reveal_child = false;
                toolbar_toggle_button.sensitive = true;
            }
        });

        toolbar_revealer_below = new Revealer() {
            transition_type = RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };

        /* image area in the center of the window */
        image = new TatapImage(true);
        image.get_style_context().add_class("image-view");

        image_container = new ScrolledWindow(null, null);
        image_container.add(image);
        image_container.scroll_child.connect((a, b) => {
            print("Scroll Event\n");
            return false;
        });

        var bottom_box = new Box(Orientation.VERTICAL, 0);
        bottom_box.pack_start(toolbar_revealer_below, false, false);
        bottom_box.pack_start(image_container, true, true);

        /* switch welcome screen and image view */
        stack = new Stack() {
            transition_type = StackTransitionType.CROSSFADE
        };
        stack.add_named(welcome, "welcome");
        stack.add_named(bottom_box, "picture");

        image.container = image_container;

        toolbar_revealer_above = new Revealer() {
            transition_type = RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };
        toolbar_revealer_above.add(toolbar);

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
        revealer_box.pack_start(toolbar_revealer_above, false, false);
        revealer_box.pack_end(message_revealer, false, false);

        /* Add images and revealer into overlay */
        var window_overlay = new Overlay();
        window_overlay.add(stack);
        window_overlay.add_overlay(revealer_box);
        window_overlay.set_overlay_pass_through(revealer_box, true);

        add(window_overlay);

        set_titlebar(headerbar);
        set_default_size(800, 600);
        event.connect(handle_events);
        add_events (Gdk.EventMask.SCROLL_MASK);
        image_container.size_allocate.connect((allocation) => {
            if (image.fit) {
                if (toolbar_revealer_below.child_revealed) {
                    Idle.add(() => {
                        image.fit_image_to_window();
                        set_title_label();
                        return false;
                    });
                } else {
                    image.fit_image_to_window();
                    set_title_label();
                }
            }
        });
        destroy.connect(() => {
            if (file_list != null) {
                file_list.close();
            }
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
                if (image.fit && x == ev.motion.x_root && y == ev.motion.y_root) {
                    image.fit_image_to_window();
                    set_title_label();
                }
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
                        image.zoom_in(10);
                        set_title_label();
                        toolbar.zoom_fit_button.sensitive = true;
                    } else if (ev.scroll.direction == ScrollDirection.DOWN) {
                        image.zoom_out(10);
                        set_title_label();
                        toolbar.zoom_fit_button.sensitive = true;
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
                if (Gdk.ModifierType.CONTROL_MASK in ev.key.state) {
                    switch (ev.key.keyval) {
                        case Gdk.Key.e:
                            if (image.has_image && !image.is_animation) {
                                resize_image();
                            }
                            break;
                        case Gdk.Key.plus:
                            if (image.has_image) {
                                image.zoom_in(10);
                                set_title_label();
                                toolbar.zoom_fit_button.sensitive = true;
                            }
                            break;
                        case Gdk.Key.minus:
                            if (image.has_image) {
                                image.zoom_out(10);
                                set_title_label();
                                toolbar.zoom_fit_button.sensitive = true;
                            }
                            break;
                        case Gdk.Key.m:
                            if (toolbar_toggle_button.sensitive) {
                                toolbar_toggle_button.active = !toolbar_toggle_button.active;
                                toolbar_toggle_button.toggled();
                            }
                            break;
                        case Gdk.Key.f:
                            if (image.has_image) {
                                toolbar_toggle_button.active = true;
                                if (!toolbar.sticked) {
                                    toolbar.stick_toolbar();
                                } else {
                                    toolbar.unstick_toolbar();
                                }
                            }
                            break;
                        case Gdk.Key.@1:
                            if (image.has_image) {
                                image.zoom_original();
                                set_title_label();
                                toolbar.zoom_fit_button.sensitive = true;
                            }
                            break;
                        case Gdk.Key.@0:
                            if (image.has_image) {
                                image.fit_image_to_window();
                                set_title_label();
                                toolbar.zoom_fit_button.sensitive = false;
                            }
                            break;
                        case Gdk.Key.h:
                            if (image.has_image) {
                                image.hflip();
                            }
                            break;
                        case Gdk.Key.v:
                            if (image.has_image) {
                                image.vflip();
                            }
                            break;
                        case Gdk.Key.l:
                            if (image.has_image) {
                                image.rotate_right();
                                set_title_label();
                            }
                            break;
                        case Gdk.Key.r:
                            if (image.has_image) {
                                image.rotate_left();
                                set_title_label();
                            }
                            break;
                        case Gdk.Key.n:
                            require_new_window();
                            return true;
                        case Gdk.Key.o:
                            on_open_button_clicked();
                            return true;
                        case Gdk.Key.s:
                            if (image.has_image) {
                                save_file.begin(false);
                            }
                            return true;
                        case Gdk.Key.S:
                            if (image.has_image) {
                                save_file.begin(true);
                            }
                            return true;
                        case Gdk.Key.w:
                            close();
                            return true;
                        case Gdk.Key.q:
                            require_quit();
                            return true;
                    }
                }

                switch (ev.key.keyval) {
                    case Gdk.Key.Left:
                        if (image.has_image) {
                            go_prev();
                        }
                        return true;
                    case Gdk.Key.Right:
                        if (image.has_image) {
                            go_next();
                        }
                        return true;
                    case Gdk.Key.space:
                        if (image.is_animation) {
                            if (!image.paused) {
                                image.pause();
                                toolbar.animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                                toolbar.animation_forward_button.sensitive = true;
                            } else {
                                image.unpause();
                                toolbar.animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                                toolbar.animation_forward_button.sensitive = false;
                            }
                        }
                        return true;
                }
                break;
            default:
                break;
        }
        return false;
    }

    public void set_title_label() {
        if (image.has_image) {
            string title = title_format.printf(
                    image.fileref.get_basename(), image.original_width,
                    image.original_height, image.size_percent);
            headerbar.title = title;
        }
    }

    private void setup_css() {
        var css_provider = new CssProvider();
        css_provider.load_from_resource ("/com/github/aharotias2/tatap/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (),
                css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public void on_open_button_clicked() {
        var dialog = new Gtk.FileChooserDialog(_("Choose file to open"), this, Gtk.FileChooserAction.OPEN,
                _("Cancel"), Gtk.ResponseType.CANCEL, _("Open"), Gtk.ResponseType.ACCEPT);
        if (image.fileref != null) {
            dialog.set_current_folder(image.fileref.get_parent().get_path());
        }
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
                if (file_list != null) {
                    file_list.close();
                }
                file_list = new TatapFileList(image.fileref.get_parent().get_path());
                file_list.directory_not_found.connect(() => {
                    DialogFlags flags = DialogFlags.MODAL;
                    MessageDialog alert = new MessageDialog(this, flags, MessageType.ERROR,
                            ButtonsType.OK, _("The directory does not found. Exiting."));
                    alert.run();
                    alert.close();
                    stack.visible_child_name = "welcome";
                });
                file_list.file_not_found.connect(() => {
                    DialogFlags flags = DialogFlags.MODAL;
                    MessageDialog alert = new MessageDialog(this, flags, MessageType.ERROR,
                            ButtonsType.OK, _("The file does not found."));
                    alert.run();
                    alert.close();
                });
                file_list.updated.connect(() => {
                    bool file_in_list = file_list.set_current(image.fileref);
                    if (!file_in_list) {
                        file_list.close();
                    } else {
                        set_next_image_button_sensitivity_conditionally();
                        set_prev_image_button_sensitivity_conditionally();
                    }
                });
                file_list.terminated.connect(() => {
                    header_buttons.image_prev_button.sensitive = false;
                    header_buttons.image_next_button.sensitive = false;
                });
                file_list.make_list_async.begin();
                header_buttons.image_prev_button.sensitive = false;
                header_buttons.image_next_button.sensitive = false;
            } else {
                file_list.set_current(image.fileref);
                set_next_image_button_sensitivity_conditionally();
                set_prev_image_button_sensitivity_conditionally();
            }
            toolbar.animation_play_pause_button.icon_name = "media-playback-start-symbolic";
            if (image.is_animation) {
                toolbar.animation_play_pause_button.sensitive = true;
                toolbar.animation_forward_button.sensitive = false;
                toolbar.resize_button.sensitive = false;
            } else {
                toolbar.animation_play_pause_button.sensitive = false;
                toolbar.animation_forward_button.sensitive = false;
                toolbar.resize_button.sensitive = true;
            }
            stack.visible_child_name = "picture";
            toolbar_toggle_button.sensitive = true;
            set_title_label();
            toolbar.save_button.sensitive = true;
        } catch (Error e) {
            string message;
            if (e is TatapError) {
                message = e.message;
            } else {
                message = _("The file could not be opend (cause: %s)").printf(e.message);
            }
            MessageDialog alert = new MessageDialog(this, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.OK, message);
            alert.run();
            alert.close();
            if (!image.has_image) {
                stack.visible_child_name = "welcome";
                toolbar.save_button.sensitive = false;
            }
        }
    }

    public async void save_file(bool with_renaming) {
        if (image.is_animation) {
            Gtk.DialogFlags flags = Gtk.DialogFlags.MODAL;
            Gtk.MessageDialog alert = new Gtk.MessageDialog(this, flags, Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.OK, _("Sorry, saving animations is not supported yet."));
            alert.run();
            alert.close();
        } else {
            bool canceled = false;
            string filename = image.fileref.get_path();
            if (with_renaming) {
                var file_dialog = new Gtk.FileChooserDialog(_("Save as…"), this, Gtk.FileChooserAction.SAVE,
                        _("Cancel"), Gtk.ResponseType.CANCEL, _("Save"), Gtk.ResponseType.ACCEPT);
                file_dialog.set_current_folder(image.fileref.get_parent().get_path());
                file_dialog.set_current_name(image.fileref.get_basename());
                file_dialog.show_all();

                int save_result = file_dialog.run();

                if (save_result == Gtk.ResponseType.ACCEPT) {
                    filename = file_dialog.get_filename();
                }
                file_dialog.close();

                Idle.add(save_file.callback);
                yield;

                if (save_result == Gtk.ResponseType.ACCEPT) {
                    if (FileUtils.test(filename, FileTest.EXISTS)) {
                        DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
                        MessageDialog alert = new MessageDialog(this, flags, MessageType.INFO, ButtonsType.OK_CANCEL,
                                _("File already exists. Do you want to overwrite it?"));
                        int res = alert.run();
                        alert.close();

                        if (res == ResponseType.CANCEL) {
                            canceled = true;
                        }
                    }
                } else {
                    canceled = true;
                }
            } else {
                DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
                MessageDialog confirm_resize = new MessageDialog(this, flags, MessageType.INFO, ButtonsType.YES_NO,
                        _("Do you really overwrite this file?"));
                int res = confirm_resize.run();
                confirm_resize.close();

                if (res == ResponseType.NO) {
                    canceled = true;
                }
            }

            Idle.add(save_file.callback);
            yield;

            if (canceled) {
                show_message.begin(_("The file save was canceled."));
            } else {
                try {
                    debug("The file name for save: %s", filename);
                    image.original_pixbuf.save(filename, TatapFileType.of(filename));
                    show_message.begin(_("The file was saved"));
                } catch (Error e) {
                    stderr.printf("Error: %s\n", e.message);
                }
            }
        }
    }

    public async void show_message(string message) {
        Idle.add(show_message.callback);
        yield;
        message_label.label = message;
        message_revealer.reveal_child = true;
        Timeout.add(2000, show_message.callback);
        yield;
        message_revealer.reveal_child = false;
    }

    public void go_prev() {
        if (file_list != null) {
            File? prev_file = toolbar.sort_order == SortOrder.ASC
                    ? file_list.get_prev_file() : file_list.get_next_file();
            if (prev_file != null) {
                open_file(prev_file.get_path());
            }
        }
    }

    public void go_next() {
        if (file_list != null) {
            File? next_file = toolbar.sort_order == SortOrder.ASC
                    ? file_list.get_next_file() : file_list.get_prev_file();
            if (next_file != null) {
                open_file(next_file.get_path());
            }
        }
    }

    private void set_next_image_button_sensitivity_conditionally() {
        if (toolbar.sort_order == SortOrder.ASC) {
            header_buttons.image_next_button.sensitive = !file_list.file_is_last(true);
        } else {
            header_buttons.image_next_button.sensitive = !file_list.file_is_first(true);
        }
    }

    private void set_prev_image_button_sensitivity_conditionally() {
        if (toolbar.sort_order == SortOrder.ASC) {
            header_buttons.image_prev_button.sensitive = !file_list.file_is_first(true);
        } else {
            header_buttons.image_prev_button.sensitive = !file_list.file_is_last(true);
        }
    }

    public void resize_image() {
        var dialog = new ResizeDialog(image.original_width, image.original_height);
        int res = dialog.run();
        dialog.close();
        if (res == Gtk.ResponseType.OK) {
            image.resize(dialog.width_value, dialog.height_value);
            set_title_label();
            show_message.begin(_("The image was resized."));
        } else {
            show_message.begin(_("Resizing of the image was canceled."));
        }
    }
}
