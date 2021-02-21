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

using Gtk, Gdk;

public enum TatapFileType {
    JPEG, PNG, BMP, ICO, GIF;

    public static string? of(string filename) {
        return to_pixbuf_type(filename.substring(filename.last_index_of_char('.') + 1));
    }

    public string? to_string() {
        switch (this) {
            case JPEG: return "jpg";
            case PNG: return "png";
            case GIF: return "gif";
            case BMP: return "bmp";
            case ICO: return "ico";
            default: return null;
        }
    }

    public static string? to_pixbuf_type(string extension) {
        switch (extension) {
            case "jpeg": case "jpg": case "JPG": case "JPEG":
            default:
                return "jpeg";
            case "png": case "PNG":
                return "png";
            case "bmp": case "BMP":
                return "bmp";
            case "gif": case "GIF":
                return "gif";
            case "ico": case "ICO":
                return "ico";
        }
    }

    public static bool is_valid_extension(string extension) {
        switch (extension) {
            case "jpeg": case "jpg": case "JPG": case "JPEG":
            case "png": case "PNG":
            case "bmp": case "BMP":
            case "ico": case "ICO":
            case "gif": case "GIF":
                return true;
            default:
                return false;
        }
    }
}
