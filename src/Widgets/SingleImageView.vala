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

using Gdk, Gtk;

namespace Tatap {
    public class SingleImageView : ImageView, Bin {
        public override Tatap.Window main_window { get; construct; }
        public Image image { get; private set; }
        public ScrolledWindow scrolled { get; private set; }
        public override ViewMode view_mode { get; construct; }
        public override bool has_image {
            get {
                return image.has_image;
            }
        }

        private unowned FileList? _file_list = null;
        public SingleFileAccessor accessor { get; private set; }
        private bool button_pressed = false;
        private double x;
        private double y;

        private const string TITLE_FORMAT = "%s (%dx%d : %.2f%%)";

        public override FileList file_list {
            get {
                return _file_list;
            }
            set {
                _file_list = value;
                accessor = new SingleFileAccessor.with_file_list(_file_list);
            }
        }

        public string dir_path {
            owned get {
                return image.fileref.get_parent().get_path();
            }
        }

        public SingleImageView(Window window) {
            Object(
                main_window: window,
                view_mode: ViewMode.SINGLE_VIEW_MODE
            );
        }

        public SingleImageView.with_file_list(Window window, FileList file_list) {
            Object(
                main_window: window,
                view_mode: ViewMode.SINGLE_VIEW_MODE,
                file_list: file_list
            );
        }

        construct {
            scrolled = new ScrolledWindow(null, null);
            {
                image = new Image(true);
                {
                    image.container = scrolled;
                    image.get_style_context().add_class("image-view");
                }

                scrolled.add(image);
                scrolled.size_allocate.connect((allocation) => {
                    if (image.fit) {
                        debug("size_allocated");
                        image.fit_size_to_window();
                        update_title();
                    }
                });
            }

            add(scrolled);
        }

        public bool handle_event(Event ev) throws Error {
            if (!image.has_image) {
                return false;
            }
            switch (ev.type) {
              case EventType.BUTTON_PRESS:
                button_pressed = true;
                x = ev.motion.x_root;
                y = ev.motion.y_root;
                break;
              case EventType.BUTTON_RELEASE:
                if (image.fit && x == ev.motion.x_root && y == ev.motion.y_root) {
                    image.fit_size_to_window();
                    update_title();
                }
                button_pressed = false;
                break;
              case EventType.MOTION_NOTIFY:
                if (button_pressed) {
                    double new_x = ev.motion.x_root;
                    double new_y = ev.motion.y_root;
                    int x_move = (int) (new_x - x);
                    int y_move = (int) (new_y - y);
                    scrolled.hadjustment.value -= x_move;
                    scrolled.vadjustment.value -= y_move;
                    x = new_x;
                    y = new_y;
                }
                break;
              case EventType.SCROLL:
                if (ModifierType.CONTROL_MASK in ev.scroll.state) {
                    switch (ev.scroll.direction) {
                      case ScrollDirection.UP:
                        image.zoom_in(10);
                        update_title();
                        main_window.toolbar.zoom_fit_button.sensitive = true;
                        break;
                      case ScrollDirection.DOWN:
                        image.zoom_out(10);
                        update_title();
                        main_window.toolbar.zoom_fit_button.sensitive = true;
                        break;
                      default: break;
                    }
                } else {
                    if (scrolled.get_allocated_height() >= scrolled.get_vadjustment().upper
                            && scrolled.get_allocated_width() >= scrolled.get_hadjustment().upper) {
                        switch (ev.scroll.direction) {
                          case ScrollDirection.UP:
                            go_backward(1);
                            break;
                          case ScrollDirection.DOWN:
                            go_forward(1);
                            break;
                          default: break;
                        }
                    }
                }
                break;
              case EventType.KEY_PRESS:
                if (Gdk.ModifierType.CONTROL_MASK in ev.key.state) {
                    switch (ev.key.keyval) {
                      case Gdk.Key.e:
                        if (!image.is_animation) {
                            resize_image();
                        }
                        break;
                      case Gdk.Key.plus:
                        image.zoom_in(10);
                        update_title();
                        main_window.toolbar.zoom_fit_button.sensitive = true;
                        break;
                      case Gdk.Key.minus:
                        image.zoom_out(10);
                        update_title();
                        main_window.toolbar.zoom_fit_button.sensitive = true;
                        break;
                      case Gdk.Key.m:
                        if (main_window.toolbar_toggle_button.sensitive) {
                            main_window.toolbar_toggle_button.active = !main_window.toolbar_toggle_button.active;
                            main_window.toolbar_toggle_button.toggled();
                        }
                        break;
                      case Gdk.Key.f:
                        main_window.toolbar_toggle_button.active = true;
                        if (!main_window.toolbar.sticked) {
                            main_window.toolbar.stick_toolbar();
                        } else {
                            main_window.toolbar.unstick_toolbar();
                        }
                        break;
                      case Gdk.Key.@1:
                        image.zoom_original();
                        update_title();
                        main_window.toolbar.zoom_fit_button.sensitive = true;
                        break;
                      case Gdk.Key.@0:
                        image.fit_size_to_window();
                        update_title();
                        main_window.toolbar.zoom_fit_button.sensitive = false;
                        break;
                      case Gdk.Key.h:
                        image.hflip();
                        break;
                      case Gdk.Key.v:
                        image.vflip();
                        break;
                      case Gdk.Key.l:
                        image.rotate_right();
                        update_title();
                        break;
                      case Gdk.Key.r:
                        image.rotate_left();
                        update_title();
                        break;
                      case Gdk.Key.s:
                        save_file_async.begin(false);
                        break;
                      case Gdk.Key.S:
                        save_file_async.begin(true);
                        break;
                      default: break;
                    }
                } else {
                    switch (ev.key.keyval) {
                      case Gdk.Key.Left:
                        go_backward(1);
                        break;
                      case Gdk.Key.Right:
                        go_forward(1);
                        break;
                      case Gdk.Key.space:
                        if (image.is_animation) {
                            if (!image.paused) {
                                image.pause();
                                main_window.toolbar.animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                                main_window.toolbar.animation_forward_button.sensitive = true;
                            } else {
                                image.unpause();
                                main_window.toolbar.animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                                main_window.toolbar.animation_forward_button.sensitive = false;
                            }
                        }
                        break;
                      default: break;
                    }
                }
                break;
              default: break;
            }
            return false;
        }

        public File get_file() throws Error {
            return accessor.get_file();
        }

        public void open(File file) throws Error {
            image.open(file.get_path());
            if (file_list.has_list) {
                accessor.set_name(file.get_basename());
            }
            main_window.image_next_button.sensitive = is_next_button_sensitive();
            main_window.image_prev_button.sensitive = is_prev_button_sensitive();
            if (image.is_animation) {
                main_window.toolbar.animation_play_pause_button.sensitive = true;
                main_window.toolbar.animation_forward_button.sensitive = false;
                main_window.toolbar.resize_button.sensitive = false;
            } else {
                main_window.toolbar.animation_play_pause_button.sensitive = false;
                main_window.toolbar.animation_forward_button.sensitive = false;
                main_window.toolbar.resize_button.sensitive = true;
            }
        }

        public void reopen() throws Error {
            return;
        }

        public void go_backward(int offset = 1) throws Error {
            if (file_list != null) {
                accessor.go_backward();
                File? prev_file = accessor.get_file();
                if (prev_file != null) {
                    main_window.open_file(prev_file);
                }
            }
        }

        public void go_forward(int offset = 1) throws Error {
            if (file_list != null) {
                accessor.go_forward();
                File? next_file = accessor.get_file();
                if (next_file != null) {
                    main_window.open_file(next_file);
                }
            }
        }

        public bool is_next_button_sensitive() {
            if (main_window.toolbar.sort_order == SortOrder.ASC) {
                return !accessor.is_last(true);
            } else {
                return !accessor.is_first(true);
            }
        }

        public bool is_prev_button_sensitive() {
            if (main_window.toolbar.sort_order == SortOrder.ASC) {
                return !accessor.is_first(true);
            } else {
                return !accessor.is_last(true);
            }
        }

        public void update_title() {
            if (image.has_image) {
                string title = TITLE_FORMAT.printf(
                        image.fileref.get_basename(), image.original_width,
                        image.original_height, image.size_percent);
                title_changed(title);
            }
        }

        public void resize_image() {
            var dialog = new ResizeDialog(image.original_width, image.original_height);
            int res = dialog.run();
            dialog.close();
            if (res == Gtk.ResponseType.OK) {
                double old_size_percent = image.size_percent;
                image.resize(dialog.width_value, dialog.height_value);
                image.set_scale_percent((uint) (old_size_percent));
                update_title();
                main_window.show_message_async.begin(_("The image was resized."));
            } else {
                main_window.show_message_async.begin(_("Resizing of the image was canceled."));
            }
        }

        public async void save_file_async(bool with_renaming) {
            if (image.is_animation) {
                Gtk.DialogFlags flags = Gtk.DialogFlags.MODAL;
                Gtk.MessageDialog alert = new Gtk.MessageDialog(main_window, flags, Gtk.MessageType.ERROR,
                        Gtk.ButtonsType.OK, _("Sorry, saving animations is not supported yet."));
                alert.run();
                alert.close();
            } else {
                bool canceled = false;
                string filename = image.fileref.get_path();
                if (with_renaming) {
                    var file_dialog = new Gtk.FileChooserDialog(_("Save as…"), main_window, Gtk.FileChooserAction.SAVE,
                            _("Cancel"), Gtk.ResponseType.CANCEL, _("Save"), Gtk.ResponseType.ACCEPT);
                    file_dialog.set_current_folder(image.fileref.get_parent().get_path());
                    file_dialog.set_current_name(image.fileref.get_basename());
                    file_dialog.show_all();

                    int save_result = file_dialog.run();

                    if (save_result == Gtk.ResponseType.ACCEPT) {
                        filename = file_dialog.get_filename();
                    }
                    file_dialog.close();

                    Idle.add(save_file_async.callback);
                    yield;

                    if (save_result == Gtk.ResponseType.CANCEL) {
                        canceled = true;
                    } else if (GLib.FileUtils.test(filename, GLib.FileTest.EXISTS)) {
                        DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
                        MessageDialog alert = new MessageDialog(main_window, flags, MessageType.INFO, ButtonsType.OK_CANCEL,
                                _("File already exists. Do you want to overwrite it?"));
                        int res = alert.run();
                        alert.close();

                        if (res == ResponseType.CANCEL) {
                            canceled = true;
                        }
                    }
                } else {
                    DialogFlags flags = DialogFlags.DESTROY_WITH_PARENT;
                    MessageDialog confirm_resize = new MessageDialog(main_window, flags, MessageType.INFO, ButtonsType.YES_NO,
                            _("Do you really overwrite this file?"));
                    int res = confirm_resize.run();
                    confirm_resize.close();

                    if (res == ResponseType.NO) {
                        canceled = true;
                    }
                }

                Idle.add(save_file_async.callback);
                yield;

                if (canceled) {
                    main_window.show_message_async.begin(_("The file save was canceled."));
                } else {
                    try {
                        debug("The file name for save: %s", filename);
                        image.original_pixbuf.save(filename, Tatap.FileType.of(filename));
                        main_window.show_message_async.begin(_("The file was saved"));
                    } catch (Error e) {
                        stderr.printf("Error: %s\n", e.message);
                    }
                }
            }
        }

        public void update() {
            try {
                accessor.set_file(image.fileref);
                main_window.image_next_button.sensitive = is_next_button_sensitive();
                main_window.image_prev_button.sensitive = is_prev_button_sensitive();
            } catch (Error e) {
                file_list.close();
            }
        }

        public void close() {
            if (image.is_animation) {
                image.quit_animation();
            }
        }
    }
}
