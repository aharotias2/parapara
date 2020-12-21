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
 *  Tanaka Takayuki <msg@gorigorilinux.net>
 */

/**
 * TatapFileList is a custome Gee.LinkedList<File>.
 */
public class TatapFileList {
    private string dir_path = "";
    private Gee.List<string> file_list = new Gee.LinkedList<string>();
    private int current_index = -1;
    private string current_name = "";
    private bool inner_running = false;

    public int size {
        get {
            return file_list.size;
        }
    }

    public signal void directory_not_found();
    public signal void file_not_found();

    public void make_list(string dir_path) throws FileError {
        this.dir_path = dir_path;
        Dir dir = Dir.open(dir_path);
        string? name;
        while (true) {
            try {
                while ((name = dir.read_name()) != null) {
                    if (name != "." && name != "..") {
                        string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);
                        if (TatapFileUtils.check_file_is_image(path)) {
                            file_list.add(name);
                        }
                    }
                }
                break;
            } catch (FileError e) {
                stderr.printf("FileError: %s\n", e.message);
            }
        }
        file_list.sort((a, b) => a.collate(b));
        Timeout.add(1000, () => {
                make_list_async.begin();
                return Source.REMOVE;
            });
    }
    
    public void set_current(File file) {
        string name = file.get_basename();
        int new_index = file_list.index_of(name);
        if (new_index >= 0) {
            current_index = new_index;
            current_name = name;
        } else {
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
        }
        file_not_found();
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
        file_not_found();
        return null;
    }

    private async void make_list_async() {
        try {
            while (true) {
                debug("Start running async loop");
                Gee.List<string> list = new Gee.LinkedList<string>();
                Dir dir = Dir.open(dir_path);
                string? name = null;
                inner_running = true;

                try {
                    while ((name = dir.read_name()) != null) {
                        if (name != "." && name != "..") {
                            string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);
                            if (TatapFileUtils.check_file_is_image(path)) {
                                list.add(name);
                            }
                        }
                        Idle.add(make_list_async.callback);
                        yield;
                    }
                } catch (FileError e) {
                    // if file is not exist
                    file_not_found();
                    continue;
                }

                try {
                    int len = list.size;
                    if (len > 0) {
                        for (int i = 0; i < list.size; i++) {
                            string p = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, list.get(i));
                            if (!FileUtils.test(p, FileTest.EXISTS)) {
                                throw new TatapError.FILE_NOT_EXISTS("file is not found");
                            }
                        }

                        list.sort((a, b) => a.collate(b));
                        int new_index = list.index_of(current_name);
                        if (new_index >= 0) {
                            current_index = new_index;
                        } else if (current_index < list.size) {
                            current_name = list.get(current_index);
                        } else {
                            current_index = list.size - 1;
                            current_name = list.get(current_index);
                        }
                    }

                    file_list = list;
                    inner_running = false;
                    debug("File list is updated");
                    debug("End running async loop");
                    Timeout.add(1000, make_list_async.callback);
                    yield;
                } catch (TatapError e) {
                    // file existing check error after list made up.
                    file_not_found();
                }
            }
        } catch (FileError e) {
            // dir.open method failed.
            directory_not_found();
        }
    }
}
