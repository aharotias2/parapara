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
    public class SingleFileAccessor : Object {

        public FileList file_list { get; construct; }

        private int current_index = 0;
        private string? current_name = null;

        public SingleFileAccessor.with_file_list(FileList file_list) {
            Object(
                file_list: file_list
            );
        }

        public int get_index() {
            return current_index;
        }

        public void set_index(int index) throws AppError {
            if (0 <= index < file_list.size) {
                current_index = index;
                current_name = file_list.get_filename_at(current_index);
            } else {
                throw new AppError.FILE_LIST_ERROR(_("The index is out of the bounds (%d/%d)"), index, file_list.size);
            }
        }

        public string? get_name() {
            return current_name;
        }

        public void set_name(string name) throws AppError {
            current_name = name;
            current_index = file_list.get_index_of(current_name);
            if (current_index < 0) {
                current_name = null;
                throw new AppError.FILE_LIST_ERROR(_("file list does not contains this name! (%s)"), name);
            }
        }

        public File? get_file() {
            if (current_name != null) {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, file_list.dir_path, current_name);
                return File.new_for_path(path);
            } else {
                return null;
            }
        }

        public void set_file(File file) throws AppError {
            string name = file.get_basename();
            set_name(name);
        }

        public bool is_first(bool default_value = true) {
            if (file_list.size == 0) {
                return default_value;
            } else {
                return current_index == 0;
            }
        }

        public bool is_last(bool default_value = true) {
            if (file_list.size == 0) {
                return default_value;
            } else {
                return current_index == file_list.size - 1;
            }
        }

        public bool go_backward(int offset = 1) throws AppError {
            if (file_list.has_list && 0 < current_index < file_list.size) {
                current_index--;
                current_name = file_list.get_filename_at(current_index);
                return true;
            } else {
                return false;
            }
        }

        public bool go_forward(int offset = 1) throws AppError {
            if (offset >= 0 && file_list.has_list && 0 <= current_index < file_list.size - 1) {
                current_index++;
                current_name = file_list.get_filename_at(current_index);
                return true;
            } else {
                return false;
            }
        }
    }
}
