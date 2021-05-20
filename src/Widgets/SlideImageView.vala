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
    public class SlideImageView : ImageView, EventBox {
        public ViewMode view_mode { get; construct; }
        public Tatap.Window main_window { get; construct; }
        public FileList file_list {
            get {
                return _file_list;
            }
            set {
                _file_list = value;
            }
        }
        public bool controllable { get; set; }
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
        public double position { get; }
        public int index { get; }

        private Gee.List<Tatap.Image> widget_list;
        private Box slide_box;
        private ScrolledWindow scroll;
        private FileList _file_list;
        private uint64 size_changed_count;
        private SourceFunc make_view_callback;
        private int saved_width;
        private int saved_height;

        public SlideImageView(Tatap.Window window) {
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
            size_allocate.connect((allocation) => {
                debug("slide image view size allocate to (%d, %d) current size = (%d, %d)", allocation.width, allocation.height, get_allocated_width(), get_allocated_height());
                if (saved_width != allocation.width) {
                    size_changed_count++;
                    fit_images_by_width.begin();
                }
                saved_width = allocation.width;
            });
            debug("slide view mode added scroll");
        }

        private async void fit_images_by_width() {
            if (widget_list == null || widget_list.size == 0) {
                return;
            }
            uint64 tmp = size_changed_count;
            for (int i = 0; i < widget_list.size && tmp == size_changed_count; i++) {
                debug("size_allocated");
                int new_width = scroll.get_allocated_width();
                debug("slide image view resize image %d (%lld) => %d", i, tmp, new_width);
                widget_list[i].scale_fit_in_width(new_width);
                update_title();
                Idle.add(fit_images_by_width.callback);
                yield;
            }
        }

        private bool is_make_view_continue;

        private async void init_async() {
            size_changed_count = 0;
            var saved_cursor = get_window().cursor;
            change_cursor(WATCH);
            Idle.add(init_async.callback);
            yield;
            widget_list = new Gee.ArrayList<Tatap.Image>();
            remove(scroll);
            scroll = new ScrolledWindow(null, null);
            scroll.get_style_context().add_class("image-view");
            scroll.vscrollbar_policy = ALWAYS;
            scroll.hscrollbar_policy = ALWAYS;
            scroll.scroll_event.connect((event) => {
                if (is_make_view_continue && get_scroll_position() > 0.98) {
                    Idle.add((owned) make_view_callback);
                }
                return false;
            });
            add(scroll);
            slide_box = new Box(VERTICAL, 0);
            scroll.add(slide_box);
            show_all();
            Idle.add(init_async.callback);
            yield;

            make_view_async.begin();

            get_window().cursor = saved_cursor;
        }

        private async void make_view_async() {
            is_make_view_continue = true;
            foreach (var filename in file_list) {
                try {
                    string filepath = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, filename);
                    var image_widget = new Tatap.Image(false);
                    image_widget.container = scroll;
                    image_widget.get_style_context().add_class("image-view");
                    image_widget.halign = START;
                    widget_list.add(image_widget);
                    slide_box.pack_start(image_widget, false, false);
                    debug("slide image view make view async image open %s", filepath);
                    yield image_widget.open_async(filepath);
                    image_widget.scale_fit_in_width(get_allocated_width());
                    image_widget.show_all();
                    if (get_scroll_position() < 0.9) {
                        make_view_callback = make_view_async.callback;
                        yield;
                    }
                } catch (Error e) {
                    main_window.show_error_dialog(e.message);
                }
            }
            is_make_view_continue = false;
        }

        private double get_scroll_position() {
            if (slide_box.orientation == VERTICAL) {
                double position = scroll.vadjustment.value / (scroll.vadjustment.upper - scroll.vadjustment.page_size);
                debug("slide image view scroll position: %f", position);
                return position;
            } else {
                double position = scroll.hadjustment.value / (scroll.hadjustment.upper - scroll.hadjustment.page_size);
                debug("slide image view scroll position: %f", position);
                return position;
            }
        }

        public File get_file() throws Error {
            // TODO
            string filename = file_list.get_filename_at(0);
            string filepath = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, filename);
            return File.new_for_path(filepath);
        }

        public bool is_next_button_sensitive() {
            // TODO
            return false;
        }

        public bool is_prev_button_sensitive() {
            // TODO
            return false;
        }

        public async void go_forward_async(int offset = 1) {
            // TODO
            return;
        }

        public async void go_backward_async(int offset = 1) {
            // TODO
            return;
        }

        public async void open_async(File file) throws Error {
            // TODO
            yield init_async();
        }

        public async void reopen_async() throws Error {
            // TODO
            yield open_async(File.new_for_path(file_list.get_filename_at(0)));
        }

        public async void open_at_async(int index) throws Error {
            // TODO
            yield open_async(File.new_for_path(file_list.get_filename_at(index)));
        }

        public void update_title() {
            // TODO
            return;
        }

        public void update() {
            // TODO
            return;
        }

        public void close() {
            // TODO
            return;
        }

        private void change_cursor(CursorType cursor_type) {
            get_window().cursor = new Gdk.Cursor.for_display(Gdk.Screen.get_default().get_display(), cursor_type);
        }
    }
}
