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

public errordomain TatapError {
    INVALID_FILE,
    INVALID_EXTENSION,
    FILE_NOT_EXISTS
}

public class Application : Gtk.Application {
    /**
    * The Program Entry Proint.
    * It initializes Gtk, and create a new window to start program.
    */
    public static int main(string[] args) {
#if DEBUG
        string home_dir = Environment.get_home_dir();
        stdout = FileStream.open(home_dir + "/tatap-out.txt", "w+");
        stderr = FileStream.open(home_dir + "/tatap-out.txt", "w+");
#endif
        Gtk.init(ref args);
        var window = new TatapWindow();

        if (args.length > 1) {
            File file = File.new_for_path(args[1]);
            string? filepath = file.get_path();
            string mimetype = TatapFileUtils.get_mime_type_from_file(file);

            stdout.printf("The first argument is a file path: %s (%s)\n", filepath,
                        mimetype != null ? "unknown type" : "");

            if (mimetype != null && mimetype.split("/")[0] == "image") {
                window.open_file(filepath);
            } else {
                stderr.printf("The argument is not a image file!\n");
            }
        }

        window.show_all();
        Gtk.main();
        return 0;
    }
}
