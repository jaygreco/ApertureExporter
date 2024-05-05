# Aperture Exporter (apex)

Apple Aperture 3 is a no longer maintained product. I wanted to move to a fully opensource solution and still retain access to my Aperture libraries. Based on [MarSik/ApertureToDarktable](https://github.com/MarSik/ApertureToDarktable)

This tool takes an Aperture library and creates a parallel directory structure using symlinks and metadata files. The original Aperture library is not modified in any way.

## Requirements

- Python 3

## How to use this tool

```
./apex --help
usage: apex [-h] [-r] [-c] [--skip-xmp] [--skip-raw] [--ignore-folder IGNORE_FOLDER]
            library dest

Aperture library exporter

positional arguments:
  library               Path to Aperture library
  dest                  Path to the output directory

optional arguments:
  -h, --help            show this help message and exit
  -r, --relative        Use symlinks
  -c, --copy            Copy files to dest
  --skip-xmp            Don't generate XMP
  --skip-raw            Don't export RAW files
  --ignore-folder IGNORE_FOLDER
                        Don't export this folder
```

This will read the Aperture library <library> and create the directory with symlinks at `<dest>`.

## Licensing

Copyright 2019 Martin Sivak

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

