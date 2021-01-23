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
    public Pixbuf? original_pixbuf { get; private set; }

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

    public TatapImage(bool fit) {
        this.fit = fit;
        has_image = false;
        paused_value = true;
        playing = false;
        container = parent;
        file_counter = 0;
    }

    public void open(string filename) throws Error {
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
        Idle.add(() => {
            fit_image_to_window();
            if (is_animation) {
                animate.begin(animation_iter);
            }
            return false;
        });
    }

    public async void animate(Gdk.PixbufAnimationIter animation_iter) {
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
                                prepared_pixbuf_resized
                                        = prepared_pixbuf.scale_simple(pixbuf.width, pixbuf.height, Gdk.InterpType.BILINEAR);
                                next_zoom_percent
                                        = calc_zoom_percent(prepared_pixbuf_resized.height, prepared_pixbuf.height);
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
            int max_width = container.get_allocated_width();
            int max_height = container.get_allocated_height();
            double r0 = (double) max_width / (double) max_height;
            double r1 = original_rate_x;
            if (r0 >= r1) {
                pixbuf = PixbufUtils.scale_by_max_height(original_pixbuf, max_height);
            } else if (r0 < r1) {
                pixbuf = PixbufUtils.scale_by_max_width(original_pixbuf, max_width);
            }
            if (fit) {
                adjust_zoom_percent();
            }
        }
    }

    public void set_scale_percent(uint percentage) {
        if (original_pixbuf != null) {
            scale(percentage);
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
                fit_image_to_window();
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
                fit_image_to_window();
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

    private void scale(uint max_size) {
        if (original_pixbuf != null) {
            debug("TatapImage::scale(%u)", max_size);
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
        debug("zoom: %.1f%%", (double) zoom_percent / 10.0);
    }

    private int calc_zoom_percent(int resized, int original) {
        return resized * 1000 / original;
    }
}
