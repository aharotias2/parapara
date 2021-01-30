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

public class TatapToolBar : Gtk.Bin {
    public TatapWindow window { get; construct; }
    public SortOrder sort_order { get; protected set; }
    public bool sticked { get; protected set; }
    public signal void sort_order_changed(SortOrder sort_order);
    public signal void stick_button_clicked(bool sticked);

    private Gtk.Button zoom_fit_button;
    private ActionButton stick_button;
    public ActionButton animation_forward_button { get; private set; }
    public ActionButton animation_play_pause_button { get; private set; }

    public TatapToolBar (TatapWindow window) {
        Object (
            window: window,
            sort_order: SortOrder.ASC,
            sticked: false
        );
    }

    construct {
        /* action buttons for the image */
        var zoom_in_button = new ActionButton(
                "zoom-in-symbolic", _("Zoom in"), {"<control>plus"});
        zoom_in_button.get_style_context().add_class("image_overlay_button");
        zoom_in_button.clicked.connect(() => {
            window.image.zoom_in(10);
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var zoom_out_button = new ActionButton(
                "zoom-out-symbolic", _("Zoom out"), {"<control>minus"});
        zoom_out_button.get_style_context().add_class("image_overlay_button");
        zoom_out_button.clicked.connect(() => {
            window.image.zoom_out(10);
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        zoom_fit_button = new ActionButton(
                "zoom-fit-best-symbolic", _("Fit to the page"), {"<control>0"});
        zoom_fit_button.get_style_context().add_class("image_overlay_button");
        zoom_fit_button.clicked.connect(() => {
            window.image.fit_image_to_window();
            window.set_title_label();
            zoom_fit_button.sensitive = false;
        });

        var zoom_orig_button = new ActionButton(
                "zoom-original-symbolic", _("100%"), {"<control>1"});
        zoom_orig_button.get_style_context().add_class("image_overlay_button");
        zoom_orig_button.clicked.connect(() => {
            window.image.zoom_original();
            window.set_title_label();
            zoom_fit_button.sensitive = true;
        });

        var hflip_button = new ActionButton(
                "object-flip-horizontal-symbolic", _("Flip horizontally"), {"<control>h"});
        hflip_button.get_style_context().add_class("image_overlay_button");
        hflip_button.clicked.connect(() => {
            window.image.hflip();
        });

        var vflip_button = new ActionButton(
                "object-flip-vertical-symbolic", _("Flip vertically"), {"<control>v"});
        vflip_button.get_style_context().add_class("image_overlay_button");
        vflip_button.clicked.connect(() => {
            window.image.vflip();
        });

        var lrotate_button = new ActionButton(
                "object-rotate-left-symbolic", _("Rotate to the left"), {"<control>l"});
        lrotate_button.get_style_context().add_class("image_overlay_button");
        lrotate_button.clicked.connect(() => {
            window.image.rotate_left();
            window.set_title_label();
        });

        var rrotate_button = new ActionButton(
                "object-rotate-right-symbolic", _("Rotate to the right"), {"<control>r"});
        rrotate_button.get_style_context().add_class("image_overlay_button");
        rrotate_button.clicked.connect(() => {
            window.image.rotate_right();
            window.set_title_label();
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

        Gtk.ToggleButton sort_desc_button;

        var sort_asc_button = new Gtk.ToggleButton() {
            tooltip_text = _("Sort Asc"),
            image = new Gtk.Image.from_icon_name("view-sort-ascending-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            active = true
        };
        sort_asc_button.get_style_context().add_class("image_overlay_button");
        sort_asc_button.toggled.connect(() => {
            if (sort_asc_button.active) {
                sort_order = SortOrder.ASC;
                sort_desc_button.active = false;
                sort_order_changed(sort_order);
            }
        });

        sort_desc_button = new Gtk.ToggleButton() {
            tooltip_text = _("Sort Desc"),
            image = new Gtk.Image.from_icon_name("view-sort-descending-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            active = false
        };
        sort_desc_button.get_style_context().add_class("image_overlay_button");
        sort_desc_button.toggled.connect(() => {
            if (sort_desc_button.active) {
                sort_order = SortOrder.DESC;
                sort_asc_button.active = false;
                sort_order_changed(sort_order);
            }
        });

        var sort_order_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            margin = 5,
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };
        sort_order_button_box.pack_start(sort_asc_button);
        sort_order_button_box.pack_start(sort_desc_button);

        animation_forward_button = new ActionButton("media-skip-forward-symbolic", _("Skip forward"));
        animation_forward_button.sensitive = false;
        animation_forward_button.get_style_context().add_class("image_overlay_button");
        animation_forward_button.clicked.connect(() => {
            if (window.image.paused) {
                window.image.animate_step_once();
            }
        });

        animation_play_pause_button = new ActionButton("media-playback-start-symbolic", _("Play animation"));
        animation_play_pause_button.sensitive = false;
        animation_play_pause_button.get_style_context().add_class("image_overlay_button");
        animation_play_pause_button.clicked.connect(() => {
            if (!window.image.paused) {
                window.image.pause();
                animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                animation_forward_button.sensitive = true;
            } else {
                window.image.unpause();
                animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                animation_forward_button.sensitive = false;
            }
        });
        animation_play_pause_button.enter_notify_event.connect((ex) => {
            if (window.image.is_animation) {
                if (window.image.paused) {
                    animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                } else {
                    animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                }
            }
        });
        animation_play_pause_button.leave_notify_event.connect((ex) => {
            if (window.image.is_animation) {
                if (window.image.paused) {
                    animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                } else {
                    animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                }
            }
        });

        var animation_actions_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
            margin = 5,
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };
        animation_actions_button_box.pack_start(animation_play_pause_button);
        animation_actions_button_box.pack_start(animation_forward_button);

        stick_button = new ActionButton("pan-down-symbolic", _("Stick"), {"<control>f"}) {
            margin = 5
        };
        stick_button.clicked.connect(() => {
            if (sticked) {
                unstick_toolbar();
            } else {
                stick_toolbar();
            }
        });

        var toolbar_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
            vexpand = false,
            valign = Gtk.Align.START
        };
        toolbar_hbox.pack_start(image_actions_button_box, false, false);
        toolbar_hbox.pack_start(sort_order_button_box, false, false);
        toolbar_hbox.pack_end(stick_button, false, false);
        toolbar_hbox.pack_end(animation_actions_button_box, false, false);
        toolbar_hbox.get_style_context().add_class("toolbar");

        add(toolbar_hbox);
    }

    public void set_zoom_fit_button_sensitivity(bool is_sensitive) {
        zoom_fit_button.sensitive = is_sensitive;
    }

    public void stick_toolbar() {
        stick_button.icon_name = "pan-up-symbolic";
        sticked = true;
        stick_button_clicked(true);
    }

    public void unstick_toolbar() {
        stick_button.icon_name = "pan-down-symbolic";
        sticked = false;
        stick_button_clicked(false);
    }
}
