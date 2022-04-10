## TES3MP Data Files Loader

This project is a set of scripts for TES3MP 0.8 making use of the tes3conv tool by Greatness7 to allow TES3MP server scripts to have easy access to the data of the plugins used by the clients.

## Features and Usage

Currently, this script uses a set of plugins converted to JSON by tes3conv to create its own set of JSON files containing the data of configurable record types (e.g. Activator, NPC, Creature) that can then be queried from a global Lua table or via a few included functions.

The script also contains the functionality to automatically update reference numbers in saved cells when its JSON files are regenerated after a change in the mods required by the server. (For a description of the problems that this can mitigate, see here: https://en.uesp.net/wiki/Morrowind_Mod:Doubling.) However, this functionality has not been sufficiently tested and may result in damaged server data. Back up your server/data/cell folder before using!

## Installation

tes3conv is required for providing input to the script: https://github.com/Greatness7/tes3conv

Installation instructions for the script: https://github.com/tes3mp-scripts/Tutorials

`dataFilesLoaderMain.lua` should be required in `customScripts.lua`

Once the script is installed, use tes3conv to produce a JSON file of each plugin used by your server and place these files in `data/custom/DFL_input`. They should be named the same as the equivalent ESM or ESP file.

The script can be configured by modifying `dataFilesLoader.config` in `dataFilesLoaderMain.lua`. There are currently two settings that can be changed:

* `parseOnServerStart` - If this is set to true, the function to generate the output JSON files will be run on each server start. Otherwise it must be run manually by another script. I don't recommend setting this to true.

* `recordTypesToRead` - This is a list of record types for which to generate output JSON files. Not all record types can currently be included, but the majority will be handled properly.

* `staticLoading` - This ensures that the JSON data is loaded into a lua table, making it quicker to access data. Turning this off saves memory, but increases the workload of the server. If you have the memory, make sure this is on.

### Important information for Linux Users

Lua, unfortunately, has issues with memory allocation in Linux, and this will be apparent if you try installing **all** the record types. 

To remedy this, use the library proved here: https://github.com/Neopallium/mmap_lowmem

After installing the shared library, run `export LD_PRELOAD="/usr/lib/libmmap_lowmen.so" lua` before running tes3mp.

## Usage

Cell records have been divided into Interior and Exterior records due to their number and the size of each cell record. Use either "Interior" or "Exterior" in place of "Cell" when accessing cell records directly.

Individual records can also be accessed by the following functions:

* `dataFilesLoader.getItemRecord(id)` Returns the record of the inventory item matching the given id, or `nil` if none exists

* `dataFilesLoader.getRecord(nil, recordType)` Returns the table associated with the recordType, assuming that staticLoading is active.

* `dataFilesLoader.getRecord(id, recordType)` Returns the record with the given id and the type of `recordType`, or nil if none exists. 

## Contributors

Written by Vidi_Aquam and Oliver Rees

## License

MIT License

Copyright (c) 2022 Vidi_Aquam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
