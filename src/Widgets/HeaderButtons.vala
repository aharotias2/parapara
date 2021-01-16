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

    private ActionButton image_prev_button;
    private ActionButton image_next_button;
    private ActionButton save_button;
    private ActionButton open_button;

    public HeaderButtons (TatapWindow window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.HORIZONTAL,
            spacing: 12
        );
    }

    construct {
        image_prev_button = new ActionButton("go-previous-symbolic", _("Previous"));
        image_prev_button.get_style_context().add_class("image_button");
        image_prev_button.clicked.connect(window.go_prev);

        image_next_button = new ActionButton("go-next-symbolic", _("Next"));
        image_next_button.get_style_context().add_class("image_button");
        image_next_button.clicked.connect(window.go_next);

        var navigation_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };
        navigation_box.pack_start(image_prev_button);
        navigation_box.pack_start(image_next_button);

        /* file buttons */
        open_button = new ActionButton("document-open", _("Open"));
        open_button.clicked.connect(() => {
            window.on_open_button_clicked();
        });

        save_button = new ActionButton("document-save-as-symbolic", _("Save as…"));
        save_button.clicked.connect(() => {
            on_save_button_clicked();
        });

        var file_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };
        file_box.pack_start(open_button);
        file_box.pack_start(save_button);

        add(navigation_box);
        add(file_box);
    }

    private void on_save_button_clicked() {
        if (window.image.is_animation) {
            Gtk.DialogFlags flags = Gtk.DialogFlags.MODAL;
            Gtk.MessageDialog alert = new Gtk.MessageDialog(window, flags, Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.OK, _("Sorry, saving animations is not supported yet."));
            alert.run();
            alert.close();
        } else {
            var dialog = new Gtk.FileChooserDialog(_("Save as…"), window, Gtk.FileChooserAction.SAVE,
                    _("Cancel"), Gtk.ResponseType.CANCEL, _("Open"), Gtk.ResponseType.ACCEPT);
            int res = dialog.run();
            if (res == Gtk.ResponseType.ACCEPT) {
                string filename = dialog.get_filename();
                window.save_file(filename);
            }
            dialog.close();
        }
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
