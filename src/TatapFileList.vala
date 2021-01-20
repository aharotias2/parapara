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

/**
 * TatapFileList is a custome Gee.LinkedList<File>.
 */
public class TatapFileList {
    public signal void updated();
    
    private string dir_path = "";
    private Gee.List<string> file_list = new Gee.LinkedList<string>();
    private int current_index = -1;
    private string current_name = "";
    private bool closed;

    public int size {
        get {
            return file_list.size;
        }
    }

    public TatapFileList() {
        closed = false;
    }

    public void close() {
        closed = true;
    }

    public signal void directory_not_found();
    public signal void file_not_found();

    public void make_list(string dir_path) throws FileError {
        make_list_async.begin(dir_path);
    }

    public void set_current(File file) {
        string name = file.get_basename();
        int new_index = file_list.index_of(name);
        if (new_index >= 0) {
            current_index = new_index;
            current_name = name;
        } else if (current_index < file_list.size) {
            current_name = file_list.get(current_index);
        } else {
            current_index = file_list.size - 1;
            current_name = file_list.get(current_index);
            file_not_found();
        }
    }

    public bool file_is_first(bool default_value = true) {
        if (file_list.size == 0) {
            return default_value;
        } else {
            return current_index == 0;
        }
    }

    public bool file_is_last(bool default_value = true) {
        if (file_list.size == 0) {
            return default_value;
        } else {
            return current_index == file_list.size - 1;
        }
    }

    public File? get_prev_file(File file) {
        if (file_list.size == 0) {
            return null;
        }
        int new_index;
        if (current_index > 0) {
            const int try_count = 3;
            for (int i = 0; i < try_count; i++) {
                if (file_list.size == 0) {
                    return null;
                }
                if (current_index < file_list.size) {
                    new_index = current_index - 1;
                } else {
                    new_index = file_list.size - 1;
                }
                string new_name = file_list.get(new_index);
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, new_name);
                if (FileUtils.test(path, FileTest.EXISTS)) {
                    File prev_file = File.new_for_path(path);
                    current_index = new_index;
                    current_name = new_name;
                    return prev_file;
                }
                Thread.usleep(500);
            }
            file_not_found();
        }
        return null;
    }

    public File? get_next_file(File file) {
        if (file_list.size == 0) {
            return null;
        }
        int new_index;
        const int try_count = 3;
        for (int i = 0; i < try_count; i++) {
            if (file_list.size == 0) {
                return null;
            }
            if (current_index < file_list.size - 1) {
                new_index = current_index + 1;
            } else if (current_index == file_list.size - 1) {
                continue;
            } else {
                new_index = file_list.size - 1;
            }
            string new_name = file_list.get(new_index);
            string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, new_name);
            if (FileUtils.test(path, FileTest.EXISTS)) {
                current_index = new_index;
                current_name = new_name;
                File? next_file = File.new_for_path(path);
                return next_file;
            }
            Thread.usleep(500);
        }
        if (current_index < file_list.size - 1) {
            file_not_found();
        }
        return null;
    }

    public async void make_list_async(string dir_path) {
        this.dir_path = dir_path;
        string save_dir_path = dir_path;
        Gee.List<string>? inner_file_list = null;
        TatapFileListThreadData thread_data = new TatapFileListThreadData(dir_path);
        thread_data.file_found.connect((file_name) => {
            string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, file_name);
            try {
                return TatapFileUtils.check_file_is_image(path);
            } catch (FileError e) {
                thread_data.canceled = true;
                file_not_found();
                return false;
            }
        });
        thread_data.sort.connect((a, b) => {
            return a.collate(b);
        });
        thread_data.update.connect((thread_file_list) => {
            if (thread_file_list == null || thread_file_list.size == 0) {
                thread_data.canceled = true;
            } else {
                inner_file_list = thread_file_list;
            }
            Idle.add(make_list_async.callback);
            return true;
        });
        Thread<int> thread = new Thread<int>(null, thread_data.run);
        while (!thread_data.canceled && !closed) {
            if (save_dir_path != this.dir_path) {
                break;
            }
            yield;
            if (thread_data.canceled || inner_file_list == null || inner_file_list.size == 0) {
                thread_data.canceled = true;
                break;
            }
            file_list = inner_file_list;
            updated();
        }
        thread_data.terminate();
        int res = thread.join();
        if (res < 0) {
            directory_not_found();
        }
    }

    public class TatapFileListThreadData : Object {
        public signal bool file_found(string file_path);
        public signal bool update(Gee.List<string>? file_list);
        public signal int sort(string a, string b);
        public bool canceled { get; set; }
        private string dir_path;

        public TatapFileListThreadData(string dir_path) {
            this.dir_path = dir_path;
            this.canceled = false;
        }

        public int run() {
            try {
                while (!canceled) {
                    Dir dir = Dir.open(dir_path);
                    string? name = null;
                    Gee.List<string> thread_file_list = new Gee.ArrayList<string>();
                    while ((name = dir.read_name()) != null) {
                        if (name != "." || name != "..") {
                            if (file_found(name)) {
                                thread_file_list.add(name);
                            }
                        }
                    }
                    thread_file_list.sort((a, b) => sort(a, b));
                    if (update(thread_file_list)) {
                        Thread.usleep(3000000);
                    } else {
                        return 0;
                    }
                }
                return 0;
            } catch (FileError e) {
                return -1;
            }
        }

        public void terminate() {
            canceled = true;
        }
    }
}
