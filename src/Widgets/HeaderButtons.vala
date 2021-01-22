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

public class HeaderButtons : Gtk.Box {
    public TatapWindow window { get; construct; }
    public Gtk.ToolButton save_button { get; private set; }

    private ActionButton image_prev_button;
    private ActionButton image_next_button;

    public HeaderButtons (TatapWindow window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.HORIZONTAL,
            spacing: 12
        );
    }

    construct {
        image_prev_button = new ActionButton("go-previous-symbolic", _("Previous"), {"Left"});
        image_prev_button.get_style_context().add_class("image_button");
        image_prev_button.clicked.connect(window.go_prev);

        image_next_button = new ActionButton("go-next-symbolic", _("Next"), {"Right"});
        image_next_button.get_style_context().add_class("image_button");
        image_next_button.clicked.connect(window.go_next);

        var navigation_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };
        navigation_box.pack_start(image_prev_button);
        navigation_box.pack_start(image_next_button);

        /* file buttons */
        var open_button = new ActionButton("document-open-symbolic", _("Open"), {"<Control>o"});
        open_button.clicked.connect(() => {
            window.on_open_button_clicked();
        });

        var save_button = new ActionButton("document-save-as-symbolic", _("Save as…"), {"<Control>s"});
        save_button.clicked.connect(() => {
            window.on_save_button_clicked();
        });

        var new_button = new ActionButton("document-new-symbolic", _("New"), {"<Control>n"});
        new_button.clicked.connect(() => {
            window.require_new_window();
        });

        var file_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };
        file_box.pack_start(new_button);
        file_box.pack_start(open_button);
        file_box.pack_start(save_button);

        pack_start(navigation_box, false, false);
        pack_start(file_box, false, false);
    }

    public void set_image_prev_button_sensitivity(bool is_sensitive) {
        image_prev_button.sensitive = is_sensitive;
    }

    public void set_image_next_button_sensitivity(bool is_sensitive) {
        image_next_button.sensitive = is_sensitive;
    }

    public void set_save_button_sensitivity(bool is_sensitive) {
        save_button.sensitive = is_sensitive;
    }
}
