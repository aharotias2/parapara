/*
 *  Copyright 2019-2021 Tanaka Takayuki (田中喬之)
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
namespace Tatap {
    public class Window : Gtk.Window {
        private const IconSize ICON_SIZE = IconSize.SMALL_TOOLBAR;

        public bool repeat_updating_file_list { get; construct set; }
        public Tatap.FileList? file_list { get; private set; default = null; }
        public Tatap.ToolBar toolbar { get; private set; }
        public ToggleButton toolbar_toggle_button { get; private set; }
        public Revealer toolbar_revealer_above { get; private set; }
        public Revealer toolbar_revealer_below { get; private set; }
        public Revealer progress_revealer { get; private set; }
        public Scale progress_scale { get; private set; }
        public ImageView image_view { get; private set; }
        public ActionButton image_prev_button { get; private set; }
        public ActionButton image_next_button { get; private set; }

        public bool fullscreen_mode {
            get {
                return _fullscreen_mode;
            }
            set {
                _fullscreen_mode = value;
                if (_fullscreen_mode) {
                    get_window().fullscreen();
                } else {
                    get_window().unfullscreen();
                    Timeout.add(100, () => {
                        try {
                            image_view.reopen();
                        } catch (Error e) {
                            show_error_dialog(e.message);
                        }
                        return false;
                    });
                }
            }
        }

        public signal void require_new_window();
        public signal void require_quit();

        private Box header_buttons;
        private HeaderBar headerbar;
        private Revealer message_revealer;
        private Label message_label;
        private Stack stack;
        private Box bottom_box;
        private Granite.Widgets.Welcome welcome;
        private bool _fullscreen_mode = false;

        construct {
            /* the headerbar itself */
            headerbar = new HeaderBar() {
                    show_close_button = true };
            {
                /* previous, next, open, and save buttons at the left of the headerbar */
                header_buttons = new Box(Orientation.HORIZONTAL, 12);
                {
                    var navigation_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
                            layout_style = Gtk.ButtonBoxStyle.EXPAND };
                    {
                        image_prev_button = new ActionButton("go-previous-symbolic", _("Previous"), {"Left"}) {
                                sensitive = false };
                        {
                            image_prev_button.get_style_context().add_class("image_button");
                            image_prev_button.clicked.connect(() => {
                                int offset = 1;
                                if (image_view.view_mode == ViewMode.DUAL_VIEW_MODE) {
                                    offset = 2;
                                }
                                try {
                                    if (toolbar.sort_order == SortOrder.ASC) {
                                        image_view.go_backward(offset);
                                    } else {
                                        image_view.go_forward(offset);
                                    }
                                } catch (Error error) {
                                    show_error_dialog(error.message);
                                }
                            });
                        }

                        image_next_button = new ActionButton("go-next-symbolic", _("Next"), {"Right"}) {
                                sensitive = false };
                        {
                            image_next_button.get_style_context().add_class("image_button");
                            image_next_button.clicked.connect(() => {
                                int offset = 1;
                                if (image_view.view_mode == ViewMode.DUAL_VIEW_MODE) {
                                    offset = 2;
                                }
                                try {
                                    if (toolbar.sort_order == SortOrder.ASC) {
                                        image_view.go_forward(offset);
                                    } else {
                                        image_view.go_backward(offset);
                                    }
                                } catch (Error error) {
                                    show_error_dialog(error.message);
                                }
                            });
                        }

                        navigation_box.pack_start(image_prev_button);
                        navigation_box.pack_start(image_next_button);
                    }


                    var file_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
                            layout_style = Gtk.ButtonBoxStyle.EXPAND };
                    {
                        /* file buttons */
                        var open_button = new ActionButton("document-open-symbolic", _("Open"), {"<Control>o"});
                        {
                            open_button.clicked.connect(() => {
                                on_open_button_clicked();
                            });
                        }

                        var new_button = new ActionButton("document-new-symbolic", _("New"), {"<Control>n"});
                        {
                            new_button.clicked.connect(() => {
                                require_new_window();
                            });
                        }

                        file_box.pack_start(new_button);
                        file_box.pack_start(open_button);
                    }

                    header_buttons.pack_start(navigation_box, false, false);
                    header_buttons.pack_start(file_box, false, false);
                }

                var header_button_box_right = new ButtonBox(Orientation.HORIZONTAL) {
                        layout_style = ButtonBoxStyle.EXPAND };
                {
                    /* menu button at the right of the headerbar */
                    toolbar_toggle_button = new ToggleButton() {
                            tooltip_markup = Granite.markup_accel_tooltip({"<control>m"}, _("Menu")),
                            relief = Gtk.ReliefStyle.NONE,
                            sensitive = false };
                    {
                        var toggle_toolbar_icon = new Gtk.Image.from_icon_name("view-more-symbolic", ICON_SIZE);
                        toolbar_toggle_button.add(toggle_toolbar_icon);
                        toolbar_toggle_button.toggled.connect(() => {
                            toolbar_revealer_above.reveal_child = toolbar_toggle_button.active;
                        });
                    }

                    header_button_box_right.add(toolbar_toggle_button);
                }

                headerbar.pack_start(header_buttons);
                headerbar.pack_end(header_button_box_right);
            }

            /* switch welcome screen and image view */
            stack = new Stack() { transition_type = StackTransitionType.CROSSFADE };
            {
                /* welcome screen */
                welcome = new Granite.Widgets.Welcome(_("No Images Open"), _("Click 'Open Image' to get started."));
                {
                    welcome.append("document-open", _("Open Image"), _("Show and edit your image."));
                    welcome.activated.connect((i) => {
                        if (i == 0) {
                            on_open_button_clicked();
                        }
                    });
                }

                /* Add images and revealer into overlay */
                var window_overlay = new Overlay();
                {
                    bottom_box = new Box(Orientation.VERTICAL, 0);
                    {
                        /* contain buttons that can be opened from the menu */
                        toolbar = new Tatap.ToolBar(this);
                        {
                            toolbar.sort_order_changed.connect(() => {
                                image_next_button.sensitive = image_view.is_next_button_sensitive();
                                image_prev_button.sensitive = image_view.is_prev_button_sensitive();
                                try {
                                    image_view.reopen();
                                } catch (Error e) {
                                    show_error_dialog(e.message);
                                }
                                progress_scale.inverted = toolbar.sort_order == SortOrder.DESC;
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

                            toolbar.view_mode_changed.connect((view_mode) => {
                                try {
                                    update_image_view(view_mode);
                                } catch (Error error) {
                                    show_error_dialog(error.message);
                                }
                            });

                            toolbar_revealer_below = new Revealer() {
                                transition_type = RevealerTransitionType.SLIDE_DOWN,
                                reveal_child = false
                            };
                        }

                        /* image area in the center of the window */
                        image_view = new SingleImageView(this);
                        {
                            image_view.title_changed.connect((title) => {
                                headerbar.title = title;
                            });
                            image_view.image_opened.connect((name, index) => {
                                progress_scale.set_value((double) index);
                            });
                        }

                        bottom_box.pack_start(toolbar_revealer_below, false, false);
                        bottom_box.pack_start(image_view, true, true);
                    }

                    var revealer_box = new Box(Orientation.VERTICAL, 0);
                    {
                        toolbar_revealer_above = new Revealer() {
                                transition_type = RevealerTransitionType.SLIDE_DOWN,
                                reveal_child = false };
                        {
                            toolbar_revealer_above.add(toolbar);
                        }

                        message_revealer = new Revealer() {
                                transition_type = RevealerTransitionType.SLIDE_UP,
                                transition_duration = 100, reveal_child = false };
                        {
                            var message_bar = new Box(Orientation.HORIZONTAL, 0) {
                                    valign = Align.END, hexpand = true, vexpand = false };
                            {
                                /* revealer showing error messages */
                                message_label = new Label("") {
                                        margin = 10 };
                                {
                                    message_label.get_style_context().add_class("message_label");
                                }

                                message_bar.pack_start(message_label);
                                message_bar.get_style_context().add_class("message_bar");
                            }

                            message_revealer.add(message_bar);
                        }

                        progress_revealer = new Revealer() {
                                transition_type = RevealerTransitionType.SLIDE_UP,
                                transition_duration = 200, reveal_child = false };
                        {
                            var progress_box = new Box(Orientation.HORIZONTAL, 0);
                            {
                                progress_scale = new Scale.with_range(Orientation.HORIZONTAL, 0.0, 1.0, 0.1) {
                                        draw_value = false, has_origin = true, margin = 5 };
                                {
                                    progress_scale.change_value.connect(() => {
                                        try {
                                            image_view.open_at((int) progress_scale.get_value());
                                        } catch (Error e) {
                                            show_error_dialog(e.message);
                                        }
                                    });
                                }

                                progress_box.pack_start(progress_scale, true, true);
                                progress_box.get_style_context().add_class("progress_bar");
                            }

                            progress_revealer.add(progress_box);
                        }

                        revealer_box.pack_start(toolbar_revealer_above, false, false);
                        revealer_box.pack_end(progress_revealer, false, false);
                        revealer_box.pack_end(message_revealer, false, false);
                    }

                    window_overlay.add(bottom_box);
                    window_overlay.add_overlay(revealer_box);
                    window_overlay.set_overlay_pass_through(revealer_box, false);
                }

                stack.add_named(welcome, "welcome");
                stack.add_named(window_overlay, "picture");
            }

            add(stack);

            set_titlebar(headerbar);
            set_default_size(800, 600);
            motion_notify_event.connect((event) => handle_motion_event(event.motion));
            key_press_event.connect((event) => handle_key_event(event.key));
            leave_notify_event.connect((event) => handle_leave_event(event));
            event.connect(handle_other_events);
            add_events(Gdk.EventMask.SCROLL_MASK);
            destroy.connect(() => {
                if (file_list != null) {
                    file_list.close();
                }
                image_view.close();
            });

            setup_css();
        }

        private bool in_progress_area(double x, double y) {
            int win_x_root, win_y_root;
            get_window().get_origin(out win_x_root, out win_y_root);
            Allocation allocation;
            get_allocation(out allocation);
            return (win_y_root + allocation.height * 0.8) < ((int) y) <= win_y_root + allocation.height;
        }

        private bool in_toolbar_area(double x, double y) {
            int win_x_root, win_y_root;
            get_window().get_origin(out win_x_root, out win_y_root);
            Allocation allocation;
            get_allocation(out allocation);
            return win_y_root <= (y - allocation.y) <= win_y_root + allocation.height * 0.2;
        }

        private bool handle_motion_event(EventMotion ev) {
            if (stack.visible_child_name == "picture") {
                if (in_progress_area(ev.x_root, ev.y_root)) {
                    if (!progress_revealer.child_revealed) {
                        Timeout.add(300, () => {
                            progress_revealer.reveal_child = true;
                            return false;
                        });
                    }
                } else {
                    if (progress_revealer.child_revealed) {
                        Timeout.add(300, () => {
                            progress_revealer.reveal_child = false;
                            return false;
                        });
                    }
                }
                if (fullscreen_mode) {
                    if (!toolbar.sticked) {
                        if (in_toolbar_area(ev.x_root, ev.y_root)) {
                            if (!toolbar_revealer_above.child_revealed) {
                                Timeout.add(300, () => {
                                    toolbar_revealer_above.reveal_child = true;
                                    return false;
                                });
                            }
                        } else {
                            if (toolbar_revealer_above.child_revealed) {
                                Timeout.add(300, () => {
                                    toolbar_revealer_above.reveal_child = false;
                                    return false;
                                });
                            }
                        }
                    }
                }
            }
            return false;
        }

        private bool handle_leave_event(EventCrossing event) {
            if (progress_revealer.child_revealed) {
                Timeout.add(300, () => {
                    progress_revealer.reveal_child = false;
                    return false;
                });
            }
            return false;
        }

        private bool handle_key_event(EventKey ev) {
            if (Gdk.ModifierType.CONTROL_MASK in ev.state) {
                switch (ev.keyval) {
                case Gdk.Key.m:
                    if (toolbar_toggle_button.sensitive) {
                        toolbar_toggle_button.active = !toolbar_toggle_button.active;
                        toolbar_toggle_button.toggled();
                    }
                    break;
                case Gdk.Key.f:
                    if (toolbar_revealer_above.child_revealed && !toolbar.sticked) {
                        toolbar_toggle_button.active = true;
                        toolbar.stick_toolbar();
                    } else if (toolbar_revealer_below.child_revealed) {
                        toolbar.unstick_toolbar();
                    }
                    break;
                case Gdk.Key.n:
                    require_new_window();
                    break;
                case Gdk.Key.o:
                    on_open_button_clicked();
                    break;
                case Gdk.Key.w:
                    close();
                    break;
                case Gdk.Key.q:
                    require_quit();
                    break;
                }
            } else {
                switch (ev.keyval) {
                  case Gdk.Key.F11:
                    fullscreen_mode = !fullscreen_mode;
                    break;
                }
            }
            return false;
        }

        private bool handle_other_events(Event ev) {
            try {
                return image_view.handle_event(ev);
            } catch (Error error) {
                show_error_dialog(error.message);
                return false;
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
            if (file_list != null) {
                dialog.set_current_folder(file_list.dir_path);
            }
            int res = dialog.run();
            if (res == Gtk.ResponseType.ACCEPT) {
                var file_path = dialog.get_filename();
                File file = File.new_for_path(file_path);
                open_file(file);
            }
            dialog.close();
        }

        public void open_file(File file) {
            string? old_file_dir = null;
            if (file_list != null) {
                old_file_dir = file_list.dir_path;
            }

            try {
                if (old_file_dir == null || old_file_dir != file.get_parent().get_path()) {
                    if (file_list != null) {
                        file_list.close();
                    }
                    file_list = new Tatap.FileList.with_dir_path(file.get_parent().get_path());
                    file_list.directory_not_found.connect(() => {
                        show_error_dialog(_("The directory does not found. Exiting."));
                        stack.visible_child_name = "welcome";
                    });
                    file_list.file_not_found.connect(() => {
                        show_error_dialog(_("The file does not found."));
                    });
                    file_list.updated.connect(() => {
                        image_view.update();
                        progress_scale.set_range(0.0, (double) (file_list.size - 1));
                        progress_scale.set_value(image_view.position);
                    });
                    file_list.terminated.connect(() => {
                        if (repeat_updating_file_list) {
                            image_prev_button.sensitive = false;
                            image_next_button.sensitive = false;
                        }
                    });
                    file_list.make_list_async.begin(repeat_updating_file_list, (obj, res) => {
                        if (image_view.view_mode != ViewMode.SINGLE_VIEW_MODE) {
                            try {
                                image_view.open(file);
                                image_view.update_title();
                            } catch (Error e) {
                                show_error_dialog(e.message);
                            }
                        }
                    });
                    image_view.file_list = file_list;
                    image_prev_button.sensitive = false;
                    image_next_button.sensitive = false;
                }

                if (image_view.view_mode == ViewMode.SINGLE_VIEW_MODE || file_list.has_list) {
                    image_view.open(file);
                    image_view.update_title();
                }

                toolbar.animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                stack.visible_child_name = "picture";
                toolbar_toggle_button.sensitive = true;
                toolbar.save_button.sensitive = true;
            } catch (Error e) {
                string message;
                if (e is AppError) {
                    message = e.message;
                } else {
                    message = _("The file could not be opend (cause: %s)").printf(e.message);
                }
                show_error_dialog(message);
                if (!image_view.has_image) {
                    stack.visible_child_name = "welcome";
                    toolbar.save_button.sensitive = false;
                }
            }
        }

        public async void show_message_async(string message) {
            Idle.add(show_message_async.callback);
            yield;
            message_label.label = message;
            message_revealer.reveal_child = true;
            Timeout.add(2000, show_message_async.callback);
            yield;
            message_revealer.reveal_child = false;
        }

        public void update_image_view(ViewMode view_mode) throws Error {
            if (image_view.view_mode != view_mode) {
                File file = image_view.get_file();
                bottom_box.remove(image_view);
                switch (view_mode) {
                case SINGLE_VIEW_MODE:
                    image_view = new SingleImageView.with_file_list(this, file_list);
                    break;
                case DUAL_VIEW_MODE:
                    image_view = new DualImageView.with_file_list(this, file_list);
                    image_view.image_opened.connect((name, index) => {
                        progress_scale.set_value((double) index);
                    });
                    break;
                case SCROLL_VIEW_MODE:
                    // TODO: Implement later.
                    return;
                }
                bottom_box.pack_start(image_view, true, true);
                image_view.title_changed.connect((title) => {
                    headerbar.title = title;
                });
                image_view.image_opened.connect((name, index) => {
                    progress_scale.set_value((double) index);
                });
                open_file(file);
                bottom_box.show_all();
            }
        }

        public void show_error_dialog(string message) {
            MessageDialog alert = new MessageDialog(this, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.OK, message);
            alert.run();
            alert.close();
        }
    }
}
