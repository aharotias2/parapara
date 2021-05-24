/*
 *  Copyright 2019-2021 Tanaka Takayuki (田中喬之)
 *
 *  This file is part of ParaPara.
 *
 *  ParaPara is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  ParaPara is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with ParaPara.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Tanaka Takayuki <aharotias2@gmail.com>
 */

using Gtk;

namespace ParaPara {
    public class ToolBar : Bin {
        public ParaPara.Window main_window { get; construct; }
        public SortOrder sort_order { get; protected set; }
        public bool sticked { get; protected set; }
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
        public ToggleButton single_view_button { get; private set; }
        public ToggleButton slide_view_button { get; private set; }
        public ToggleButton dual_view_button { get; private set; }
        public Button l2button { get; private set; }
        public Button l1button { get; private set; }
        public Button r1button { get; private set; }
        public Button r2button { get; private set; }
        public ToggleButton sort_asc_button { get; private set; }
        public ToggleButton sort_desc_button { get; private set; }
        public ToggleButton l2rbutton { get; private set; }
        public ToggleButton r2lbutton { get; private set; }
        public ToggleButton orientation_vertical_button { get; private set; }
        public ToggleButton orientation_horizontal_button { get; private set; }
        public ActionButton fullscreen_button { get; private set; }
        private Box toolbar_hbox;
        private Box single_view_mode_box;
        private Box slide_view_mode_box;
        private Box dual_view_mode_box;
        private ButtonBox mode_switch_button_box;
        private ViewMode _view_mode;

        private SingleImageView? single_image_view {
            get {
                return main_window.image_view as SingleImageView;
            }
        }

        private DualImageView? dual_image_view {
            get {
                return main_window.image_view as DualImageView;
            }
        }

        private SlideImageView? slide_image_view {
            get {
                return main_window.image_view as SlideImageView;
            }
        }

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
                        single_view_button.sensitive = true;
                        break;
                      case SLIDE_VIEW_MODE:
                        toolbar_hbox.remove(slide_view_mode_box);
                        slide_view_mode_box.hide();
                        slide_view_button.active = false;
                        slide_view_button.sensitive = true;
                        break;
                      case DUAL_VIEW_MODE:
                        toolbar_hbox.remove(dual_view_mode_box);
                        dual_view_mode_box.hide();
                        dual_view_button.active = false;
                        dual_view_button.sensitive = true;
                        break;
                    }
                    _view_mode = value;
                    switch (_view_mode) {
                      case SINGLE_VIEW_MODE:
                        toolbar_hbox.pack_start(single_view_mode_box, false, false);
                        toolbar_hbox.reorder_child(single_view_mode_box, 0);
                        single_view_button.active = true;
                        single_view_button.sensitive = false;
                        if (sort_order == SortOrder.ASC && !sort_asc_button.active) {
                            sort_asc_button.active = true;
                        }
                        if (sort_order == SortOrder.DESC && !sort_desc_button.active) {
                            sort_desc_button.active = true;
                        }
                        break;
                      case SLIDE_VIEW_MODE:
                        toolbar_hbox.pack_start(slide_view_mode_box, false, false);
                        toolbar_hbox.reorder_child(slide_view_mode_box, 0);
                        slide_view_button.active = true;
                        slide_view_button.sensitive = false;
                        break;
                      case DUAL_VIEW_MODE:
                        toolbar_hbox.pack_start(dual_view_mode_box, false, false);
                        toolbar_hbox.reorder_child(dual_view_mode_box, 0);
                        dual_view_button.active = true;
                        dual_view_button.sensitive = false;
                        if (sort_order == SortOrder.ASC && !l2rbutton.active) {
                            l2rbutton.active = true;
                        }
                        if (sort_order == SortOrder.DESC && !r2lbutton.active) {
                            r2lbutton.active = true;
                        }
                        break;
                    }
                    view_mode_changed(_view_mode);
                    toolbar_hbox.show_all();
                }
            }
        }

        public ToolBar (ParaPara.Window main_window) {
            Object (
                main_window: main_window,
                sort_order: SortOrder.ASC,
                sticked: false,
                view_mode: ViewMode.SINGLE_VIEW_MODE
            );
        }

        construct {
            toolbar_hbox = new Box(Orientation.HORIZONTAL, 0) {
                vexpand = false,
                valign = Align.START
            };
            {
                single_view_mode_box = new Box(Orientation.HORIZONTAL, 0) {
                    vexpand = false,
                    valign = Align.START
                };
                {
                    var save_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                        margin = 3,
                        layout_style = ButtonBoxStyle.EXPAND
                    };
                    {
                        save_button = new ActionButton("document-save-symbolic", _("Save"), {"<Control>s"}) {
                            sensitive = false
                        };
                        {
                            save_button.get_style_context().add_class("image_overlay_button");
                            save_button.clicked.connect(() => {
                                single_image_view.save_file_async.begin(false);
                            });
                        }

                        save_as_button = new ActionButton("document-save-as-symbolic", _("Save as…"), {"<Control><Shift>s"});
                        {
                            save_as_button.get_style_context().add_class("image_overlay_button");
                            save_as_button.clicked.connect(() => {
                                single_image_view.save_file_async.begin(true);
                            });
                        }

                        save_button_box.pack_start(save_button);
                        save_button_box.pack_start(save_as_button);
                    }

                    var image_actions_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                        margin = 3,
                        layout_style = ButtonBoxStyle.EXPAND
                    };
                    {
                        resize_button = new ActionButton("edit-find-replace-symbolic", _("Resize"), {"<control>e"});
                        {
                            resize_button.get_style_context().add_class("image_overlay_button");
                            resize_button.clicked.connect(() => {
                                single_image_view.resize_image();
                            });
                        }

                        var zoom_in_button = new ActionButton("zoom-in-symbolic", _("Zoom in"), {"<control>plus"});
                        {
                            zoom_in_button.get_style_context().add_class("image_overlay_button");
                            zoom_in_button.clicked.connect(() => {
                                single_image_view.image.zoom_in(10);
                                single_image_view.update_title();
                                zoom_fit_button.sensitive = true;
                            });
                        }

                        var zoom_out_button = new ActionButton("zoom-out-symbolic", _("Zoom out"), {"<control>minus"});
                        {
                            zoom_out_button.get_style_context().add_class("image_overlay_button");
                            zoom_out_button.clicked.connect(() => {
                                single_image_view.image.zoom_out(10);
                                single_image_view.update_title();
                                zoom_fit_button.sensitive = true;
                            });
                        }

                        zoom_fit_button = new ActionButton("zoom-fit-best-symbolic", _("Fit to the page"), {"<control>0"});
                        {
                            zoom_fit_button.get_style_context().add_class("image_overlay_button");
                            zoom_fit_button.clicked.connect(() => {
                                single_image_view.image.fit_size_in_window();
                                single_image_view.update_title();
                                zoom_fit_button.sensitive = false;
                            });
                        }

                        var zoom_orig_button = new ActionButton("zoom-original-symbolic", _("100%"), {"<control>1"});
                        {
                            zoom_orig_button.get_style_context().add_class("image_overlay_button");
                            zoom_orig_button.clicked.connect(() => {
                                single_image_view.image.zoom_original();
                                single_image_view.update_title();
                                zoom_fit_button.sensitive = true;
                            });
                        }

                        var hflip_button = new ActionButton("object-flip-horizontal-symbolic", _("Flip horizontally"), {"<control>h"});
                        {
                            hflip_button.get_style_context().add_class("image_overlay_button");
                            hflip_button.clicked.connect(() => {
                                single_image_view.image.hflip();
                            });
                        }

                        var vflip_button = new ActionButton("object-flip-vertical-symbolic", _("Flip vertically"), {"<control>v"});
                        {
                            vflip_button.get_style_context().add_class("image_overlay_button");
                            vflip_button.clicked.connect(() => {
                                single_image_view.image.vflip();
                            });
                        }

                        var lrotate_button = new ActionButton("object-rotate-left-symbolic", _("Rotate to the left"), {"<control>l"});
                        {
                            lrotate_button.get_style_context().add_class("image_overlay_button");
                            lrotate_button.clicked.connect(() => {
                                single_image_view.image.rotate_left();
                                single_image_view.update_title();
                            });
                        }

                        var rrotate_button = new ActionButton("object-rotate-right-symbolic", _("Rotate to the right"), {"<control>r"});
                        {
                            rrotate_button.get_style_context().add_class("image_overlay_button");
                            rrotate_button.clicked.connect(() => {
                                single_image_view.image.rotate_right();
                                single_image_view.update_title();
                            });
                        }

                        image_actions_button_box.pack_start(resize_button);
                        image_actions_button_box.pack_start(zoom_in_button);
                        image_actions_button_box.pack_start(zoom_out_button);
                        image_actions_button_box.pack_start(zoom_fit_button);
                        image_actions_button_box.pack_start(zoom_orig_button);
                        image_actions_button_box.pack_start(hflip_button);
                        image_actions_button_box.pack_start(vflip_button);
                        image_actions_button_box.pack_start(lrotate_button);
                        image_actions_button_box.pack_start(rrotate_button);
                    }

                    var sort_order_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                        margin = 3,
                        layout_style = ButtonBoxStyle.EXPAND
                    };
                    {
                        sort_asc_button = new ToggleButton() {
                            tooltip_text = _("Sort Asc"),
                            image = new Gtk.Image.from_icon_name("view-sort-ascending-symbolic", IconSize.SMALL_TOOLBAR),
                            active = true,
                            sensitive = false
                        };
                        {
                            sort_asc_button.get_style_context().add_class("image_overlay_button");
                            sort_asc_button.toggled.connect(() => {
                                if (sort_asc_button.active) {
                                    sort_asc_button.sensitive = false;
                                    sort_desc_button.active = false;
                                    sort_desc_button.sensitive = true;
                                    sort_order = SortOrder.ASC;
                                    sort_order_changed(sort_order);
                                }
                            });
                        }

                        sort_desc_button = new ToggleButton() {
                            tooltip_text = _("Sort Desc"),
                            image = new Gtk.Image.from_icon_name("view-sort-descending-symbolic", IconSize.SMALL_TOOLBAR),
                            active = false
                        };
                        {
                            sort_desc_button.get_style_context().add_class("image_overlay_button");
                            sort_desc_button.toggled.connect(() => {
                                if (sort_desc_button.active) {
                                    sort_desc_button.sensitive = false;
                                    sort_asc_button.active = false;
                                    sort_asc_button.sensitive = true;
                                    sort_order = SortOrder.DESC;
                                    sort_order_changed(sort_order);
                                }
                            });
                        }

                        sort_order_button_box.pack_start(sort_asc_button);
                        sort_order_button_box.pack_start(sort_desc_button);
                    }

                    var animation_actions_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                        margin = 3,
                        layout_style = ButtonBoxStyle.EXPAND
                    };
                    {
                        animation_forward_button = new ActionButton("media-skip-forward-symbolic", _("Skip forward"));
                        {
                            animation_forward_button.sensitive = false;
                            animation_forward_button.get_style_context().add_class("image_overlay_button");
                            animation_forward_button.clicked.connect(() => {
                                if (single_image_view.image.paused) {
                                    single_image_view.image.animate_step_once();
                                }
                            });
                        }

                        animation_play_pause_button = new ActionButton("media-playback-start-symbolic", _("Play/Pause animation")) {
                            sensitive = false
                        };
                        {
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
                        }

                        animation_actions_button_box.pack_start(animation_play_pause_button);
                        animation_actions_button_box.pack_start(animation_forward_button);
                    }

                    single_view_mode_box.pack_start(save_button_box, false, false);
                    single_view_mode_box.pack_start(sort_order_button_box, false, false);
                    single_view_mode_box.pack_start(image_actions_button_box, false, false);
                    single_view_mode_box.pack_start(animation_actions_button_box, false, false);
                }

                dual_view_mode_box = new Box(Orientation.HORIZONTAL, 0) {
                    vexpand = false,
                    valign = Align.START
                };
                {
                    var dual_paging_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                        margin = 3,
                        layout_style = ButtonBoxStyle.EXPAND
                    };
                    {
                        l2button = new ActionButton("move-two-page-left-symbolic", _("Slide 2 page to Left"), null);
                        {
                            l2button.clicked.connect(() => {
                                if (sort_order == SortOrder.ASC) {
                                    dual_image_view.go_backward_async.begin(2);
                                } else {
                                    dual_image_view.go_forward_async.begin(2);
                                }
                            });
                        }

                        l1button = new ActionButton("move-one-page-left-symbolic", _("Slide 1 page to Left"), null);
                        {
                            l1button.clicked.connect(() => {
                                if (sort_order == SortOrder.ASC) {
                                    dual_image_view.go_backward_async.begin(1);
                                } else {
                                    dual_image_view.go_forward_async.begin(1);
                                }
                            });
                        }

                        r1button = new ActionButton("move-one-page-right-symbolic", _("Slide 1 page to Right"), null);
                        {
                            r1button.clicked.connect(() => {
                                if (sort_order == SortOrder.ASC) {
                                    dual_image_view.go_forward_async.begin(1);
                                } else {
                                    dual_image_view.go_backward_async.begin(1);
                                }
                            });
                        }

                        r2button = new ActionButton("move-two-page-right-symbolic", _("Slide 2 page to Right"), null);
                        {
                            r2button.clicked.connect(() => {
                                if (sort_order == SortOrder.ASC) {
                                    dual_image_view.go_forward_async.begin(2);
                                } else {
                                    dual_image_view.go_backward_async.begin(2);
                                }
                            });
                        }

                        dual_paging_button_box.pack_start(l2button);
                        dual_paging_button_box.pack_start(l1button);
                        dual_paging_button_box.pack_start(r1button);
                        dual_paging_button_box.pack_start(r2button);
                    }

                    var dual_sort_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                        margin = 3,
                        layout_style = ButtonBoxStyle.EXPAND
                    };
                    {
                        l2rbutton = new ToggleButton() {
                            tooltip_text = _("Left to Right"),
                            image = new Gtk.Image.from_icon_name("read-left-to-right-symbolic", SMALL_TOOLBAR),
                            active = true,
                            sensitive = false
                        };
                        {
                            l2rbutton.get_style_context().add_class("image_overlay_button");
                            l2rbutton.toggled.connect(() => {
                                if (l2rbutton.active) {
                                    l2rbutton.sensitive = false;
                                    r2lbutton.active = false;
                                    r2lbutton.sensitive = true;
                                    sort_order = SortOrder.ASC;
                                    sort_order_changed(sort_order);
                                }
                            });
                        }

                        r2lbutton = new ToggleButton() {
                            tooltip_text = _("Right to Left"),
                            image = new Gtk.Image.from_icon_name("read-right-to-left-symbolic", SMALL_TOOLBAR),
                            active = false
                        };
                        {
                            r2lbutton.get_style_context().add_class("image_overlay_button");
                            r2lbutton.toggled.connect(() => {
                                print("r2lbutton toggled %s\n", r2lbutton.active ? "active" : "inactive");
                                if (r2lbutton.active) {
                                    r2lbutton.sensitive = false;
                                    l2rbutton.active = false;
                                    l2rbutton.sensitive = true;
                                    sort_order = SortOrder.DESC;
                                    sort_order_changed(sort_order);
                                }
                            });
                        }

                        dual_sort_button_box.pack_start(r2lbutton);
                        dual_sort_button_box.pack_start(l2rbutton);
                    }

                    dual_view_mode_box.pack_start(dual_paging_button_box, false, false);
                    dual_view_mode_box.pack_start(dual_sort_button_box, false, false);
                }

                slide_view_mode_box = new Box(Orientation.HORIZONTAL, 0) {
                    vexpand = false,
                    valign = Align.START
                };
                {
                    var size_combo = new ComboBoxText() {
                        margin = 3
                    };
                    {
                        size_combo.append("fit-width", _("Fit Width"));
                        size_combo.append("fit-page", _("Fit Page"));
                        size_combo.append("separtator-1", "separator");
                        size_combo.append("scale-25", _("25%"));
                        size_combo.append("scale-50", _("50%"));
                        size_combo.append("scale-70", _("70%"));
                        size_combo.append("scale-80", _("80%"));
                        size_combo.append("scale-100", _("100%"));
                        size_combo.append("scale-200", _("200%"));
                        size_combo.append("scale-400", _("400%"));
                        size_combo.active_id = "fit-width";
                        size_combo.set_row_separator_func((model, iter) => {
                            Value id;
                            model.get_value(iter, 0, out id);
                            return id.get_string().has_prefix("separator");
                        });
                        size_combo.changed.connect(() => {
                            string id = size_combo.active_id;
                            if (id == "fit-width") {
                                slide_image_view.fit_width();
                            } else if (id == "fit-page") {
                                slide_image_view.fit_page();
                            } else if (id.has_prefix("scale-")) {
                                uint scale_percentage = uint.parse(id.substring(6));
                                slide_image_view.scale_by_percentage(scale_percentage);
                            }
                        });
                    }

                    var orientation_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                        margin = 3,
                        layout_style = ButtonBoxStyle.EXPAND
                    };
                    {
                        orientation_vertical_button = new ToggleButton() {
                            tooltip_text = _("Vertical"),
                            image = new Gtk.Image.from_icon_name("orientation-vertical-symbolic", SMALL_TOOLBAR),
                            active = true,
                            sensitive = false
                        };
                        {
                            orientation_vertical_button.get_style_context().add_class("image_overlay_button");
                            orientation_vertical_button.toggled.connect(() => {
                                if (orientation_vertical_button.active) {
                                    slide_image_view.orientation = VERTICAL;
                                    orientation_vertical_button.sensitive = false;
                                    orientation_horizontal_button.active = false;
                                    orientation_horizontal_button.sensitive = true;
                                }
                            });
                        }

                        orientation_horizontal_button = new ToggleButton() {
                            tooltip_text = _("Vertical"),
                            image = new Gtk.Image.from_icon_name("orientation-horizontal-symbolic", SMALL_TOOLBAR),
                            active = false,
                            sensitive = true
                        };
                        {
                            orientation_horizontal_button.get_style_context().add_class("image_overlay_button");
                            orientation_horizontal_button.toggled.connect(() => {
                                if (orientation_horizontal_button.active) {
                                    slide_image_view.orientation = HORIZONTAL;
                                    orientation_horizontal_button.sensitive = false;
                                    orientation_vertical_button.active = false;
                                    orientation_vertical_button.sensitive = true;
                                }
                            });
                        }

                        orientation_button_box.pack_start(orientation_vertical_button);
                        orientation_button_box.pack_start(orientation_horizontal_button);
                    }

                    slide_view_mode_box.pack_start(size_combo);
                    slide_view_mode_box.pack_start(new Label(_("Orientation : ")));
                    slide_view_mode_box.pack_start(orientation_button_box);
                }

                var fullscreen_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                    margin = 3,
                    layout_style = ButtonBoxStyle.EXPAND
                };
                {
                    fullscreen_button = new ActionButton("view-fullscreen-symbolic", _("Fullscreen"), {"f11"});
                    {
                        fullscreen_button.clicked.connect(() => {
                            main_window.fullscreen_mode = !main_window.fullscreen_mode;
                        });
                    }
                    fullscreen_button_box.pack_start(fullscreen_button);
                }

                mode_switch_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                    margin = 3,
                    layout_style = ButtonBoxStyle.EXPAND
                };
                {
                    single_view_button = new ToggleButton() {
                        tooltip_text = _("Single View Mode"),
                        image = new Gtk.Image.from_icon_name("view-paged-symbolic", IconSize.SMALL_TOOLBAR),
                        active = true,
                        sensitive = false
                    };
                    {
                        single_view_button.get_style_context().add_class("image_overlay_button");
                        single_view_button.toggled.connect(() => {
                            view_mode = ViewMode.SINGLE_VIEW_MODE;
                        });
                    }

                    slide_view_button = new ToggleButton() {
                        tooltip_text = _("Scroll View Mode"),
                        image = new Gtk.Image.from_icon_name("view-continuous-symbolic", IconSize.SMALL_TOOLBAR),
                        active = false
                    };
                    {
                        slide_view_button.get_style_context().add_class("image_overlay_button");
                        slide_view_button.toggled.connect(() => {
                            view_mode = ViewMode.SLIDE_VIEW_MODE;
                        });
                    }

                    dual_view_button = new ToggleButton() {
                        tooltip_text = _("Dual View Mode"),
                        image = new Gtk.Image.from_icon_name("view-dual-symbolic", IconSize.SMALL_TOOLBAR),
                        active = false
                    };
                    {
                        dual_view_button.get_style_context().add_class("image_overlay_button");
                        dual_view_button.toggled.connect(() => {
                            view_mode = ViewMode.DUAL_VIEW_MODE;
                        });
                    }

                    mode_switch_button_box.pack_start(single_view_button);
                    mode_switch_button_box.pack_start(slide_view_button);
                    mode_switch_button_box.pack_start(dual_view_button);
                }

                var stick_button_box = new ButtonBox(Orientation.HORIZONTAL) {
                    margin = 3,
                    layout_style = ButtonBoxStyle.EXPAND
                };
                {
                    stick_button = new ActionButton("pan-down-symbolic", _("Stick"), {"<control>f"});
                    {
                        stick_button.clicked.connect(() => {
                            if (sticked) {
                                unstick_toolbar();
                            } else {
                                stick_toolbar();
                            }
                        });
                    }

                    stick_button_box.pack_start(stick_button);
                }

                toolbar_hbox.pack_start(single_view_mode_box, false, false);
                toolbar_hbox.pack_end(stick_button_box, false, false);
                toolbar_hbox.pack_end(mode_switch_button_box, false, false);
                toolbar_hbox.pack_end(fullscreen_button_box, false, false);
                toolbar_hbox.get_style_context().add_class("toolbar");
            }
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
