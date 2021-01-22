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

public class TatapFileListThreadData : Object {
    public signal bool file_found(string file_path);
    public signal bool update(Gee.List<string>? file_list);
    public signal int sort(string a, string b);
    public bool canceled {
        get {
            return !keep_doing;
        }
        private set {
            keep_doing = !value;
        }
    }
    private string dir_path;
    private bool keep_doing;

    public TatapFileListThreadData(string dir_path) {
        this.dir_path = dir_path;
        this.canceled = false;
    }

    public int run() {
        try {
            while (keep_doing) {
                keep_doing = do_task();
                if (keep_doing) {
                    sleep(3000000, 10000);
                }
            }
            return 0;
        } catch (FileError e) {
            return -1;
        }
    }

    private bool do_task() throws FileError {
        Dir dir = Dir.open(dir_path);
        string? name = null;
        Gee.List<string> thread_file_list = new Gee.ArrayList<string>();
        while ((name = dir.read_name()) != null) {
            if (name != "." && name != "..") {
                if (file_found(name)) {
                    thread_file_list.add(name);
                } else if (canceled) {
                    return false;
                }
            }
        }
        thread_file_list.sort((a, b) => sort(a, b));
        return update(thread_file_list);
    }

    private bool sleep(uint time_length, uint check_interval) {
        for (uint i = 0; i < time_length; i += check_interval) {
            if (canceled) {
                return false;
            }
            Thread.usleep(check_interval);
        }
        return true;
    }

    public void terminate() {
        keep_doing = false;
    }
}
