/*
 *  Copyright 2019-2022 Tanaka Takayuki (田中喬之)
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

namespace ParaPara {
    public enum ToolbarOption {
        ALWAYS_VISIBLE, ALWAYS_HIDDEN, DEPENDS;

        public static ToolbarOption value_of(string name) {
            switch (name) {
              case "always-visible":
                return ALWAYS_VISIBLE;
              case "always-hidden":
                return ALWAYS_HIDDEN;
              default:
              case "depends":
                return DEPENDS;
            }
        }

        public string to_string() {
            switch (this) {
              case ALWAYS_VISIBLE:
                return "always-visible";
              case ALWAYS_HIDDEN:
                return "always-hidden";
              default:
              case DEPENDS:
                return "depends";
            }
        }
    }
}
