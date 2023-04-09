/*
 *  Copyright 2019-2023 Tanaka Takayuki (田中喬之)
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

#include <stdlib.h>
#include <string.h>
#include <glib.h>

#ifndef NAME_MAX
# define NAME_MAX 255
#endif
#define PART_TYPE_EMPTY 0
#define PART_TYPE_DIGIT 1
#define PART_TYPE_NONDIGIT 2

struct StrPart {
    int type;
    int length;
    gchar *data;
};

gchar* parapara_string_get_next_part(gchar* str, struct StrPart* part);
int parapara_string_compare_nondigit(gchar *str_a, gchar *str_b);
int parapara_string_last_index_of_char(gchar *str, gchar needle);

/**
 * The string (filename) comparison function.
 * This function compares two strings so that the number part of the string is correct in the order of the numbers.
 */
int parapara_filename_compare(gchar* str_a, gchar* str_b) {
    int last_dot_a = parapara_string_last_index_of_char(str_a, '.');
    int last_dot_b = parapara_string_last_index_of_char(str_b, '.');
    gchar *name_a = g_strndup(str_a, last_dot_a);
    gchar *name_b = g_strndup(str_b, last_dot_b);
    struct StrPart part_a = {0};
    struct StrPart part_b = {0};
    int result = 0;
    gchar *next_a = name_a, *next_b = name_b;
    do {
        next_a = parapara_string_get_next_part(next_a, &part_a);
        next_b = parapara_string_get_next_part(next_b, &part_b);
        if (part_a.type == PART_TYPE_EMPTY) {
            if (part_b.type == PART_TYPE_EMPTY) {
                result = 0;
                break;
            } else {
                result = -1;
                g_free(part_b.data);
            }
        } else if (part_b.type == PART_TYPE_EMPTY) {
            result = 1;
            g_free(part_a.data);
        } else {
            if (part_a.type == PART_TYPE_DIGIT && part_b.type == PART_TYPE_DIGIT) {
                int int_a = atoi(part_a.data);
                int int_b = atoi(part_b.data);
                result = int_a - int_b;
            } else {
                result = g_ascii_strncasecmp(part_a.data, part_b.data, NAME_MAX);
            }
            g_free(part_a.data);
            g_free(part_b.data);
        }
    } while (result == 0);
    g_free(name_a);
    g_free(name_b);
    if (result == 0) {
        if (str_a[last_dot_a] != '\0' && str_b[last_dot_b] != '\0') {
            gchar *ext_a = str_a + last_dot_a + 1;
            gchar *ext_b = str_b + last_dot_b + 1;
            result = strcmp(ext_a, ext_b);
        } else {
            result = last_dot_a - last_dot_b;
        }
    }
    return result;
}

gchar* parapara_string_get_next_part(gchar* str, struct StrPart* part) {
    if (str[0] == '\0') {
        part->type = PART_TYPE_EMPTY;
        part->length = 0;
        part->data = NULL;
        return NULL;
    }
    gboolean isdigit = g_ascii_isdigit(str[0]);
    int i = 1;
    while (str[i] != '\0' && isdigit == g_ascii_isdigit(str[i])) {
        i++;
    }
    part->type = isdigit ? PART_TYPE_DIGIT : PART_TYPE_NONDIGIT;
    part->data = g_strndup(str, i);
    part->length = i;
    return str + i;
}

int parapara_string_last_index_of_char(gchar *str, gchar needle) {
    int len = strlen(str);
    int offset = 0;
    while (str[offset] == '.') {
        offset++;
    }
    int i = len - 1;
    while (i > offset && str[i] != needle) {
        i--;
    }
    return i == offset ? len : i;
}
