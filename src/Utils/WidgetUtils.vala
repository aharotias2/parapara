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

[Compact]
namespace ParaPara {
    public class WidgetUtils {
        public static void calc_event_position_percent(Gdk.Event event, Gtk.Widget widget, out int x_percent, out int y_percent) {
            double x, y;

            get_event_position(event, out x, out y, false);

            Gtk.Allocation allocation;
            widget.get_allocation(out allocation);

            double a = x - allocation.x;
            double b = a / (double) allocation.width * 100.0;
            x_percent = (int) b;

            double c = y - allocation.y;
            double d = c / (double) allocation.height * 100.0;
            y_percent = (int) d;
        }

        public static bool is_event_in_widget(Gdk.Event event, Gtk.Widget widget) {
            int widget_root_x, widget_root_y;
            widget.get_window().get_root_coords(0, 0, out widget_root_x, out widget_root_y);
            Gtk.Allocation allocation;
            widget.get_allocation(out allocation);
            double event_x_root, event_y_root;
            get_event_position(event, out event_x_root, out event_y_root, true);
            return (widget_root_x <= (int) event_x_root)
                    && ((int) event_x_root < widget_root_x + allocation.width)
                    && (widget_root_y <= (int) event_y_root)
                    && ((int) event_y_root <= widget_root_y + allocation.height);
        }

        private static void get_event_position(Gdk.Event event, out double x, out double y, bool is_from_root) {
            double tmp_x, tmp_y, tmp_x_root, tmp_y_root;
            switch (event.type) {
              case BUTTON_PRESS: case 2BUTTON_PRESS: case 3BUTTON_PRESS: case BUTTON_RELEASE:
                tmp_x_root = event.button.x_root;
                tmp_y_root = event.button.y_root;
                tmp_x = event.button.x;
                tmp_y = event.button.y;
                break;
              case TOUCHPAD_PINCH:
                tmp_x_root = event.touchpad_pinch.x_root;
                tmp_y_root = event.touchpad_pinch.y_root;
                tmp_x = event.touchpad_pinch.x;
                tmp_y = event.touchpad_pinch.y;
                break;
              case TOUCHPAD_SWIPE:
                tmp_x_root = event.touchpad_swipe.x_root;
                tmp_y_root = event.touchpad_swipe.y_root;
                tmp_x = event.touchpad_swipe.x;
                tmp_y = event.touchpad_swipe.y;
                break;
              case SCROLL:
                tmp_x_root = event.scroll.x_root;
                tmp_y_root = event.scroll.y_root;
                tmp_x = event.scroll.x;
                tmp_y = event.scroll.y;
                break;
              case MOTION_NOTIFY:
                tmp_x_root = event.motion.x_root;
                tmp_y_root = event.motion.y_root;
                tmp_x = event.motion.x;
                tmp_y = event.motion.y;
                break;
              case ENTER_NOTIFY: case LEAVE_NOTIFY:
                tmp_x_root = event.crossing.x_root;
                tmp_y_root = event.crossing.y_root;
                tmp_x = event.crossing.x;
                tmp_y = event.crossing.y;
                break;
              default:
                x = 0;
                y = 0;
                return;
            }
            if (is_from_root) {
                x = tmp_x_root;
                y = tmp_y_root;
            } else {
                x = tmp_x;
                y = tmp_y;
            }
        }
    }
}
