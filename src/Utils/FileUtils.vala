/*
 *  Copyright 2019-2023 Tanaka Takayuki (田中喬之)
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

namespace ParaPara {
    namespace FileUtils {
        public string? get_mime_type_from_file(File? file) throws Error {
            FileInfo info = file.query_info("standard::*", 0);
            return info.get_content_type();
        }

        /**
         * This function checks an argument as a file path pointing to an image file or not.
         *
         * when path does not exist        => throw Error
         * when path is not a regular file => return false
         * when path is not a image file   => return false
         * when path is a image file       => return true
         */
        public bool check_file_is_image(string? path) throws Error {
            if (GLib.FileUtils.test(path, GLib.FileTest.EXISTS)) {
                if (GLib.FileUtils.test(path, GLib.FileTest.IS_REGULAR)) {
                    File f = File.new_for_path(path);
                    string mime_type = get_mime_type_from_file(f);
                    if (mime_type.split("/")[0] == "image") {
                        return true;
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            } else {
                throw new FileError.EXIST(_("The file path is invalid. it does not exist or is not a regular file."));
            }
        }
    }
}
