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

public class NavigationBox : Gtk.ButtonBox {
    public TatapWindow window { get; construct; }

    private Gtk.Button image_prev_button;
    private Gtk.Button image_next_button;

    public NavigationBox (TatapWindow window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.HORIZONTAL,
            layout_style: Gtk.ButtonBoxStyle.EXPAND,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        image_prev_button = new ToolButton("go-previous-symbolic", _("Previous"));
        image_prev_button.get_style_context().add_class("image_button");
        image_prev_button.clicked.connect(() => {
            if (window.file_list != null) {
                File? prev_file = window.file_list.get_prev_file(window.image.fileref);

                if (prev_file != null) {
                    window.open_file(prev_file.get_path());
                }
            }
        });

        image_next_button = new ToolButton("go-next-symbolic", _("Next"));
        image_next_button.get_style_context().add_class("image_button");
        image_next_button.clicked.connect(() => {
            if (window.file_list != null) {
                File? next_file = window.file_list.get_next_file(window.image.fileref);
                debug("next file: %s", next_file.get_basename());

                if (next_file != null) {
                    window.open_file(next_file.get_path());
                }
            }
        });

        add(image_prev_button);
        add(image_next_button);
    }

    public void set_image_prev_button_sensitivity(bool is_sensitive) {
        image_prev_button.sensitive = is_sensitive;
    }

    public void set_image_next_button_sensitivity(bool is_sensitive) {
        image_next_button.sensitive = is_sensitive;
    }
}
