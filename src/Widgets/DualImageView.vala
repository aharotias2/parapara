/*
 *  Copyright 2019-2021 Tanaka Takayuki (田中喬之)
 *
 *  This file is part of ParaPara.
 *
 *  ParaPara is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  ParaPara is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with ParaPara.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Tanaka Takayuki <aharotias2@gmail.com>
 */

using Gdk, Gtk;

namespace ParaPara {
    public class DualImageView : ImageView, EventBox {
        public ViewMode view_mode { get; construct; }
        public ParaPara.Window main_window { get; construct; }

        public bool controllable { get; set; default = true; }
        public FileList file_list {
            get {
                return _file_list;
            }
            set {
                _file_list = value;
                accessor = new DualFileAccessor.with_file_list(_file_list);
            }
        }

        public string dir_path {
            owned get {
                return _file_list.dir_path;
            }
        }

        public bool has_image {
            get {
                return left_image.has_image || right_image.has_image;
            }
        }

        public int index {
            get {
                int index1 = accessor.get_index1();
                int index2 = accessor.get_index2();
                if (index1 < 0) {
                    if (index2 < 0) {
                        return 0;
                    } else {
                        return index2;
                    }
                } else {
                    return index1;
                }
            }
        }

        public double position {
            get {
                return (double) accessor.get_index1() / (double) _file_list.size;
            }
        }

        private Box dual_box;
        private Image left_image;
        private Image right_image;
        private DualFileAccessor accessor;
        private unowned FileList _file_list;
        private bool button_pressed = false;
        private double x;
        private double y;
        private bool in_progress = false;

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
                    debug("scroll.size_allocated");
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
            if (main_window.toolbar.sort_order == ASC) {
                return !accessor.is_last();
            } else {
                return !accessor.is_first();
            }
        }

        public bool is_prev_button_sensitive() {
            if (main_window.toolbar.sort_order == ASC) {
                return !accessor.is_first();
            } else {
                return !accessor.is_last();
            }
        }

        private enum ClickedArea {
            RIGHT_AREA, LEFT_AREA, OTHER_AREA
        }

        private ClickedArea event_area(Event event) {
            int hpos, vpos;
            WidgetUtils.calc_event_position_percent(event, this, out hpos, out vpos);
            if (20 < vpos < 80) {
                var sort_order = main_window.toolbar.sort_order;
                if (hpos < 25) {
                    if ((sort_order == ASC && !accessor.is_first())
                            || (sort_order == DESC && !accessor.is_last())) {
                        return LEFT_AREA;
                    }
                } else if (hpos > 75) {
                    if ((sort_order == ASC && !accessor.is_last())
                            || (sort_order == DESC && !accessor.is_first())) {
                        return RIGHT_AREA;
                    }
                }
            }
            return OTHER_AREA;
        }

        public override bool button_press_event(EventButton ev) {
            if (!controllable || (!left_image.has_image && !right_image.has_image)) {
                return false;
            }
            if (event_area((Event) ev) == OTHER_AREA && ev.type == 2BUTTON_PRESS) {
                main_window.fullscreen_mode = ! main_window.fullscreen_mode;
            } else {
                button_pressed = true;
                x = ev.x_root;
                y = ev.y_root;
            }
            return false;
        }

        public override bool button_release_event(EventButton ev) {
            if (!controllable || (!left_image.has_image && !right_image.has_image)) {
                return false;
            }

            bool shift_masked =  ModifierType.SHIFT_MASK in ev.state;
            if (x == ev.x_root && y == ev.y_root) {
                var area = event_area((Event) ev);
                switch (area) {
                  case LEFT_AREA:
                    switch (main_window.toolbar.sort_order) {
                      case ASC:
                        if (!accessor.is_first()) {
                            go_backward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                                adjust_cursor(area);
                            });
                            return true;
                        }
                        break;
                      case DESC:
                        if (!accessor.is_last()) {
                            go_forward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                                adjust_cursor(area);
                            });
                            return true;
                        }
                        break;
                    }
                    break;
                  case RIGHT_AREA:
                    switch (main_window.toolbar.sort_order) {
                      case ASC:
                        if (!accessor.is_last()) {
                            go_forward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                                adjust_cursor(area);
                            });
                            return true;
                        }
                        break;
                      case DESC:
                        if (!accessor.is_first()) {
                            go_backward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                                adjust_cursor(area);
                            });
                            return true;
                        }
                        break;
                    }
                    break;
                  default:
                    break;
                }
            }
            button_pressed = false;

            return false;
        }

        private ClickedArea prev_area = OTHER_AREA;

        public override bool motion_notify_event(EventMotion ev) {
            if (!controllable || (!left_image.has_image && !right_image.has_image)) {
                return false;
            }

            var area = event_area((Event) ev);
            if (area != prev_area) {
                adjust_cursor(area);
                prev_area = area;
            }

            return false;
        }

        public override bool scroll_event(EventScroll ev) {
            if (!controllable || (!left_image.has_image && !right_image.has_image)) {
                return false;
            }

            bool shift_masked =  ModifierType.SHIFT_MASK in ev.scroll.state;

            switch (ev.direction) {
              case ScrollDirection.UP:
                if (!accessor.is_first()) {
                    go_backward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                        adjust_cursor(event_area(ev));
                    });
                }
                break;
              case ScrollDirection.DOWN:
                if (!accessor.is_last()) {
                    go_forward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                        adjust_cursor(event_area(ev));
                    });
                }
                break;
              default: break;
            }

            return false;
        }

        public override bool key_press_event(EventKey ev) {
            if (!controllable || (!left_image.has_image && !right_image.has_image)) {
                return false;
            }
            bool shift_masked =  ModifierType.SHIFT_MASK in ev.key.state;
            switch (ev.key.keyval) {
              case Gdk.Key.Left:
                switch (main_window.toolbar.sort_order) {
                  case ASC:
                    if (!accessor.is_first()) {
                        go_backward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                            adjust_cursor(event_area(ev));
                        });
                    }
                    break;
                  case DESC:
                    if (!accessor.is_last()) {
                        go_forward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                            adjust_cursor(event_area(ev));
                        });
                    }
                    break;
                }
                break;
              case Gdk.Key.Right:
                switch (main_window.toolbar.sort_order) {
                  case ASC:
                    if (!accessor.is_last()) {
                        go_forward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                            adjust_cursor(event_area(ev));
                        });
                    }
                    break;
                  case DESC:
                    if (!accessor.is_first()) {
                        go_backward_async.begin(shift_masked ? 1 : 2, (obj, res) => {
                            adjust_cursor(event_area(ev));
                        });
                    }
                    break;
                }
                break;
              default: break;
            }
            return false;
        }

        public async void go_forward_async(int offset = 2) {
            try {
                debug("accessor.get_index1 == %d", accessor.get_index1());
                if (accessor.get_index1() + offset <= file_list.size) {
                    accessor.go_forward(offset);
                    yield reopen_async();
                    if (accessor.get_index1() < 0) {
                        image_opened(accessor.get_name2(), 0);
                    } else {
                        image_opened(accessor.get_name1(), accessor.get_index1());
                    }
                }
            } catch (Error e) {
                main_window.show_error_dialog(e.message);
            }
        }

        public async void go_backward_async(int offset = 2) {
            try {
                debug("accessor.get_index1 == %d", accessor.get_index1());
                if (accessor.get_index1() - offset >= -1) {
                    accessor.go_backward(offset);
                    yield reopen_async();
                    if (accessor.get_index1() < 0) {
                        image_opened(accessor.get_name2(), 0);
                    } else {
                        image_opened(accessor.get_name1(), accessor.get_index1());
                    }
                }
            } catch (Error e) {
                main_window.show_error_dialog(e.message);
            }
        }

        private async void open_by_accessor_current_index() throws Error {
            if (in_progress) {
                return;
            }
            var saved_cursor = get_window().cursor;
            change_cursor(WATCH);
            main_window.disable_controls();
            Idle.add(open_by_accessor_current_index.callback);
            yield;
            try {
                in_progress = true;
                string? left_file_path = null;
                string? right_file_path = null;
                bool left_visible = false;
                bool right_visible = false;
                int index1 = accessor.get_index1();
                int index2 = accessor.get_index2();
                switch (main_window.toolbar.sort_order) {
                  case ASC:
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
                  case DESC:
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
                main_window.toolbar.l2button.sensitive = main_window.image_prev_button.sensitive;
                main_window.toolbar.r2button.sensitive = main_window.image_next_button.sensitive;
                Idle.add(open_by_accessor_current_index.callback);
                yield;
                int width = get_allocated_width() / 2;
                int height = get_allocated_height();
                if (left_file_path != null) {
                    yield left_image.open_async(left_file_path);
                    left_image.scale_fit_in_width_and_height(width, height);
                }
                if (right_file_path != null) {
                    yield right_image.open_async(right_file_path);
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
            } finally {
                get_window().cursor = saved_cursor;
                main_window.enable_controls();
            }
        }

        public async void open_async(File file1) throws Error {
            accessor.set_file1(file1);
            yield reopen_async();

            if (accessor.get_index1() < 0) {
                image_opened(accessor.get_name2(), 0);
            } else {
                image_opened(accessor.get_name1(), accessor.get_index1());
            }
        }

        public async void open_at_async(int index) throws Error {
            debug("open at: %d", index);
            accessor.set_index1(index);
            yield reopen_async();
        }

        public async void reopen_async() throws Error {
            debug("open: %d, %d", accessor.get_index1(), accessor.get_index2());
            try {
                yield open_by_accessor_current_index();
            } catch (Error e) {
                main_window.show_error_dialog(e.message);
            }
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

        private void adjust_cursor(ClickedArea area) {
            switch (area) {
              case LEFT_AREA:
                change_cursor(SB_LEFT_ARROW);
                break;
              case RIGHT_AREA:
                change_cursor(SB_RIGHT_ARROW);
                break;
              default:
                change_cursor(LEFT_PTR);
                break;
            }
        }

        private void change_cursor(CursorType cursor_type) {
            get_window().cursor = new Gdk.Cursor.for_display(Gdk.Screen.get_default().get_display(), cursor_type);
        }
    }
}
