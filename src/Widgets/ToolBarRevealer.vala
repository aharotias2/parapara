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
 *  Tanaka Takayuki <msg@gorigorilinux.net>
 */

public class ToolBarRevealer : Gtk.Revealer {
    public TatapWindow window { get; construct; }

    private Gtk.Button zoom_fit_button;

    public ToolBarRevealer (TatapWindow window) {
        Object (
            window: window,
            transition_type: Gtk.RevealerTransitionType.SLIDE_DOWN
        );
    }

    construct {
        /* action buttons for file */
        var open_button = new Gtk.Button.from_icon_name("document-open-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Open")
        };
        open_button.clicked.connect(() => {
            on_open_button_clicked();
        });

        var save_button = new Gtk.Button.from_icon_name("document-save-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Save as…")
        };
        save_button.clicked.connect(() => {
            on_save_button_clicked();
        });

        var file_action_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            margin = 5
        };
        file_action_button_box.add(open_button);
        file_action_button_box.add(save_button);
        file_action_button_box.set_layout(Gtk.ButtonBoxStyle.EXPAND);

        /* action buttons for the image */
        var zoom_in_button = new Gtk.Button.from_icon_name("zoom-in-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Zoom in")
        };
        zoom_in_button.get_style_context().add_class("image_overlay_button");
        zoom_in_button.clicked.connect(() => {
            window.image.zoom_in();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var zoom_out_button = new Gtk.Button.from_icon_name("zoom-out-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Zoom out")
        };
        zoom_out_button.get_style_context().add_class("image_overlay_button");
        zoom_out_button.clicked.connect(() => {
            window.image.zoom_out();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        zoom_fit_button = new Gtk.Button.from_icon_name("zoom-fit-best-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Fit to the page")
        };
        zoom_fit_button.get_style_context().add_class("image_overlay_button");
        zoom_fit_button.clicked.connect(() => {
            window.image.fit_image_to_window();
            window.set_title_label();
            zoom_fit_button.sensitive = false;
        });

        var zoom_orig_button = new Gtk.Button.from_icon_name("zoom-original-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("100%")
        };
        zoom_orig_button.get_style_context().add_class("image_overlay_button");
        zoom_orig_button.clicked.connect(() => {
            window.image.zoom_original();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var hflip_button = new Gtk.Button.from_icon_name("object-flip-horizontal-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Flip horizontally")
        };
        hflip_button.get_style_context().add_class("image_overlay_button");
        hflip_button.clicked.connect(() => {
            window.image.hflip();
        });

        var vflip_button = new Gtk.Button.from_icon_name("object-flip-vertical-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Flip vertically")
        };
        vflip_button.get_style_context().add_class("image_overlay_button");
        vflip_button.clicked.connect(() => {
            window.image.vflip();
        });

        var lrotate_button = new Gtk.Button.from_icon_name("object-rotate-left-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Rotate to the left")
        };
        lrotate_button.get_style_context().add_class("image_overlay_button");
        lrotate_button.clicked.connect(() => {
            window.image.rotate_left();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var rrotate_button = new Gtk.Button.from_icon_name("object-rotate-right-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Rotate to the right")
        };
        rrotate_button.get_style_context().add_class("image_overlay_button");
        rrotate_button.clicked.connect(() => {
            window.image.rotate_right();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var image_actions_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            margin = 5
        };
        image_actions_button_box.pack_start(zoom_in_button);
        image_actions_button_box.pack_start(zoom_out_button);
        image_actions_button_box.pack_start(zoom_fit_button);
        image_actions_button_box.pack_start(zoom_orig_button);
        image_actions_button_box.pack_start(hflip_button);
        image_actions_button_box.pack_start(vflip_button);
        image_actions_button_box.pack_start(lrotate_button);
        image_actions_button_box.pack_start(rrotate_button);
        image_actions_button_box.set_layout(Gtk.ButtonBoxStyle.EXPAND);

        var toolbar_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
            vexpand = false,
            valign = Gtk.Align.START
        };
        toolbar_hbox.pack_start(file_action_button_box, false, false);
        toolbar_hbox.pack_start(image_actions_button_box, false, false);
        toolbar_hbox.get_style_context().add_class("toolbar");

        add(toolbar_hbox);
    }

    private void on_open_button_clicked() {
        var dialog = new Gtk.FileChooserDialog(_("Choose file to open"), window, Gtk.FileChooserAction.OPEN,
                                           _("Cancel"), Gtk.ResponseType.CANCEL,
                                           _("Open"), Gtk.ResponseType.ACCEPT);
        int res = dialog.run();
        if (res == Gtk.ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            window.open_file(filename);
        }
        dialog.close();
    }

    private void on_save_button_clicked() {
        var dialog = new Gtk.FileChooserDialog(_("Save as…"), window, Gtk.FileChooserAction.SAVE,
                                           _("Cancel"), Gtk.ResponseType.CANCEL,
                                           _("Open"), Gtk.ResponseType.ACCEPT);
        int res = dialog.run();
        if (res == Gtk.ResponseType.ACCEPT) {
            string filename = dialog.get_filename();
            window.save_file(filename);
        }
        dialog.close();
    }
}
