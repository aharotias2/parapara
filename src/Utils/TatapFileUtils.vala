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

public class TatapFileUtils {
    public static FileInfo? get_file_info_from_file(File? file) {
        if (file == null) {
            return null;
        }

        try {
            return file.query_info("standard::*", 0);
        } catch (Error e) {
            return null;
        }
    }

    public static string? get_mime_type_from_file(File? file) {
        FileInfo? info = get_file_info_from_file(file);
        if (info != null) {
            return info.get_content_type();
        }
        return null;
    }

    /**
     * This function checks an argument as a file path pointing to an image file or not.
     *
     * when path does not exist        => throw Error
     * when path is not a regular file => return false
     * when path is not a image file   => return false
     * when path is a image file       => return true
     */
    public static bool check_file_is_image(string? path) throws FileError {
        if (FileUtils.test(path, FileTest.EXISTS)) {
            if (FileUtils.test(path, FileTest.IS_REGULAR)) {
                File f = File.new_for_path(path);
                string? mime_type = get_mime_type_from_file(f);
                if (mime_type.split("/")[0] == "image") {
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else {
            throw new FileError.EXIST("The file path is invalid. it does not exist or is not a regular file.");
        }
    }
}

