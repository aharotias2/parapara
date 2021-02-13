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

extern int tatap_filename_compare(string str_a, string str_b);

/**
 * TatapFileList is a custome Gee.LinkedList<File>.
 */
public class TatapFileList {
    public signal void updated();
    public signal void terminated();
    public signal void directory_not_found();
    public signal void file_not_found();

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

    public TatapFileList(string dir_path) {
        this.dir_path = dir_path;
        closed = false;
    }

    public void close() {
        closed = true;
    }

    public bool set_current(File file) {
        string name = file.get_basename();
        int new_index = file_list.index_of(name);
        if (new_index >= 0) {
            current_index = new_index;
            current_name = name;
            return true;
        } else if (current_index >= 0 && current_index < file_list.size) {
            current_name = file_list[current_index];
            return true;
        } else if (current_index >= 0 && current_index >= file_list.size) {
            current_index = file_list.size - 1;
            current_name = file_list[current_index];
            return true;
        } else {
            current_index = -1;
            current_name = "";
            file_not_found();
            return false;
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

    public File? get_prev_file(int offset = 1) {
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
                if (current_index <= 0) {
                    continue;
                } else if (current_index < file_list.size) {
                    new_index = current_index - offset;
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

    public File? get_next_file(int offset = 1) {
        if (file_list.size == 0) {
            return null;
        }
        int new_index;
        const int try_count = 3;
        for (int i = 0; i < try_count; i++) {
            if (file_list.size == 0) {
                return null;
            }
            if (current_index < file_list.size - offset) {
                new_index = current_index + offset;
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

    public async void make_list_async() {
        Gee.List<string>? inner_file_list = null;
        TatapFileListThreadData thread_data = new TatapFileListThreadData(dir_path);
        thread_data.file_found.connect((file_name) => {
            string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, file_name);
            try {
                return TatapFileUtils.check_file_is_image(path);
            } catch (Error e) {
                thread_data.terminate();
                file_not_found();
                return false;
            }
        });
        thread_data.sorted.connect(tatap_filename_compare);
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
        while (!thread_data.canceled && !closed) {
            yield;
            if (thread_data.canceled || inner_file_list == null || inner_file_list.size == 0) {
                break;
            }
            file_list = inner_file_list;
            updated();
        }
        thread_data.terminate();
        terminated();
        int thread_result = thread.join();
        if (thread_result < 0) {
            directory_not_found();
        }
    }
}
