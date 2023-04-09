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

/**
 * ParaParaFileList is a custome Gee.LinkedList<File>.
 */
namespace ParaPara {
    public class FileListIter {
        private FileList file_list;
        private int index;

        public FileListIter(FileList file_list) {
            this.file_list = file_list;
            index = 0;
        }

        public bool next() {
            if (file_list.has_list) {
                return index < file_list.size - 1;
            } else {
                return false;
            }
        }

        public string get() {
            try {
                return file_list.get_filename_at(index++);
            } catch (AppError e) {
                return "";
            }
        }
    }
}
