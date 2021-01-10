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
 * TatapImage is a custome image widget
 * that has several image handling function
 * like zoom in/out, fit it to a parent widget, rotate, and flip.
 */
public class TatapImage : Image {
    public static int[] zoom_level = {
        16, 24, 32, 48, 52, 64, 72, 82, 96, 100, 120, 140, 160, 180, 200,
        220, 240, 260, 280, 300, 320, 340, 360, 380, 400, 440, 480, 520,
        560, 600, 640, 680, 720, 760, 800, 880, 960, 1040, 1120, 1200, 1280,
        1360, 1440, 1520, 1600, 1700, 1800, 1900, 2000, 2100, 2200, 2300,
        2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400,
        3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4300, 4400, 4500,
        4600, 4700, 4800, 4900, 5000, 5100, 5200, 5300, 5400, 5500, 5600,
        5700, 5800, 5900, 6000
    };

    public Container container { get; set; }
    public File? fileref { get; set; }
    public bool fit { get; set; }
    public bool is_animation { get; private set; }
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
    public double size_percent { get { return zoom_percent / 10.0; } }
    public int original_height { get { return original_pixbuf.height; } }
    public int original_width { get { return original_pixbuf.width; } }
    public bool has_image { get; set; }
    private PixbufAnimation? animation;
    private Pixbuf? original_pixbuf;
    private int zoom_percent = 1000;
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

    public TatapImage(bool fit) {
        this.fit = fit;
        has_image = false;
        paused_value = true;
        playing = false;
        container = parent;
        file_counter = 0;
    }

    public void open(string filename) throws FileError, Error {
        try {
            File file = File.new_for_path(filename);
            string? mime_type = TatapFileUtils.get_mime_type_from_file(file);
            if (mime_type == null) {
                throw new TatapError.INVALID_FILE(null);
            }

            fileref = file;
            file_counter++;
            animation = new PixbufAnimation.from_file(filename);
            tval = TimeVal();
            var animation_iter = animation.get_iter(tval);
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
            Idle.add(() => {
                fit_image_to_window();
                if (is_animation) {
                    animate.begin(animation_iter);
                }
                return false;
            });
        } catch (TatapError e) {
            print("Warning: file type is invalid.\n");
        }
    }

    public async void animate(Gdk.PixbufAnimationIter animation_iter) {
        uint count_holder = file_counter;
        Thread<int>? inner_thread = null;
        bool run_thread = false;
        Gdk.Pixbuf? prepared_pixbuf = null;
        Gdk.Pixbuf? prepared_pixbuf_resized = null;
        int next_zoom_percent = 100;
        while (count_holder == file_counter) {
            if (!paused_value || step_once) {
                tval.add(animation_iter.get_delay_time() * 1000);
                animation_iter.advance(tval);
                run_thread = true;
                if (inner_thread == null) {
                    inner_thread = new Thread<int>(null, () => {
                        while (count_holder == file_counter) {
                            if (run_thread) {
                                prepared_pixbuf = animation_iter.get_pixbuf();
                                if (prepared_pixbuf == null) {
                                    Idle.add(animate.callback);
                                    return -1;
                                }
                                if (hflipped) {
                                    prepared_pixbuf = prepared_pixbuf.flip(true);
                                }
                                if (vflipped) {
                                    prepared_pixbuf = prepared_pixbuf.flip(false);
                                }
                                if (degree != 0) {
                                    for (int i_degree = 0; i_degree < degree; i_degree += 90) {
                                        prepared_pixbuf = prepared_pixbuf.rotate_simple(PixbufRotation.COUNTERCLOCKWISE);
                                    }
                                }
                                prepared_pixbuf_resized = return_scale_xy(prepared_pixbuf, pixbuf.width, pixbuf.height);
                                next_zoom_percent = calc_zoom_percent(prepared_pixbuf_resized.height, prepared_pixbuf.height);
                                run_thread = false;
                                Idle.add(animate.callback);
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
                    Timeout.add(animation_iter.get_delay_time(), animate.callback);
                }
            } else {
                run_thread = false;
                Idle.add(animate.callback);
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

    public void fit_image_to_window() {
        if (original_pixbuf != null) {
            fit = true;
            debug("TatapImage::fit_image_to_window");
            int w0 = container.get_allocated_width();
            int h0 = container.get_allocated_height();
            double r0 = (double) w0 / (double) h0;
            double r1 = original_rate_x;
            if (r0 >= r1) {
                scale_xy(-1, h0);
            } else if (r0 < r1) {
                scale_xy(w0, -1);
            }
        }
    }

    public void zoom_in() {
        if (original_pixbuf != null) {
            up_percent();
            scale((int) (original_max_size * zoom_percent / 1000));
            fit = false;
        }
    }

    public void zoom_out() {
        if (original_pixbuf != null) {
            down_percent();
            scale((int) (original_max_size * zoom_percent / 1000));
            fit = false;
        }
    }

    public void rotate_right() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.rotate_simple(PixbufRotation.CLOCKWISE);
            degree = degree == 0 ? 270 : degree - 90;
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            if (fit) {
                fit_image_to_window();
                adjust_zoom_percent();
            } else {
                scale(int.max(pixbuf.width, pixbuf.height));
            }
        }
    }

    public void rotate_left() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.rotate_simple(PixbufRotation.COUNTERCLOCKWISE);
            degree = degree == 270 ? 0 : degree + 90;
            original_rate_x = (double) original_pixbuf.width / (double) original_pixbuf.height;
            if (fit) {
                fit_image_to_window();
                adjust_zoom_percent();
            } else {
                scale(int.max(pixbuf.width, pixbuf.height));
            }
        }
    }

    public void hflip() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.flip(true);
            scale(int.max(pixbuf.width, pixbuf.height));
            hflipped = !hflipped;
        }
    }

    public void vflip() {
        if (original_pixbuf != null) {
            original_pixbuf = original_pixbuf.flip(false);
            scale(int.max(pixbuf.width, pixbuf.height));
            vflipped = !vflipped;
        }
    }

    private void scale(int max_size) {
        if (original_pixbuf != null) {
            debug("TatapImage::scale(%d)", max_size);
            if (max_size != int.max(save_width, save_height)) {
                pixbuf = PixbufUtils.scale_limited(original_pixbuf, max_size);
                if (fit) {
                    adjust_zoom_percent();
                }
            }
        }
    }

    private void scale_xy(int width, int height) {
        if (original_pixbuf != null) {
            debug("TatapImage::scale_xy(%d, %d)", width, height);
            pixbuf = return_scale_xy(original_pixbuf, width, height);
            if (fit) {
                adjust_zoom_percent();
            }
        }
    }

    private void adjust_zoom_percent() {
        zoom_percent = calc_zoom_percent(pixbuf.height, original_pixbuf.height);
        debug("zoom: %.1f%%", (double) zoom_percent / 10.0);
    }

    private void up_percent() {
        for (int i = 0; i < zoom_level.length; i++) {
            if (zoom_percent < zoom_level[i]) {
                zoom_percent = zoom_level[i];
                debug("zoom: %.1f%%", ((double) zoom_percent) / 10.0);
                return;
            }
        }
    }

    private void down_percent() {
        int i = 0;
        int temp = zoom_percent;
        while (zoom_level[i] < zoom_percent && i < zoom_level.length) {
            temp = zoom_level[i];
            i++;
        }
        zoom_percent = temp;
        debug("zoom: %.1f%%", ((double) zoom_percent) / 10.0);
    }

    private int calc_zoom_percent(int resized, int original) {
        return resized * 1000 / original;
    }

    private Gdk.Pixbuf? return_scale_xy(Gdk.Pixbuf? src_pixbuf, int width, int height) {
        if (width >= 0 && height < 0) {
            height = (int) (src_pixbuf.height * ((double) width / (double) src_pixbuf.width));
        } else if (width < 0 && height >= 0) {
            width = (int) (src_pixbuf.width * ((double) height / (double) src_pixbuf.height));
        }
        return PixbufUtils.scale_xy(src_pixbuf, width, height);
    }
}
