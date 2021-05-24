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
    public class SlideImageView : ImageView, EventBox {
        private delegate int GetLengthFunc(Widget widget);
        private delegate void ScrollEventFunc();

        private enum ScalingMode {
            FIT_WIDTH, FIT_PAGE, BY_PERCENTAGE
        }

        public ViewMode view_mode { get; construct; }
        public ParaPara.Window main_window { get; construct; }
        public FileList file_list {
            get {
                return _file_list;
            }
            set {
                _file_list = value;
                length_list = new double[_file_list.size];
            }
        }
        public bool controllable { get; set; default = true; }
        public string dir_path {
            owned get {
                return file_list.dir_path;
            }
        }
        public bool has_image {
            get {
                return widget_list.size > 0;
            }
        }
        public double position {
            get {
                return (double) get_location() / (double) file_list.size;
            }
        }
        public int index {
            get {
                return get_location();
            }
        }
        public int page_spacing { get; set; default = 4; }
        public int scroll_interval { get; set; default = 1; }
        public double scroll_amount { get; set; default = 10.0; }
        public double scroll_overlapping { get; set; default = 0.1; }
        public Orientation orientation {
            get {
                return slide_box.orientation;
            }
            set {
                if (slide_box.orientation != value) {
                    slide_box.orientation = value;
                    set_primary_functions();
                    Allocation allocation;
                    int baseline;
                    scroll.get_allocated_size(out allocation, out baseline);
                    saved_width = 0;
                    saved_height = 0;
                    scroll.size_allocate(allocation);
                }
            }
        }

        private Gee.List<ParaPara.Image> widget_list;
        private Box slide_box;
        private ScrolledWindow scroll;
        private FileList _file_list;
        private uint64 resizing_counter;
        private SourceFunc make_view_callback;
        private int saved_width;
        private int saved_height;
        private double[] length_list;
        private ScalingMode scaling_mode = FIT_WIDTH;
        private uint scale_percentage = 0;
        private int prev_location = 0;
        private bool button_pressed = false;
        private double x;
        private double y;
        private int up_to_index;
        private Adjustment primary_adjustment;
        private GetLengthFunc get_widget_length;
        private ScrollEventFunc on_vadjustment_value_changed;
        private ScrollEventFunc on_hadjustment_value_changed;
        private int64 saved_location;

        public SlideImageView(ParaPara.Window window) {
            Object(
                main_window: window,
                view_mode: ViewMode.SLIDE_VIEW_MODE,
                controllable: true
            );
        }

        public SlideImageView.with_file_list(Window window, FileList file_list) {
            Object(
                main_window: window,
                file_list: file_list,
                view_mode: ViewMode.SLIDE_VIEW_MODE,
                controllable: true
            );
        }

        construct {
            scroll = new ScrolledWindow(null, null);
            {
                slide_box = new Box(VERTICAL, 0);
                scroll.add(slide_box);
                debug("slide view mode scroll added slide box");
            }

            add(scroll);
            primary_adjustment = scroll.vadjustment;
            size_allocate.connect((allocation) => {
                debug("slide image view size allocate to (%d, %d) current size = (%d, %d)", allocation.width, allocation.height, get_allocated_width(), get_allocated_height());
                if ((slide_box.orientation == VERTICAL && saved_width != allocation.width)
                        || (slide_box.orientation == HORIZONTAL && saved_height != allocation.height)) {
                    resizing_counter++;
                    switch (scaling_mode) {
                      case FIT_WIDTH:
                        fit_width();
                        break;
                      case FIT_PAGE:
                        fit_page();
                        break;
                      case BY_PERCENTAGE:
                        break;
                    }
                }
                saved_width = allocation.width;
                saved_height = allocation.height;
            });
            debug("slide view mode added scroll");
        }

        public void fit_width() {
            scaling_mode = FIT_WIDTH;
            resizing_counter++;
            fit_images_by_width.begin((obj, res) => {
                if (fit_images_by_width.end(res)) {
                    primary_adjustment.value = length_list[saved_location];
                }
            });
        }

        public void fit_page() {
            scaling_mode = FIT_PAGE;
            resizing_counter++;
            fit_images_by_height.begin((obj, res) => {
                if (fit_images_by_height.end(res)) {
                    primary_adjustment.value = length_list[saved_location];
                }
            });
        }

        public void scale_by_percentage(uint scale_percentage) {
            scaling_mode = BY_PERCENTAGE;
            this.scale_percentage = scale_percentage;
            resizing_counter++;
            scale_images_by_percentage.begin(scale_percentage, (obj, res) => {
                if (scale_images_by_percentage.end(res)) {
                    primary_adjustment.value = length_list[saved_location];
                }
            });
        }

        public File get_file() throws Error {
            string filename = file_list.get_filename_at(get_location());
            string filepath = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, filename);
            return File.new_for_path(filepath);
        }

        public bool is_next_button_sensitive() {
            var adjust = primary_adjustment;
            if (adjust.value < adjust.upper - adjust.page_size) {
                return true;
            } else {
                return false;
            }
        }

        public bool is_prev_button_sensitive() {
            var adjust = primary_adjustment;
            if (adjust.value > 0) {
                return true;
            } else {
                return false;
            }
        }

        public async void go_forward_async(int offset = 1) {
            double start = primary_adjustment.value;
            double page_size = primary_adjustment.page_size;
            double goal = start + page_size - (page_size * scroll_overlapping);
            if (goal > primary_adjustment.upper - page_size) {
                goal = primary_adjustment.upper - page_size;
            }
            Timeout.add(scroll_interval, () => {
                if (primary_adjustment.value < goal) {
                    double a = primary_adjustment.value;
                    double b = a + scroll_amount;
                    debug("slide image view go forward timeout: a = %f, b = %f, goal = %f", a, b, goal);
                    if (b >= goal) {
                        primary_adjustment.value = goal;
                        return false;
                    } else {
                        primary_adjustment.value = b;
                        return true;
                    }
                } else {
                    return false;
                }
            });
        }

        public async void go_backward_async(int offset = 1) {
            double start = primary_adjustment.value;
            double page_size = primary_adjustment.page_size;
            double goal = start - page_size + (page_size * scroll_overlapping);
            if (goal < 0) {
                goal = 0.0;
            }
            Timeout.add(scroll_interval, () => {
                if (primary_adjustment.value > goal) {
                    double a = primary_adjustment.value;
                    double b = a - scroll_amount;
                    debug("slide image view go backward timeout: a = %f, b = %f, goal = %f", a, b, goal);
                    if (b < goal) {
                        primary_adjustment.value = goal;
                        return false;
                    } else {
                        primary_adjustment.value = b;
                        return true;
                    }
                } else {
                    return false;
                }
            });
        }

        public async void open_async(File file) throws Error {
            debug("open %s", file.get_basename());
            int index = file_list.get_index_of(file.get_basename());
            yield init_async(index);
            image_opened(file.get_basename(), index);
        }

        public async void reopen_async() throws Error {
            yield open_at_async(get_location());
        }

        public async void open_at_async(int index) throws Error {
            if (widget_list.size < index) {
                up_to_index = index;
                Idle.add((owned) make_view_callback);
                while (widget_list.size < index) {
                    Idle.add(open_at_async.callback);
                    yield;
                }
            }
            primary_adjustment.value = index > 0 ? length_list[index - 1] : 0;
            image_opened(file_list.get_filename_at(index), index);
        }

        public void update_title() {
            try {
                int index = get_location();
                string filename = file_list.get_filename_at(index);
                title_changed(filename);
            } catch (AppError e) {
                main_window.show_error_dialog(e.message);
            }
        }

        public void update() {
            main_window.image_next_button.sensitive = is_next_button_sensitive();
            main_window.image_prev_button.sensitive = is_prev_button_sensitive();
        }

        public void close() {
            foreach (var image in widget_list) {
                if (image.is_animation) {
                    image.quit_animation();
                }
            }
        }

        public override bool button_press_event(EventButton ev) {
            if (!controllable) {
                return false;
            }

            if (ev.type == 2BUTTON_PRESS) {
                main_window.fullscreen_mode = ! main_window.fullscreen_mode;
                return true;
            } else {
                button_pressed = true;
                x = ev.x_root;
                y = ev.y_root;
                return false;
            }
        }

        public override bool button_release_event(EventButton ev) {
            if (!controllable) {
                return false;
            }

            button_pressed = false;
            return false;
        }

        public override bool motion_notify_event(EventMotion ev) {
            if (!controllable) {
                return false;
            }

            if (button_pressed) {
                double new_x = ev.x_root;
                double new_y = ev.y_root;
                int x_move = (int) (new_x - x);
                int y_move = (int) (new_y - y);
                scroll.hadjustment.value -= x_move;
                scroll.vadjustment.value -= y_move;
                x = new_x;
                y = new_y;
            }

            return false;
        }

        public override bool key_press_event(EventKey ev) {
            if (!controllable) {
                return false;
            }
            switch (ev.keyval) {
              case Gdk.Key.Page_Down:
                go_forward_async.begin();
                break;
              case Gdk.Key.Page_Up:
                go_backward_async.begin();
                break;
              case Gdk.Key.Down:
                primary_adjustment.value += scroll_amount;
                break;
              case Gdk.Key.Up:
                primary_adjustment.value -= scroll_amount;
                break;
              default:
                break;
            }
            return false;
        }

        private async bool fit_images_by_width() {
            if (widget_list == null || widget_list.size == 0) {
                return false;
            }
            uint64 tmp = resizing_counter;
            int i = 0;
            for (i = 0; i < widget_list.size && tmp == resizing_counter; i++) {
                int new_width = scroll.get_allocated_width() - page_spacing * 2;
                widget_list[i].scale_fit_in_width(new_width);
                Idle.add(fit_images_by_width.callback);
                yield;
                length_list[i] = (i > 0 ? length_list[i - 1] : 0) + (double) (get_widget_length(widget_list[i]) + page_spacing);
                update_title();
                Idle.add(fit_images_by_width.callback);
                yield;
            }
            return i >= widget_list.size;
        }

        private async bool fit_images_by_height() {
            if (widget_list == null || widget_list.size == 0) {
                return false;
            }
            uint64 tmp = resizing_counter;
            int i = 0;
            for (i = 0; i < widget_list.size && tmp == resizing_counter; i++) {
                int new_height = scroll.get_allocated_height() - page_spacing * 2;
                widget_list[i].scale_fit_in_height(new_height);
                Idle.add(fit_images_by_height.callback);
                yield;
                length_list[i] = (i > 0 ? length_list[i - 1] : 0) + (double) (get_widget_length(widget_list[i]) + page_spacing);
                update_title();
                Idle.add(fit_images_by_height.callback);
                yield;
            }
            return i >= widget_list.size;
        }

        private async bool scale_images_by_percentage(uint percentage) {
            if (widget_list == null || widget_list.size == 0) {
                return false;
            }
            uint64 tmp = resizing_counter;
            int i = 0;
            for (i = 0; i < widget_list.size && tmp == resizing_counter; i++) {
                widget_list[i].set_scale_percent(percentage);
                Idle.add(scale_images_by_percentage.callback);
                yield;
                length_list[i] = (i > 0 ? length_list[i - 1] : 0) + (double) (get_widget_length(widget_list[i]) + page_spacing);
                update_title();
                Idle.add(scale_images_by_percentage.callback);
                yield;
            }
            return i >= widget_list.size;
        }

        private bool is_make_view_continue;

        private async void init_async(int index = 0) {
            resizing_counter = 0;
            var saved_cursor = get_window().cursor;
            change_cursor(WATCH);
            Idle.add(init_async.callback);
            yield;
            widget_list = new Gee.ArrayList<ParaPara.Image>();
            remove(scroll);
            scroll = new ScrolledWindow(null, null) {
                hscrollbar_policy = EXTERNAL,
                vscrollbar_policy = EXTERNAL
            };
            scroll.get_style_context().add_class("image-view");
            scroll.scroll_event.connect((event) => {
                debug("slide image view scroll to %f", scroll.vadjustment.value);
                saved_location = get_location();
                if (is_make_view_continue && get_scroll_position() > 0.98) {
                    Idle.add((owned) make_view_callback);
                }
                return false;
            });
            scroll.vadjustment.value_changed.connect(() => {
                on_vadjustment_value_changed();
            });
            scroll.hadjustment.value_changed.connect(() => {
                on_hadjustment_value_changed();
            });
            add(scroll);
            set_primary_functions();
            slide_box = new Box(slide_box.orientation, page_spacing) {
                margin = page_spacing
            };
            scroll.add(slide_box);
            show_all();
            Idle.add(init_async.callback);
            yield;

            make_view_async.begin(index);

            get_window().cursor = saved_cursor;
        }

        private async void make_view_async(int index = 0) {
            up_to_index = index;
            change_cursor(WATCH);
            Idle.add(make_view_async.callback);
            yield;
            for (int i = 0; i < file_list.size; i++) {
                try {
                    string filename = file_list.get_filename_at(i);
                    string filepath = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, filename);
                    var image_widget = new ParaPara.Image(false) {
                        container = scroll,
                        halign = CENTER
                    };
                    image_widget.get_style_context().add_class("image-view");
                    widget_list.add(image_widget);
                    slide_box.pack_start(image_widget, false, false);
                    yield image_widget.open_async(filepath);
                    switch (scaling_mode) {
                      case FIT_WIDTH:
                        image_widget.scale_fit_in_width(get_allocated_width() - page_spacing * 2);
                        break;
                      case FIT_PAGE:
                        image_widget.scale_fit_in_height(get_allocated_height() - page_spacing * 2);
                        break;
                      case BY_PERCENTAGE:
                        image_widget.set_scale_percent(scale_percentage);
                        break;
                    }
                    image_widget.show_all();
                    Idle.add(make_view_async.callback);
                    yield;
                    length_list[i] = (i > 0 ? length_list[i - 1] : 0) + get_widget_length(image_widget) + page_spacing;
                    if (i == up_to_index) {
                        if (i > 0) {
                            primary_adjustment.value = length_list[i - 1];
                        }
                        change_cursor(LEFT_PTR);
                        Idle.add(make_view_async.callback);
                        yield;
                    } else if (i > up_to_index && get_scroll_position() < 0.9) {
                        is_make_view_continue = true;
                        make_view_callback = make_view_async.callback;
                        yield;
                        is_make_view_continue = false;
                    }
                } catch (Error e) {
                    main_window.show_error_dialog(e.message);
                }
            }
        }

        private double get_scroll_position() {
            double position = primary_adjustment.value / (primary_adjustment.upper - primary_adjustment.page_size);
            debug("slide image view scroll position: %f", position);
            return position;
        }

        private int get_location() {
            double pos = 0.0;
            pos = primary_adjustment.value;
            for (int i = 0; i < length_list.length; i++) {
                debug("slide image view get location (pos: %f, index = %d, value = %f)", pos, i, length_list[i]);
                if (pos <= length_list[i]) {
                    return i;
                }
            }
            return length_list.length - 1;
        }

        private void change_cursor(CursorType cursor_type) {
            main_window.get_window().cursor = new Gdk.Cursor.for_display(Gdk.Screen.get_default().get_display(), cursor_type);
        }

        private void set_primary_functions() {
            if (orientation == VERTICAL) {
                primary_adjustment = scroll.vadjustment;
                get_widget_length = (widget) => {
                    return widget.get_allocated_height();
                };
                on_vadjustment_value_changed = () => {
                    main_window.image_prev_button.sensitive = is_prev_button_sensitive();
                    main_window.image_next_button.sensitive = is_next_button_sensitive();
                    int location = get_location();
                    if (prev_location != location) {
                        update_title();
                        try {
                            string filename = file_list.get_filename_at(location);
                            image_opened(filename, location);
                        } catch (AppError e) {
                            main_window.show_error_dialog(e.message);
                        }
                    }
                    prev_location = location;
                    if (is_make_view_continue && get_scroll_position() > 0.98) {
                        Idle.add((owned) make_view_callback);
                    }
                };
                on_hadjustment_value_changed = () => {};
            } else {
                primary_adjustment = scroll.hadjustment;
                get_widget_length = (widget) => {
                    return widget.get_allocated_width();
                };
                on_vadjustment_value_changed = () => {};
                on_hadjustment_value_changed = () => {
                    main_window.image_prev_button.sensitive = is_prev_button_sensitive();
                    main_window.image_next_button.sensitive = is_next_button_sensitive();
                    int location = get_location();
                    if (prev_location != location) {
                        update_title();
                        try {
                            string filename = file_list.get_filename_at(location);
                            image_opened(filename, location);
                        } catch (AppError e) {
                            main_window.show_error_dialog(e.message);
                        }
                    }
                    prev_location = location;
                    if (is_make_view_continue && get_scroll_position() > 0.98) {
                        Idle.add((owned) make_view_callback);
                    }
                };
            }
        }
    }
}
