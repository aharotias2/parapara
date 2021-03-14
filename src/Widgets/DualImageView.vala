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
    public class DualImageView : ImageView, Bin {
        public override ViewMode view_mode { get; construct; }
        public override Tatap.Window main_window { get; construct; }

        public override FileList file_list {
            get {
                return _file_list;
            }
            set {
                _file_list = value;
                accessor = new DualFileAccessor.with_file_list(_file_list);
            }
        }

        public override string dir_path {
            owned get {
                return _file_list.dir_path;
            }
        }

        public override bool has_image {
            get {
                return left_image.has_image || right_image.has_image;
            }
        }

        public override double position {
            get {
                return (double) accessor.get_index1() / (double) _file_list.size;
            }
        }

        private Box dual_box;
        private Image left_image;
        private Image right_image;
        private DualFileAccessor accessor;
        private unowned FileList _file_list;

        private const string TITLE_FORMAT = "%s (%dx%d : %.2f%%), %s (%dx%d : %.2f%%)";

        public DualImageView(Window window) {
            Object(
                main_window: window,
                view_mode: ViewMode.DUAL_VIEW_MODE
            );
        }

        public DualImageView.with_file_list(Window window, FileList file_list) {
            Object(
                main_window: window,
                view_mode: ViewMode.DUAL_VIEW_MODE,
                file_list: file_list
            );
        }

        construct {
            var scroll = new ScrolledWindow(null, null);
            {
                dual_box = new Box(Orientation.HORIZONTAL, 0);
                {
                    left_image = new Image(true);
                    {
                        left_image.halign = Align.END;
                        left_image.container = scroll;
                        left_image.get_style_context().add_class("image-view");
                    }

                    right_image = new Image(true);
                    {
                        right_image.halign = Align.START;
                        right_image.container = scroll;
                        right_image.get_style_context().add_class("image-view");
                    }

                    dual_box.pack_start(left_image, true, true);
                    dual_box.pack_start(right_image, true, true);
                    dual_box.get_style_context().add_class("image-view");
                }

                scroll.add(dual_box);
                scroll.size_allocate.connect((allocation) => {
                    int new_width = allocation.width / 2;
                    int new_height = allocation.height;
                    Idle.add(() => {
                        if (left_image.visible) {
                            left_image.scale_fit_in_width_and_height(new_width, new_height);
                        } else {
                            right_image.margin_start = new_width;
                        }
                        if (right_image.visible) {
                            right_image.scale_fit_in_width_and_height(new_width, new_height);
                        } else {
                            left_image.margin_end = new_width;
                        }
                        update_title();
                        return false;
                    });
                });
            }

            add(scroll);
            debug("Dual image view was created");
        }

        public File get_file() throws Error {
            return get_file1();
        }

        public File get_file1() throws AppError {
            return accessor.get_file1();
        }

        public File get_file2() throws AppError {
            return accessor.get_file2();
        }

        public bool is_next_button_sensitive() {
            if (main_window.toolbar.sort_order == SortOrder.ASC) {
                return !accessor.is_last();
            } else {
                return !accessor.is_first();
            }
        }

        public bool is_prev_button_sensitive() {
            if (main_window.toolbar.sort_order == SortOrder.ASC) {
                return !accessor.is_first();
            } else {
                return !accessor.is_last();
            }
        }

        public bool handle_event(Event ev) throws Error {
            if (!left_image.has_image && !right_image.has_image) {
                return false;
            }
            bool shift_masked = false;
            switch (ev.type) {
              case EventType.SCROLL:
                shift_masked = ModifierType.SHIFT_MASK in ev.scroll.state;
                switch (ev.scroll.direction) {
                  case ScrollDirection.UP:
                    if (!accessor.is_first()) {
                        go_backward(shift_masked ? 1 : 2);
                    }
                    break;
                  case ScrollDirection.DOWN:
                    if (!accessor.is_last()) {
                        go_forward(shift_masked ? 1 : 2);
                    }
                    break;
                  default: break;
                }
                break;
              case EventType.KEY_PRESS:
                shift_masked = ModifierType.SHIFT_MASK in ev.key.state;
                switch (ev.key.keyval) {
                  case Gdk.Key.Left:
                    switch (main_window.toolbar.sort_order) {
                      case SortOrder.ASC:
                        if (!accessor.is_first()) {
                            go_backward(shift_masked ? 1 : 2);
                        }
                        break;
                      case SortOrder.DESC:
                        if (!accessor.is_last()) {
                            go_forward(shift_masked ? 1 : 2);
                        }
                        break;
                    }
                    break;
                  case Gdk.Key.Right:
                    switch (main_window.toolbar.sort_order) {
                      case SortOrder.ASC:
                        if (!accessor.is_last()) {
                            go_forward(shift_masked ? 1 : 2);
                        }
                        break;
                      case SortOrder.DESC:
                        if (!accessor.is_first()) {
                            go_backward(shift_masked ? 1 : 2);
                        }
                        break;
                    }
                    break;
                  default: break;
                }
                break;
              default: break;
            }
            return false;
        }

        public void go_forward(int offset = 2) throws Error {
            accessor.go_forward(offset);
            reopen();
        }

        public void go_backward(int offset = 2) throws Error {
            accessor.go_backward(offset);
            reopen();
        }

        private bool in_progress = false;

        private async void open_by_accessor_current_index() throws Error {
            if (in_progress) {
                return;
            }
            try {
                in_progress = true;
                string? left_file_path = null;
                string? right_file_path = null;
                bool left_visible = false;
                bool right_visible = false;
                int index1 = accessor.get_index1();
                int index2 = accessor.get_index2();
                switch (main_window.toolbar.sort_order) {
                  case SortOrder.ASC:
                    if (index1 >= 0) {
                        left_visible = true;
                        left_file_path = accessor.get_file1().get_path();
                    }
                    if (index2 >= 0) {
                        right_visible = true;
                        right_file_path = accessor.get_file2().get_path();
                    }
                    if (index1 < 0) {
                        main_window.toolbar.l1button.sensitive = false;
                    } else {
                        main_window.toolbar.l1button.sensitive = true;
                    }
                    if (index1 >= _file_list.size - 1) {
                        main_window.toolbar.r1button.sensitive = false;
                    } else {
                        main_window.toolbar.r1button.sensitive = true;
                    }
                    break;
                  case SortOrder.DESC:
                    if (index1 >= 0) {
                        right_visible = true;
                        right_file_path = accessor.get_file1().get_path();
                    }
                    if (index2 >= 0) {
                        left_visible = true;
                        left_file_path = accessor.get_file2().get_path();
                    }
                    if (index1 < 0) {
                        main_window.toolbar.r1button.sensitive = false;
                    } else {
                        main_window.toolbar.r1button.sensitive = true;
                    }
                    if (index1 >= _file_list.size - 1) {
                        main_window.toolbar.l1button.sensitive = false;
                    } else {
                        main_window.toolbar.l1button.sensitive = true;
                    }
                    break;
                }
                main_window.image_next_button.sensitive = is_next_button_sensitive();
                main_window.image_prev_button.sensitive = is_prev_button_sensitive();
                Idle.add(open_by_accessor_current_index.callback);
                yield;
                int width = get_allocated_width() / 2;
                int height = get_allocated_height();
                if (left_file_path != null) {
                    left_image.open(left_file_path);
                    left_image.scale_fit_in_width_and_height(width, height);
                }
                if (right_file_path != null) {
                    right_image.open(right_file_path);
                    right_image.scale_fit_in_width_and_height(width, height);
                }
                left_image.visible = left_visible;
                right_image.visible = right_visible;
                if (!left_visible) {
                    right_image.margin_start = width;
                } else {
                    right_image.margin_start = 0;
                }
                if (!right_visible) {
                    left_image.margin_end = width;
                } else {
                    left_image.margin_end = 0;
                }
                in_progress = false;
            } catch (Error e) {
                in_progress = false;
                throw e;
            }
        }

        public void open(File file1) throws Error {
            accessor.set_file1(file1);
            reopen();

            if (accessor.get_index1() < 0) {
                image_opened(accessor.get_name2(), 0);
            } else {
                image_opened(accessor.get_name1(), accessor.get_index1());
            }
        }

        public void open_at(int index) throws Error {
            debug("open at: %d", index);
            accessor.set_index1(index);
            reopen();
        }

        public void reopen() throws Error {
            debug("open: %d, %d", accessor.get_index1(), accessor.get_index2());
            open_by_accessor_current_index.begin((obj, res) => {
                try {
                    open_by_accessor_current_index.end(res);
                } catch (Error e) {
                    main_window.show_error_dialog(e.message);
                }
            });
        }

        public void update_title() {
            if (left_image.has_image || right_image.has_image) {
                string title = TITLE_FORMAT.printf(
                        left_image.fileref.get_basename(), left_image.original_width,
                        left_image.original_height, left_image.size_percent,
                        right_image.fileref.get_basename(), right_image.original_width,
                        right_image.original_height, right_image.size_percent);
                title_changed(title);
            }
        }

        public void update() {
            try {
                accessor.set_file1(left_image.fileref);
                main_window.image_next_button.sensitive = is_next_button_sensitive();
                main_window.image_prev_button.sensitive = is_prev_button_sensitive();
            } catch (Error e) {
                _file_list.close();
            }
        }

        public void close() {
            return;
        }
    }
}
