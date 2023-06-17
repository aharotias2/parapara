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
    public class SlideFileAccessor : Object {
        public unowned FileList file_list {
            get;
            construct;
        }

        public SortOrder sort_order {
            get;
            set;
        }

        public SlideFileAccessor(FileList file_list, SortOrder sort_order) {
            Object(
                file_list: file_list,
                sort_order: sort_order
            );
        }

        public string get_filename_at(int index) throws AppError {
            if (index >= file_list.size || index < 0) {
                throw new AppError.INDEX_OUT_OF_BOUNDS("Invalid access to the file list");
            }
            if (sort_order == ASC) {
                return file_list.get_filename_at(index);
            } else {
                return file_list.get_filename_at(file_list.size - 1 - index);
            }
        }

        public int get_index_of(string filename) throws AppError {
            int index = file_list.get_index_of(filename);
            if (sort_order == ASC) {
                return index;
            } else {
                return file_list.size - 1 - index;
            }
        }

        public int get_size() {
            return file_list.size;
        }
    }
}
