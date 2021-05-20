/*
 *  Copyright 2019-2021 Tanaka Takayuki (田中喬之)
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

/**
 * TatapFileList is a custome Gee.LinkedList<File>.
 */
namespace Tatap {
    public class FileList : Object {
        public signal void updated();
        public signal void terminated();
        public signal void directory_not_found();
        public signal void file_not_found();

        public string dir_path { get; construct set; }
        public bool closed { get; private set; default = false; }

        private Gee.List<string>? file_list = null;

        public FileList.with_dir_path(string dir_path) {
            Object(
                dir_path: dir_path
            );
        }

        public bool has_list {
            get {
                return file_list != null;
            }
        }

        public int size {
            get {
                return has_list ? file_list.size : 0;
            }
        }

        public FileListIter iterator() {
            return new FileListIter(this);
        }

        public string get_filename_at(int index) throws AppError {
            if (file_list == null) {
                throw new AppError.FILE_LIST_ERROR(_("The file list is not initialized!"));
            } else if (0 <= index < size) {
                return file_list[index];
            } else {
                throw new AppError.FILE_LIST_ERROR(_("The index is out of the bounds (%d/%d)"), index, file_list.size);
            }
        }

        public int get_index_of(string filename) throws AppError {
            if (file_list != null) {
                return file_list.index_of(filename);
            } else {
                throw new AppError.FILE_LIST_ERROR(_("The file list is not initialized!"));
            }
        }

        public void close() {
            closed = true;
        }

        public async void make_list_async(bool loop = true) throws AppError {
            Gee.List<string>? inner_file_list = null;
            Tatap.FileListThreadData thread_data = new Tatap.FileListThreadData(dir_path);
            thread_data.file_found.connect((file_name) => {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, file_name);
                try {
                    return Tatap.FileUtils.check_file_is_image(path);
                } catch (Error e) {
                    thread_data.terminate();
                    file_not_found();
                    return false;
                }
            });
            thread_data.sorted.connect(StringUtils.compare_filenames);
            thread_data.updated.connect((thread_file_list) => {
                if (thread_file_list == null || thread_file_list.size == 0) {
                    thread_data.terminate();
                } else {
                    inner_file_list = thread_file_list;
                }
                Idle.add(make_list_async.callback);
                return true;
            });
            Thread<int> thread = new Thread<int>(null, thread_data.run);
            do {
                yield;
                if (thread_data.canceled || inner_file_list == null || inner_file_list.size == 0) {
                    break;
                }
                file_list = inner_file_list;
                updated();
            } while (loop && !thread_data.canceled && !closed);
            thread_data.terminate();
            terminated();
            int thread_result = thread.join();
            if (thread_result < 0) {
                directory_not_found();
            }
        }
    }
}
