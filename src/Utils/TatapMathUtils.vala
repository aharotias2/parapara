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
 * TatapMathUtils contains functions that needs mathmatic
 * calculation task.
 */
public class TatapMathUtils {
    public static string bytes_string(uint64 n) {
        if (n < 1024) {
            return "%dBytes".printf((int) n);
        }
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fKB".printf(n2);
        }
        n = n / 1024;
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fMB".printf(n2);
        }
        n = n / 1024;
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fGB".printf(n2);
        }
        n = n / 1024;
        if (n / 1024 < 1024) {
            double n2 = ((double) n) / 1024;
            return "%.2fTB".printf(n2);
        }
        return "%uBytes".printf((uint) n);
    }
}
