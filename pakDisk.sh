#!/bin/bash

# pakDisk.sh - Takes a binary/Program Pak image and converts it to a disk image for flashing into CoCo SDC flash.
# Copyright (C)2023  Christopher Hyzer (TJBChris)
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# No arguemnts?  --help?  Wrong # of args?  No problem.  HELP!
showHelp () {
    echo -e "\nUsage: $0 <binaryname.ccc> <diskname.dsk>\n\nWhere:"
    echo "<binaryname.ccc> is the name of the Program Pak/binary file."
    echo "<diskname.dsk> is the 8.3 disk image file name that will contain your image."
    echo -e "\nThe file must be <= 16K in size."
    echo -e "\nExample: $0 ./neutriod.ccc\n"
}

file="PAK.BIN"

# Do we want help, and if not, do we has file?
if [[ $# -ne 2 || "$1" == "--help" ]]; then
    showHelp
    exit 1
fi

if [ ! -f $1 ]; then
    echo "$0: Failed to find $1.  Exiting."
    exit 1
fi

# ToolShed tools in the path?
which decb >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "decb is not in your path.  Ensure ToolShed tools are in the path and try again."
    exit 1
fi

# File size check.
fSize=`du -b $1 | cut -f1`
echo "$1: Size = $fSize bytes."

if [ $fSize -gt 16384 ]; then
    echo "File size is too large; must be smaller than 16,384 bytes."
    exit 1
fi

# Get the file size in hex, generate LOADM preamble and postamble.
hexSize=`printf "%04x" $fSize | sed 's/.\{2\}/&\\\x/g'`
preamble="\x00\x"$hexSize"38\x00"
postamble="\xff\x00\x00\x38\x00"

# Put it together in a pretty BIN file.
echo "Writing $file."
echo -en $preamble > $file
cat $1 >> $file
echo -en $postamble >> $file

# Create a new CoCo SDC disk
decb dskini $2
decb copy -2 PAK.BIN $2,PAK.BIN
decb copy -0 -a flash.bas $2,FLASH.BAS

echo "Done.  Assuming no errors, follow these steps:"
echo -e "\n 1. Copy $2 to your CoCo SDC's SD card.\n 2. Power up your CoCo with the card in the CoCoSDC."
echo -e " 3. Issue the command: DRIVE 0,\"$2\"\n4. Issue the command: RUN \"FLASH.BAS\"\n 5. Follow the prompts."
