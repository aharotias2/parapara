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

using Gdk;

/**
 * PixbufUtils is used by TatapImage.
 * This contains image scale function.
 */
public class PixbufUtils {
    public static Pixbuf scale_limited(Pixbuf pixbuf, int size) {
        size = int.max(10, size);
        if (pixbuf.width > pixbuf.height) {
            return scale_xy(pixbuf, size, (int) (size * ((double) pixbuf.height / pixbuf.width)));
        } else if (pixbuf.width < pixbuf.height) {
            return scale_xy(pixbuf, (int) (size * ((double) pixbuf.width / pixbuf.height)), size);
        } else {
            return scale_xy(pixbuf, size, size);
        }            
    }

    public static Pixbuf scale_xy(Pixbuf pixbuf, int width, int height) {
        debug("PixbufUtils.scale_xy(%d, %d -> %d, %d)", pixbuf.width, pixbuf.height, width, height);
        return pixbuf.scale_simple(width, height, InterpType.BILINEAR);
    }
}
