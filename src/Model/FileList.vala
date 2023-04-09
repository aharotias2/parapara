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
    public class FileList : Object {
        public signal void updated();
        public signal void terminated();
        public signal void directory_not_found();
        public signal void file_not_found();
        
        public FileSystemNotifier notifier {
            get;
            private set;
        }

        public string dir_path {
            get;
            construct set;
        }
        
        public bool closed {
            get;
            private set;
            default = false;
        }

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
                int index = file_list.index_of(filename);
                if (index < 0) {
                    return file_list.size - 1;
                } else {
                    return index;
                }
            } else {
                throw new AppError.FILE_LIST_ERROR(_("The file list is not initialized!"));
            }
        }

        /**
         * Starts watching the directory and handle events what occures in it
         * and notify for callers or owners by sending signals.
         */
        public void start_watch() {
            notifier = new FileSystemNotifier(dir_path);
            notifier.children_updated.connect(() => {
                make_list_async.begin(false, (obj, res) => {
                    updated();
                });
            });
            notifier.directory_deleted.connect(() => {
                directory_not_found();
            });
            notifier.watch.begin();
            debug("file list watching has been started!");
        }
        
        public void close() {
            closed = true;
            notifier.quit();
        }

        public async void make_list_async(bool loop = true) throws AppError {
            Gee.List<string>? inner_file_list = null;
            ParaPara.FileListThreadData thread_data = new ParaPara.FileListThreadData(dir_path);
            thread_data.file_found.connect((file_name) => {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, file_name);
                try {
                    return ParaPara.FileUtils.check_file_is_image(path);
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
