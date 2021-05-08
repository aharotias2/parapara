[Compact]
namespace Tatap {
    public class WidgetUtils {
        public static bool is_event_in_widget(Gdk.Event event, Gtk.Widget widget) {
            int widget_root_x, widget_root_y;
            widget.get_window().get_root_coords(0, 0, out widget_root_x, out widget_root_y);
            Gtk.Allocation allocation;
            widget.get_allocation(out allocation);
            double event_x_root, event_y_root;
            switch (event.type) {
                case BUTTON_PRESS: case 2BUTTON_PRESS: case 3BUTTON_PRESS: case BUTTON_RELEASE:
                    event_x_root = event.button.x_root;
                    event_y_root = event.button.y_root;
                    break;
                case TOUCHPAD_PINCH:
                    event_x_root = event.touchpad_pinch.x_root;
                    event_y_root = event.touchpad_pinch.y_root;
                    break;
                case TOUCHPAD_SWIPE:
                    event_x_root = event.touchpad_swipe.x_root;
                    event_y_root = event.touchpad_swipe.y_root;
                    break;
                case SCROLL:
                    event_x_root = event.scroll.x_root;
                    event_y_root = event.scroll.y_root;
                    break;
                case MOTION_NOTIFY:
                    event_x_root = event.motion.x_root;
                    event_y_root = event.motion.y_root;
                    break;
                case ENTER_NOTIFY: case LEAVE_NOTIFY:
                    event_x_root = event.crossing.x_root;
                    event_y_root = event.crossing.y_root;
                    break;
                default:
                    return false;
            }
            return (widget_root_x <= (int) event_x_root)
                    && ((int) event_x_root < widget_root_x + allocation.width)
                    && (widget_root_y <= (int) event_y_root)
                    && ((int) event_y_root <= widget_root_y + allocation.height);
        }
    }
}
