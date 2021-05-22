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

namespace ParaPara {
    public class Application : Gtk.Application {
        public static bool config_repeat_updating_file_list = false;
        public static bool version = false;
        public static string desc_version;
        public static string desc_update_file_list_constantly;

        private const GLib.OptionEntry[] options = {
            { "version", 'v', OptionFlags.NONE, OptionArg.NONE, ref version, "Display version number", null },
            { "repeat-updating-file-list", 'u', OptionFlags.NONE, OptionArg.NONE, ref config_repeat_updating_file_list,
                    "Have this app search the directory repeatedly to see if the contained files have modified", null },
            { null }
        };

        /**
        * The Program Entry Proint.
        * It initializes Gtk, and create a new window to start program.
        */
        public Application () {
            Object (
                application_id: "com.github.aharotias2.parapara",
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
                ParaPara.Window window = create_new_window();
                window.open_file_async.begin(file);
            }
        }

        private ParaPara.Window create_new_window() {
            var window = new ParaPara.Window() {
                repeat_updating_file_list = config_repeat_updating_file_list
            };
            window.set_application(this);
            window.require_new_window.connect(() => create_new_window());
            window.require_quit.connect(() => quit());
            window.show_all();
            return window;
        }

        public static int main(string[] args) {
            var app = new ParaPara.Application();

            if (args.length > 1) {
                try {
                    var opt_context = new OptionContext("- Options");
                    opt_context.set_help_enabled(true);
                    opt_context.add_main_entries(options, null);
                    opt_context.parse(ref args);
                } catch (OptionError e) {
                    printerr("error: %s\n", e.message);
                    printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
                    return 1;
                }

                if (version) {
                    print(@"$(app.application_id) 3.0\n");
                    return 0;
                }

                File[]? files = null;

                for (int i = 0; i < args.length; i++) {
                    if (GLib.FileUtils.test(args[i], FileTest.IS_REGULAR | FileTest.EXISTS)) {
                        files += File.new_for_path(args[i]);
                    }
                }

                app.open(files, "Open specified files");
            }

            return app.run(args);
        }
    }
}
