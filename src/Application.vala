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
    public Application () {
        Object (
            application_id: "com.github.aharotias2.tatap",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    protected override void activate() {
        create_new_window();
    }

    protected override void open(File[] files, string hint) {
        if (files.length == 0) {
            return;
        }

        foreach (var file in files) {
            string? filepath = file.get_path();
            string mimetype = TatapFileUtils.get_mime_type_from_file(file);
            if (mimetype != null && mimetype.split("/")[0] == "image") {
                TatapWindow window = create_new_window();
                window.open_file(filepath);
            } else {
                stderr.printf("The argument is not a image file!\n");
            }
        }
    }

    private TatapWindow create_new_window() {
        var window = new TatapWindow();
        window.set_application(this);
        window.require_new_window.connect(() => create_new_window());
        window.require_quit.connect(() => quit());
        window.show_all();
        return window;
    }

    public static int main(string[] args) {
        var app = new Application();

        if (args.length > 1) {
            File[]? files = null;

            for (int i = 0; i < args.length; i++) {
                files += File.new_for_path(args[i]);
            }

            app.open(files, "Open specified files");
        }

        return app.run(args);
    }
}
