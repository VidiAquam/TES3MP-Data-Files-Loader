## TES3MP Data Files Loader

This project is a set of scripts for TES3MP 0.8 making use of the tes3conv tool by Greatness7 to allow TES3MP server scripts to have easy access to the data of the plugins used by the clients.

## Features and Usage

Currently, this script uses a set of plugins converted to JSON by tes3conv to create its own set of JSON files containing the data of configurable record types (e.g. Activator, NPC, or Creature) that can then be queried easily like any other JSON file.

In the future, there will be standard functions implemented to use this data for several common purposes, such as updating refnums in saved cells when a mod is updated and its refnums changed.

## Installation

tes3conv is required for providing input to the script: https://github.com/Greatness7/tes3conv
Installation instructions for the script: https://github.com/tes3mp-scripts/Tutorials
dataFilesLoaderMain.lua should be required in customScripts.lua

Once the script is installed, use tes3conv to produce a JSON file of each plugin used by your server and place these files in data/custom/DFL_input. They should be named the same as the equivalent ESM or ESP file.

The script can be configured by modifying dataFilesLoader.config in dataFilesLoaderMain.lua. There are currently two settings that can be changed:
parseOnServerStart - If this is set to true, the function to generate the output JSON files will be run on each server start. Otherwise it must be run manually by another script.
recordTypesToRead - This is a list of record types for which to generate output JSON files. Not all record types can currently be included, but the majority will be handled properly.

## Contributors

Written primarily by Vidi_Aquam
These scripts use the lua_string library by stein197 found here and included in this repo: https://github.com/stein197/lua-string

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
