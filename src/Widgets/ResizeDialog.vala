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

public class ResizeDialog : Gtk.Dialog {
    private const string FLOAT_FORMAT = "%0.2f";
    private const int MARGIN = 5;
    private Gtk.Entry width_entry;
    private Gtk.Entry height_entry;
    private Gtk.ComboBoxText width_unit_box;
    private Gtk.ComboBoxText height_unit_box;
    public int original_width { construct set; get; }
    public int original_height { construct set; get; }

    public int width_value {
        get {
            if (width_unit_box.get_active_text() == "px") {
                int label_value = int.parse(width_entry.text);
                return label_value;
            } else {
                double label_value = double.parse(width_entry.text);
                return (int) (original_width * label_value / 100.0);
            }
        }
    }

    public int height_value {
        get {
            if (height_unit_box.active == 0) {
                int label_value = int.parse(height_entry.text);
                return label_value;
            } else {
                double label_value = double.parse(height_entry.text);
                return (int) (original_height * label_value / 100.0);
            }
        }
    }

    public ResizeDialog(int original_width, int original_height) {
        Object(use_header_bar: 1, original_width: original_width, original_height: original_height);
    }

    construct {
        var title_label = new Gtk.Label(_("Set the width and the height"));

        var width_label = new Gtk.Label(_("Width:"));
        width_entry = new Gtk.Entry();
        width_entry.max_length = 10;
        width_entry.text = original_width.to_string();
        width_entry.activate.connect(() => {
            adjust_height();
        });
        width_entry.focus_out_event.connect((ev) => {
            adjust_height();
            return false;
        });
        width_unit_box = new Gtk.ComboBoxText();
        width_unit_box.append(null, "px");
        width_unit_box.append(null, "%");
        width_unit_box.active = 0;
        width_unit_box.changed.connect(() => {
            width_entry.text = unit_calc(
                    width_unit_box.get_active_text(), width_entry.text, original_width);
        });

        var height_label = new Gtk.Label(_("Height:"));
        height_entry = new Gtk.Entry();
        height_entry.max_length = 10;
        height_entry.text = original_height.to_string();
        height_entry.activate.connect(() => {
            adjust_width();
        });
        height_entry.focus_out_event.connect((ev) => {
            adjust_width();
            return false;
        });
        height_unit_box = new Gtk.ComboBoxText();
        height_unit_box.append(null, "px");
        height_unit_box.append(null, "%");
        height_unit_box.active = 0;
        height_unit_box.changed.connect(() => {
            height_entry.text = unit_calc(
                    height_unit_box.get_active_text(), height_entry.text, original_height);
        });

        var form_grid = new Gtk.Grid() {
            row_homogeneous = true,
            row_spacing = 5,
            column_spacing = 5,
            margin = 10
        };
        form_grid.attach(width_label, 0, 0);
        form_grid.attach(width_entry, 1, 0);
        form_grid.attach(width_unit_box, 2, 0);
        form_grid.attach(height_label, 0, 1);
        form_grid.attach(height_entry, 1, 1);
        form_grid.attach(height_unit_box, 2, 1);

        Gtk.Box content_area = get_content_area();
        content_area.pack_start(title_label, false, false);
        content_area.pack_start(form_grid, false, false);

        add_button(_("OK"), Gtk.ResponseType.OK);
        add_button(_("Cancel"), Gtk.ResponseType.CANCEL);

        show_all();
    }

    private void adjust_height() {
        int new_height = (int) ((double) width_value * ((double) original_height / (double) original_width));
        if (height_unit_box.get_active_text() == "px") {
            height_entry.text = new_height.to_string();
        } else {
            height_entry.text = FLOAT_FORMAT.printf((double) new_height / (double) original_height * 100.0);
        }
    }

    private void adjust_width() {
        int new_width = (int) ((double) height_value * ((double) original_width / (double) original_height));
        if (width_unit_box.get_active_text() == "px") {
            width_entry.text = new_width.to_string();
        } else {
            width_entry.text = FLOAT_FORMAT.printf((double) new_width / (double) original_width * 100.0);
        }
    }

    private static string unit_calc(string unit, string text, int original_value) {
        if (unit == "px") {
            double curr = double.parse(text);
            int new_value = (int) (original_value * curr / 100);
            return new_value.to_string();
        } else {
            int curr = int.parse(text);
            double new_value = (double) curr / (double) original_value * 100.0;
            return FLOAT_FORMAT.printf(new_value);
        }
    }
}
