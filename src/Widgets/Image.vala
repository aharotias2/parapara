/*
 *  Copyright 2019-2023 Tanaka Takayuki (田中喬之)
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

using Gtk, Gdk;

/**
 * ParaParaImage is a custome image widget
 * that has several image handling function
 * like zoom in/out, fit it to a parent widget, rotate, and flip.
 */
namespace ParaPara {
    public class Image : Gtk.Image {
        public Container container {
            get;
            set;
        }

        public File? fileref {
            get;
            set;
        }

        public bool fit {
            get;
            set;
        }

        public bool is_animation {
            get;
            private set;
        }

        public bool paused {
            get {
                return paused_value;
            }
            set {
                if (is_animation) {
                    paused_value = value;
                }
            }
        }

        private ViewMode _view_mode;

        public ViewMode view_mode {
            get {
                return _view_mode;
            }
            set {
                _view_mode = value;
            }
        }

        public double size_percent {
            get {
                return zoom_percent / 10.0;
            }
        }

        public int original_height {
            get {
                return original_pixbuf.height;
            }
        }

        public int original_width {
            get {
                return original_pixbuf.width;
            }
        }

        public bool has_image {
            get;
            set;
        }

        public Pixbuf? original_pixbuf {
            get;
            private set;
        }

        private PixbufAnimation? animation;
        private uint zoom_percent = 1000;
        private int? original_max_size;
        private double? original_rate_x;
        private int save_width;
        private int save_height;
        private bool hflipped;
        private bool vflipped;
        private int degree;
        private bool paused_value;
        private bool playing;
        private bool step_once;
        private TimeVal? tval;
        private uint file_counter;

        public Image(bool fit) {
            this.fit = fit;
            has_image = false;
            paused_value = true;
            playing = false;
            container = parent;
            file_counter = 0;
        }

        public void open(string filename) throws AppError, Error {
            animation = new PixbufAnimation.from_file(filename);
            fileref = File.new_for_path(filename);
            tval = TimeVal();
            var animation_iter = animation.get_iter(tval);
            file_counter++;
            original_pixbuf = animation_iter.get_pixbuf();
            original_max_size = int.max(original_pixbuf.width, original_pixbuf.height);
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            save_width = -1;
            save_height = -1;
            hflipped = false;
            vflipped = false;
            degree = 0;
            has_image = true;
            if (!animation.is_static_image()) {
                paused_value = false;
                playing = true;
                is_animation = true;
            } else {
                playing = false;
                paused = true;
                animation_iter = null;
                is_animation = false;
            }
            if (is_animation) {
                animate_async.begin(animation_iter);
            }
        }

        public async void open_async(string filename) throws Error {
            Error? error = null;
            AppError? app_error = null;
            PixbufAnimation? animation_tmp = null;
            var thread = new Thread<int>(filename, () => {
                int status = 0;
                try {
                    animation_tmp = new PixbufAnimation.from_file(filename);
                } catch (AppError e) {
                    app_error = e;
                    status = 1;
                } catch (Error e) {
                    error = e;
                    status = 2;
                }
                Idle.add(open_async.callback);
                return status;
            });
            yield;
            int thread_status = thread.join();
            if (thread_status == 1 || error != null || animation_tmp == null) {
                throw error;
            }
            animation = animation_tmp;
            fileref = File.new_for_path(filename);
            tval = TimeVal();
            var animation_iter = animation.get_iter(tval);
            file_counter++;
            original_pixbuf = animation_iter.get_pixbuf();
            original_max_size = int.max(original_pixbuf.width, original_pixbuf.height);
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            save_width = -1;
            save_height = -1;
            hflipped = false;
            vflipped = false;
            degree = 0;
            has_image = true;
            if (!animation.is_static_image()) {
                paused_value = false;
                playing = true;
                is_animation = true;
            } else {
                playing = false;
                paused = true;
                animation_iter = null;
                is_animation = false;
            }
            if (is_animation) {
                animate_async.begin(animation_iter);
            }
        }

        public async void animate_async(Gdk.PixbufAnimationIter animation_iter) {
            uint count_holder = file_counter;
            Thread<int>? inner_thread = null;
            bool run_thread = false;
            Gdk.Pixbuf? prepared_pixbuf = null;
            Gdk.Pixbuf? prepared_pixbuf_resized = null;
            uint next_zoom_percent = 100;
            while (count_holder == file_counter) {
                if (!paused_value || step_once) {
                    tval.add(animation_iter.get_delay_time() * 1000);
                    animation_iter.advance(tval);
                    run_thread = true;
                    if (inner_thread == null) {
                        inner_thread = new Thread<int>(null, () => {
                            while (count_holder == file_counter) {
                                if (run_thread) {
                                    var next_pixbuf = animation_iter.get_pixbuf();
                                    prepared_pixbuf = PixbufUtils.modify(next_pixbuf, hflipped, vflipped, degree);
                                    if (prepared_pixbuf == null) {
                                        Idle.add(animate_async.callback);
                                        return -1;
                                    }
                                    prepared_pixbuf_resized
                                            = prepared_pixbuf.scale_simple(pixbuf.width, pixbuf.height, Gdk.InterpType.BILINEAR);
                                    next_zoom_percent
                                            = calc_zoom_percent(prepared_pixbuf_resized.height, prepared_pixbuf.height);
                                    run_thread = false;
                                    Idle.add(animate_async.callback);
                                } else {
                                    Thread.yield();
                                }
                            }
                            return 0;
                        });
                    }
                    yield;
                    if (count_holder == file_counter) {
                        original_pixbuf = prepared_pixbuf;
                        pixbuf = prepared_pixbuf_resized;
                        zoom_percent = next_zoom_percent;
                        step_once = false;
                        run_thread = false;
                        Timeout.add(animation_iter.get_delay_time(), animate_async.callback);
                    } else {
                        break;
                    }
                } else {
                    run_thread = false;
                    Idle.add(animate_async.callback);
                }
                yield;
            }
            run_thread = false;
            inner_thread.join();
        }

        public void quit_animation() {
            file_counter = 0;
        }

        public void animate_step_once() {
            step_once = true;
        }

        public void pause() {
            paused_value = true;
        }

        public void unpause() {
            paused_value = false;
        }

        public void zoom_original() {
            if (original_pixbuf != null) {
                pixbuf = original_pixbuf;
                zoom_percent = 1000;
                fit = false;
            }
        }

        public void fit_size_in_window() {
            if (original_pixbuf != null) {
                fit = true;
                int max_width = container.get_allocated_width();
                int max_height = container.get_allocated_height();
                scale_fit_in_width_and_height(max_width, max_height);
                if (fit) {
                    adjust_zoom_percent();
                }
            }
        }

        public void scale_fit_in_width(int new_width) {
            if (original_pixbuf != null) {
                pixbuf = PixbufUtils.scale_fit_in_width(original_pixbuf, new_width);
            }
        }

        public void scale_fit_in_height(int new_height) {
            if (original_pixbuf != null) {
                pixbuf = PixbufUtils.scale_fit_in_height(original_pixbuf, new_height);
            }
        }

        public void scale_fit_in_width_and_height(int new_width, int new_height) {
            if (original_pixbuf != null) {
                double r0 = (double) new_width / (double) new_height;
                double r1 = original_rate_x;
                if (r0 >= r1) {
                    pixbuf = PixbufUtils.scale_fit_in_height(original_pixbuf, new_height);
                } else if (r0 < r1) {
                    pixbuf = PixbufUtils.scale_fit_in_width(original_pixbuf, new_width);
                }
            }
        }

        public void set_scale_percent(uint percentage) {
            if (original_pixbuf != null) {
                int new_width = (int) ((double) original_width * ((double) percentage / 100.0));
                int new_height = (int) ((double) original_height * ((double) percentage / 100.0));
                pixbuf = original_pixbuf.scale_simple(new_width, new_height, Gdk.InterpType.BILINEAR);
                adjust_zoom_percent();
            }
        }

        public void zoom_in(uint plus_percent = 1) {
            if (original_pixbuf != null) {
                zoom_percent += plus_percent;
                scale((uint) (original_max_size * zoom_percent / 1000));
                fit = false;
            }
        }

        public void zoom_out(uint minus_percent = 1) {
            if (original_pixbuf != null) {
                zoom_percent -= minus_percent;
                scale((uint) (original_max_size * zoom_percent / 1000));
                fit = false;
            }
        }

        public void rotate_right() {
            if (original_pixbuf != null) {
                original_pixbuf = original_pixbuf.rotate_simple(PixbufRotation.CLOCKWISE);
                degree = degree == 0 ? 270 : degree - 90;
                original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
                if (fit) {
                    fit_size_in_window();
                    adjust_zoom_percent();
                } else {
                    scale(uint.max((uint) pixbuf.width, (uint) pixbuf.height));
                }
            }
        }

        public void rotate_left() {
            if (original_pixbuf != null) {
                original_pixbuf = original_pixbuf.rotate_simple(PixbufRotation.COUNTERCLOCKWISE);
                degree = degree == 270 ? 0 : degree + 90;
                original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
                if (fit) {
                    fit_size_in_window();
                    adjust_zoom_percent();
                } else {
                    scale(uint.max((uint) pixbuf.width, (uint)pixbuf.height));
                }
            }
        }

        public void hflip() {
            if (original_pixbuf != null) {
                original_pixbuf = original_pixbuf.flip(true);
                scale(uint.max((uint) pixbuf.width, (uint) pixbuf.height));
                hflipped = !hflipped;
            }
        }

        public void vflip() {
            if (original_pixbuf != null) {
                original_pixbuf = original_pixbuf.flip(false);
                scale(uint.max((uint) pixbuf.width, (uint) pixbuf.height));
                vflipped = !vflipped;
            }
        }

        public void resize(uint new_width, uint new_height) {
            var animation_iter = animation.get_iter(tval);
            var fresh_pixbuf = animation_iter.get_pixbuf();
            original_pixbuf = PixbufUtils.modify(fresh_pixbuf, hflipped, vflipped, degree);
            original_pixbuf = original_pixbuf.scale_simple((int) new_width, (int) new_height, Gdk.InterpType.BILINEAR);
            original_max_size = int.max(original_pixbuf.width, original_pixbuf.height);
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            set_scale_percent((int) ((double) original_pixbuf.width / (double) fresh_pixbuf.width * 100.0));
        }

        private void scale(uint max_size) {
            if (original_pixbuf != null) {
                if (max_size != uint.max(save_width, save_height)) {
                    pixbuf = PixbufUtils.scale_limited(original_pixbuf, (int) max_size);
                    if (fit) {
                        adjust_zoom_percent();
                    }
                }
            }
        }

        private void adjust_zoom_percent() {
            zoom_percent = calc_zoom_percent(pixbuf.height, original_pixbuf.height);
        }

        private int calc_zoom_percent(int resized, int original) {
            return resized * 1000 / original;
        }
    }
}
