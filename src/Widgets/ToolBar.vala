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

namespace Tatap {
    public class ToolBar : Gtk.Bin {
        public Tatap.Window main_window { get; construct; }
        public SortOrder sort_order { get; protected set; }
        public bool sticked { get; protected set; }
        public unowned SingleImageView single_image_view { get; set; }
        public signal void sort_order_changed(SortOrder sort_order);
        public signal void stick_button_clicked(bool sticked);
        public signal void view_mode_changed(ViewMode view_mode);

        public ActionButton save_button { get; private set; }
        public ActionButton save_as_button { get; private set; }
        public ActionButton resize_button { get; private set; }
        public ActionButton zoom_fit_button { get; private set; }
        public ActionButton stick_button { get; private set; }
        public ActionButton animation_forward_button { get; private set; }
        public ActionButton animation_play_pause_button { get; private set; }
        public Gtk.ToggleButton single_view_button { get; private set; }
        public Gtk.ToggleButton scroll_view_button { get; private set; }
        public Gtk.ToggleButton dual_view_button { get; private set; }

        private Gtk.Box toolbar_hbox;
        private Gtk.Box single_view_mode_box;
        private Gtk.Box scroll_view_mode_box;
        private Gtk.Box dual_view_mode_box;
        private ViewMode _view_mode;

        public ViewMode view_mode {
            get {
                return _view_mode;
            }
            set {
                if (_view_mode != value) {
                    switch (_view_mode) {
                        case SINGLE_VIEW_MODE:
                            toolbar_hbox.remove(single_view_mode_box);
                            single_view_mode_box.hide();
                            single_view_button.active = false;
                            break;
                        case SCROLL_VIEW_MODE:
                            toolbar_hbox.remove(scroll_view_mode_box);
                            scroll_view_mode_box.hide();
                            scroll_view_button.active = false;
                            break;
                        case DUAL_VIEW_MODE:
                            toolbar_hbox.remove(dual_view_mode_box);
                            dual_view_mode_box.hide();
                            dual_view_button.active = false;
                            break;
                    }
                    _view_mode = value;
                    switch (_view_mode) {
                        case SINGLE_VIEW_MODE:
                            toolbar_hbox.pack_start(single_view_mode_box);
                            single_view_button.active = true;
                            break;
                        case SCROLL_VIEW_MODE:
                            toolbar_hbox.pack_start(scroll_view_mode_box);
                            scroll_view_button.active = true;
                            break;
                        case DUAL_VIEW_MODE:
                            toolbar_hbox.pack_start(dual_view_mode_box);
                            dual_view_button.active = true;
                            break;
                    }
                    view_mode_changed(_view_mode);
                    switch (_view_mode) {
                    case ViewMode.SINGLE_VIEW_MODE:
                        single_image_view = main_window.image_view as SingleImageView;
                        break;
                    case ViewMode.DUAL_VIEW_MODE:
                    case ViewMode.SCROLL_VIEW_MODE:
                        break;
                    }
                    toolbar_hbox.show_all();
                }
            }
        }

        public ToolBar (Tatap.Window main_window) {
            Object (
                main_window: main_window,
                sort_order: SortOrder.ASC,
                sticked: false,
                view_mode: ViewMode.SINGLE_VIEW_MODE
            );
        }

        construct {
            save_button = new ActionButton("document-save-symbolic", _("Save"), {"<Control>s"}) {
                sensitive = false
            };
            save_button.get_style_context().add_class("image_overlay_button");
            save_button.clicked.connect(() => {
                single_image_view.save_file_async.begin(false);
            });

            save_as_button = new ActionButton("document-save-as-symbolic", _("Save as…"), {"<Control><Shift>s"});
            save_as_button.get_style_context().add_class("image_overlay_button");
            save_as_button.clicked.connect(() => {
                single_image_view.save_file_async.begin(true);
            });

            var save_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
                margin = 3,
                layout_style = Gtk.ButtonBoxStyle.EXPAND
            };
            save_button_box.pack_start(save_button);
            save_button_box.pack_start(save_as_button);

            /* action buttons for the image */
            resize_button = new ActionButton("edit-find-replace-symbolic", _("Resize"), {"<control>e"});
            resize_button.get_style_context().add_class("image_overlay_button");
            resize_button.clicked.connect(() => {
                single_image_view.resize_image();
            });

            var zoom_in_button = new ActionButton("zoom-in-symbolic", _("Zoom in"), {"<control>plus"});
            zoom_in_button.get_style_context().add_class("image_overlay_button");
            zoom_in_button.clicked.connect(() => {
                single_image_view.image.zoom_in(10);
                single_image_view.update_title();
                zoom_fit_button.sensitive = true;
            });

            var zoom_out_button = new ActionButton("zoom-out-symbolic", _("Zoom out"), {"<control>minus"});
            zoom_out_button.get_style_context().add_class("image_overlay_button");
            zoom_out_button.clicked.connect(() => {
                single_image_view.image.zoom_out(10);
                single_image_view.update_title();
                zoom_fit_button.sensitive = true;
            });

            zoom_fit_button = new ActionButton("zoom-fit-best-symbolic", _("Fit to the page"), {"<control>0"});
            zoom_fit_button.get_style_context().add_class("image_overlay_button");
            zoom_fit_button.clicked.connect(() => {
                single_image_view.image.fit_size_to_window();
                single_image_view.update_title();
                zoom_fit_button.sensitive = false;
            });

            var zoom_orig_button = new ActionButton("zoom-original-symbolic", _("100%"), {"<control>1"});
            zoom_orig_button.get_style_context().add_class("image_overlay_button");
            zoom_orig_button.clicked.connect(() => {
                single_image_view.image.zoom_original();
                single_image_view.update_title();
                zoom_fit_button.sensitive = true;
            });

            var hflip_button = new ActionButton("object-flip-horizontal-symbolic", _("Flip horizontally"), {"<control>h"});
            hflip_button.get_style_context().add_class("image_overlay_button");
            hflip_button.clicked.connect(() => {
                single_image_view.image.hflip();
            });

            var vflip_button = new ActionButton("object-flip-vertical-symbolic", _("Flip vertically"), {"<control>v"});
            vflip_button.get_style_context().add_class("image_overlay_button");
            vflip_button.clicked.connect(() => {
                single_image_view.image.vflip();
            });

            var lrotate_button = new ActionButton("object-rotate-left-symbolic", _("Rotate to the left"), {"<control>l"});
            lrotate_button.get_style_context().add_class("image_overlay_button");
            lrotate_button.clicked.connect(() => {
                single_image_view.image.rotate_left();
                single_image_view.update_title();
            });

            var rrotate_button = new ActionButton("object-rotate-right-symbolic", _("Rotate to the right"), {"<control>r"});
            rrotate_button.get_style_context().add_class("image_overlay_button");
            rrotate_button.clicked.connect(() => {
                single_image_view.image.rotate_right();
                single_image_view.update_title();
            });

            var image_actions_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
                margin = 3,
                layout_style = Gtk.ButtonBoxStyle.EXPAND
            };
            image_actions_button_box.pack_start(resize_button);
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
                margin = 3,
                layout_style = Gtk.ButtonBoxStyle.EXPAND
            };
            sort_order_button_box.pack_start(sort_asc_button);
            sort_order_button_box.pack_start(sort_desc_button);

            animation_forward_button = new ActionButton("media-skip-forward-symbolic", _("Skip forward"));
            animation_forward_button.sensitive = false;
            animation_forward_button.get_style_context().add_class("image_overlay_button");
            animation_forward_button.clicked.connect(() => {
                if (single_image_view.image.paused) {
                    single_image_view.image.animate_step_once();
                }
            });

            animation_play_pause_button = new ActionButton("media-playback-start-symbolic", _("Play/Pause animation"));
            animation_play_pause_button.sensitive = false;
            animation_play_pause_button.get_style_context().add_class("image_overlay_button");
            animation_play_pause_button.clicked.connect(() => {
                if (!single_image_view.image.paused) {
                    single_image_view.image.pause();
                    animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                    animation_forward_button.sensitive = true;
                } else {
                    single_image_view.image.unpause();
                    animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                    animation_forward_button.sensitive = false;
                }
            });
            animation_play_pause_button.enter_notify_event.connect((ex) => {
                if (single_image_view.image.is_animation) {
                    if (single_image_view.image.paused) {
                        animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                    } else {
                        animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                    }
                }
            });
            animation_play_pause_button.leave_notify_event.connect((ex) => {
                if (single_image_view.image.is_animation) {
                    if (single_image_view.image.paused) {
                        animation_play_pause_button.icon_name = "media-playback-pause-symbolic";
                    } else {
                        animation_play_pause_button.icon_name = "media-playback-start-symbolic";
                    }
                }
            });

            var animation_actions_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
                margin = 3,
                layout_style = Gtk.ButtonBoxStyle.EXPAND
            };
            animation_actions_button_box.pack_start(animation_play_pause_button);
            animation_actions_button_box.pack_start(animation_forward_button);

            single_view_button = new Gtk.ToggleButton() {
                tooltip_text = _("Single View Mode"),
                image = new Gtk.Image.from_icon_name("view-paged-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                active = true
            };
            single_view_button.get_style_context().add_class("image_overlay_button");
            single_view_button.button_release_event.connect(() => {
                view_mode = ViewMode.SINGLE_VIEW_MODE;
            });

            scroll_view_button = new Gtk.ToggleButton() {
                tooltip_text = _("Scroll View Mode"),
                image = new Gtk.Image.from_icon_name("view-continuous-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                active = false
            };
            scroll_view_button.get_style_context().add_class("image_overlay_button");
            scroll_view_button.button_release_event.connect(() => {
                view_mode = ViewMode.SCROLL_VIEW_MODE;
            });

            dual_view_button = new Gtk.ToggleButton() {
                tooltip_text = _("Dual View Mode"),
                image = new Gtk.Image.from_icon_name("view-dual-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                active = false
            };
            dual_view_button.get_style_context().add_class("image_overlay_button");
            dual_view_button.button_release_event.connect(() => {
                view_mode = ViewMode.DUAL_VIEW_MODE;
            });

            var mode_switch_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
                margin = 3,
                layout_style = Gtk.ButtonBoxStyle.EXPAND
            };
            mode_switch_button_box.pack_start(single_view_button);
            mode_switch_button_box.pack_start(scroll_view_button);
            mode_switch_button_box.pack_start(dual_view_button);

            stick_button = new ActionButton("pan-down-symbolic", _("Stick"), {"<control>f"});
            stick_button.clicked.connect(() => {
                if (sticked) {
                    unstick_toolbar();
                } else {
                    stick_toolbar();
                }
            });

            var stick_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL) {
                margin = 3,
                layout_style = Gtk.ButtonBoxStyle.EXPAND
            };
            stick_button_box.pack_start(stick_button);

            single_view_mode_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                vexpand = false,
                valign = Gtk.Align.START
            };
            single_view_mode_box.pack_start(save_button_box, false, false);
            single_view_mode_box.pack_start(image_actions_button_box, false, false);
            single_view_mode_box.pack_start(sort_order_button_box, false, false);
            single_view_mode_box.pack_start(animation_actions_button_box, false, false);

            scroll_view_mode_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                vexpand = false,
                valign = Gtk.Align.START
            };

            dual_view_mode_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                vexpand = false,
                valign = Gtk.Align.START
            };

            toolbar_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                vexpand = false,
                valign = Gtk.Align.START
            };
            toolbar_hbox.pack_start(single_view_mode_box, false, false);
            toolbar_hbox.pack_end(stick_button_box, false, false);
//            toolbar_hbox.pack_end(mode_switch_button_box, false, false);
            toolbar_hbox.get_style_context().add_class("toolbar");

            add(toolbar_hbox);
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
}
