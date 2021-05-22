#!/bin/bash

TARGET=${1:-src}
grep -r '_("' "$TARGET" | awk -F: '{print $1}' | sort | uniq > po/POTFILES

xgettext -L vala --from-code=UTF-8 --sort-output -o po/com.github.aharotias2.parapara.pot $(find src -type f -name "*.vala")
if [ $? -ne 0 ]
then
    exit 1
fi

msgmerge --sort-output -o new-ja.po po/ja.po po/com.github.aharotias2.parapara.pot
if [ $? -ne 0 ]
then
    exit 2
fi

mv new-ja.po po/ja.po

exit 0
