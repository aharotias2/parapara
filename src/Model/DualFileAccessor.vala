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
    public class DualFileAccessor : Object {
        public unowned FileList file_list {
            get;
            construct;
        }

        private int index1 = 0;
        private int index2 = 1;

        public DualFileAccessor.with_file_list(FileList file_list) {
            Object(
                file_list: file_list
            );
        }

        public int get_index1() {
            return index1;
        }

        public int get_index2() {
            return index2;
        }

        public void set_index1(int index) throws AppError {
            if (-1 <= index && index < file_list.size) {
                index1 = index;
                index2 = index + 1;
            } else {
                index1 = -1;
                index2 = -1;
                throw new AppError.FILE_LIST_ERROR("Index out of bounds!");
            }
        }

        public void set_index2(int index) throws AppError {
            if (0 <= index <= file_list.size) {
                index1 = index - 1;
                index2 = index;
            } else {
                index1 = -1;
                index2 = -1;
                throw new AppError.FILE_LIST_ERROR("Index out of bounds!");
            }
        }

        public string get_name1() throws AppError {
            return file_list.get_filename_at(index1);
        }

        public string get_name2() throws AppError {
            return file_list.get_filename_at(index2);
        }

        public void set_name1(string name1) throws AppError {
            index1 = file_list.get_index_of(name1);
            index2 = index1 + 1;
            if (index1 < 0) {
                index1 = 1;
                index2 = 1;
            } else if (index1 == file_list.size - 1) {
                index2 = -1;
            }
        }

        public void set_name2(string name2) throws AppError {
            index2 = file_list.get_index_of(name2);
            index1 = index2 - 1;
            if (index2 < 0) {
                index1 = -1;
                index2 = -1;
            }
        }

        public File? get_file1() throws AppError {
            string path = Path.build_path(Path.DIR_SEPARATOR_S, file_list.dir_path, get_name1());
            return File.new_for_path(path);
        }

        public File? get_file2() throws AppError {
            string path = Path.build_path(Path.DIR_SEPARATOR_S, file_list.dir_path, get_name2());
            return File.new_for_path(path);
        }

        public void set_file1(File file1) throws AppError {
            string name1 = file1.get_basename();
            set_name1(name1);
        }

        public void set_file2(File file2) throws AppError {
            string name2 = file2.get_basename();
            set_name2(name2);
        }

        public bool is_first(bool default_value = true) {
            if (file_list.size == 0) {
                return default_value;
            } else if (index1 == 0 || index2 == 0) {
                return true;
            } else if (index1 < 0 && index2 < 0) {
                return true;
            } else {
                return false;
            }
        }

        public bool is_last(bool default_value = true) {
            if (file_list.size == 0) {
                return default_value;
            } else if (index1 >= file_list.size - 1 || index2 >= file_list.size - 1) {
                return true;
            } else if (index1 < 0 && index2 < 0) {
                return true;
            } else {
                return false;
            }
        }

        public bool go_backward(int offset = 2) throws Error {
            if (index2 < 0) {
                index2 = index1 + 1;
            }
            index1 = index1 - offset;
            index2 = index2 - offset;
            if (index1 < 0) {
                index1 = -1;
            }
            if (index2 < 0) {
                index2 = -1;
            }
            return !(index1 < 0 && index2 < 0);
        }

        public bool go_forward(int offset = 2) throws AppError {
            index1 += offset;
            index2 += offset;
            if (index1 >= file_list.size) {
                index1 = -1;
            }
            if (index2 >= file_list.size) {
                index2 = -1;
            }
            return !(index1 < 0 && index2 < 0);
        }
    }
}

