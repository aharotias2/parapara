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

using Gdk;

/**
 * PixbufUtils is used by TatapImage.
 * This contains image scale function.
 */
public class PixbufUtils {
    /**
     * Scales the image to fit in a square of the specified size.
     */
    public static Pixbuf scale_limited(Pixbuf pixbuf, int size) {
        size = int.max(10, size);
        if (pixbuf.width > pixbuf.height) {
            return pixbuf.scale_simple(size, (int) (size * ((double) pixbuf.height / pixbuf.width)), InterpType.BILINEAR);
        } else if (pixbuf.width < pixbuf.height) {
            return pixbuf.scale_simple((int) (size * ((double) pixbuf.width / pixbuf.height)), size, InterpType.BILINEAR);
        } else {
            return pixbuf.scale_simple(size, size, InterpType.BILINEAR);
        }
    }

    /**
     * Specify the maximum width to maintain the aspect ratio and zoom in/out
     */
    public static Pixbuf scale_by_max_width(Pixbuf src_pixbuf, int max_width) {
        int height = (int) (src_pixbuf.height * ((double) max_width / (double) src_pixbuf.width));
        return src_pixbuf.scale_simple(max_width, height, InterpType.BILINEAR);
    }

    /**
     * Specify the maximum height to maintain the aspect ratio and zoom in/out
     */
    public static Pixbuf scale_by_max_height(Pixbuf src_pixbuf, int max_height) {
        int width = (int) (src_pixbuf.width * ((double) max_height / (double) src_pixbuf.height));
        return src_pixbuf.scale_simple(width, max_height, InterpType.BILINEAR);
    }
}
