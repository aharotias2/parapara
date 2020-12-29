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
        /* action buttons for the image */
        var zoom_in_button = new ToolButton("zoom-in-symbolic", _("Zoom in"));
        zoom_in_button.get_style_context().add_class("image_overlay_button");
        zoom_in_button.clicked.connect(() => {
            window.image.zoom_in();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var zoom_out_button = new ToolButton("zoom-out-symbolic", _("Zoom out"));
        zoom_out_button.get_style_context().add_class("image_overlay_button");
        zoom_out_button.clicked.connect(() => {
            window.image.zoom_out();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        zoom_fit_button = new ToolButton("zoom-fit-best-symbolic", _("Fit to the page"));
        zoom_fit_button.get_style_context().add_class("image_overlay_button");
        zoom_fit_button.clicked.connect(() => {
            window.image.fit_image_to_window();
            window.set_title_label();
            zoom_fit_button.sensitive = false;
        });

        var zoom_orig_button = new ToolButton("zoom-original-symbolic", _("100%"));
        zoom_orig_button.get_style_context().add_class("image_overlay_button");
        zoom_orig_button.clicked.connect(() => {
            window.image.zoom_original();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var hflip_button = new ToolButton("object-flip-horizontal-symbolic", _("Flip horizontally"));
        hflip_button.get_style_context().add_class("image_overlay_button");
        hflip_button.clicked.connect(() => {
            window.image.hflip();
        });

        var vflip_button = new ToolButton("object-flip-vertical-symbolic", _("Flip vertically"));
        vflip_button.get_style_context().add_class("image_overlay_button");
        vflip_button.clicked.connect(() => {
            window.image.vflip();
        });

        var lrotate_button = new ToolButton("object-rotate-left-symbolic", _("Rotate to the left"));
        lrotate_button.get_style_context().add_class("image_overlay_button");
        lrotate_button.clicked.connect(() => {
            window.image.rotate_left();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var rrotate_button = new ToolButton("object-rotate-right-symbolic", _("Rotate to the right"));
        rrotate_button.get_style_context().add_class("image_overlay_button");
        rrotate_button.clicked.connect(() => {
            window.image.rotate_right();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var image_actions_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            margin = 5,
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };
        image_actions_button_box.pack_start(zoom_in_button);
        image_actions_button_box.pack_start(zoom_out_button);
        image_actions_button_box.pack_start(zoom_fit_button);
        image_actions_button_box.pack_start(zoom_orig_button);
        image_actions_button_box.pack_start(hflip_button);
        image_actions_button_box.pack_start(vflip_button);
        image_actions_button_box.pack_start(lrotate_button);
        image_actions_button_box.pack_start(rrotate_button);

        var toolbar_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
            vexpand = false,
            valign = Gtk.Align.START
        };
        toolbar_hbox.add(image_actions_button_box);
        toolbar_hbox.get_style_context().add_class("toolbar");

        add(toolbar_hbox);
    }
}
