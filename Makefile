# Copyright 2019 Tanaka Takayuki (田中喬之) 
#
# This file is part of tatap.
#
# tatap is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# tatap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with tatap.  If not, see <http://www.gnu.org/licenses/>.
#
# Tanaka Takayuki <msg@gorigorilinux.net>

all: tatap.vala
	valac -o tatap --pkg=gtk+-3.0 --pkg=gee-0.8 $^

ja: tatap.vala
	valac -o tatap --pkg=gtk+-3.0 --pkg=gee-0.8 -D LANGUAGE_JA $^

debug: tatap.vala
	valac -o tatap --pkg=gtk+-3.0 --pkg=gee-0.8 -D DEBUG $^
