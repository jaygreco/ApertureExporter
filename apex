#!/usr/bin/python3

# Copyright 2019 Martin Sivak
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import errno
import os.path
import pprint
import shutil
import unicodedata
import library
import xmp

parser = argparse.ArgumentParser(prog='apex', description='Aperture library exporter')
parser.add_argument('library', help='Path to Aperture library')
parser.add_argument('dest', help='Path to the output directory')
parser.add_argument('-s', '--symlink', action='store_true', help='Use symlinks')
parser.add_argument('-c', '--copy', action='store_true', help='Copy files to dest')
parser.add_argument('-l', '--list', action='store_true', help='Only list files/folders')
parser.add_argument('-f', '--folder', action='append', help='Only export this folder')
parser.add_argument('--skip-xmp', action='store_true', help='Don\'t generate XMP')
parser.add_argument('--skip-raw', action='store_true', help='Don\'t export RAW files')
parser.add_argument('--ignore-folder', action='append', help='Don\'t export this folder')
args = parser.parse_args()

# make folder names lowercase
args.ignore_folder = [f.lower() for f in args.ignore_folder] if args.ignore_folder else []
args.folder = [f.lower() for f in args.folder] if args.folder else []

def try_copy(src, dest):
    try:
        shutil.copyfile(src, dest)
    except Exception as e:
        print(e)

def try_hardlink(src, dest):
    try:
        os.link(src, dest)
    # Overwrite the link if it exists
    except OSError as e:
        if e.errno == errno.EEXIST:
            os.remove(dest)
            os.symlink(src, dest)
    except Exception as e:
        print(e)
        try_copy(src, dest)

def try_symlink(src, dest):
    try:
        os.symlink(src, dest)
    # Overwrite the link if it exists
    except OSError as e:
        if e.errno == errno.EEXIST:
            os.remove(dest)
            os.symlink(src, dest)
    except Exception as e:
        print(f"symlink error: {src} {dest}")
        print(e)
        try_none(src, dest)

def try_none(src, dest):
    pass

if args.copy:
    link_method = try_copy
elif args.symlink:
    link_method = try_symlink
else:
    link_method = try_hardlink

def process_folder(f, d, path):
    def is_raw(fname):
        RAW_EXTS = set([".cr2", ".raw", ".tif", ".tiff"])
        for ext in RAW_EXTS:
            if str(photo.filename).lower().endswith(ext):
                return True
        return False

    if f.name == "Projects":
        # Always process top-level projects folder
        pass
    elif args.folder and not f.name.lower() in args.folder:
        # Skip folder (not selected)
        print(f"Skipping folder: {f.name}")
        return
    elif f.name.lower() in args.ignore_folder:
        # Skip folder (ignored)
        print(f"Ignoring folder: {f.name}")
        return

    print((d * 2 * " ") + "- " + f.name)
    if not os.path.exists(path):
        os.makedirs(path)
        
    for photo in f.photos:
        if args.skip_raw:
            if is_raw(photo.filename):
                continue
        if args.list:
            # only list, don't copy
            print((d * 2 * " ") + f"  - {photo.filename}")
            continue
        dest = os.path.join(path, photo.filename)

        src = os.path.join(args.library, "Masters", photo.path)

        # At least on ext4 this was necessary when accessing data
        # copied from HFS+
        src = unicodedata.normalize("NFKC", src)

        try:
            link_method(src, dest)
        except FileNotFoundError as e:
            print(e)

        for idx, ver in enumerate(photo.versions):
            if not args.skip_xmp:
                xmp_content = xmp.generate_xmp_rating(photo.filename, ver.rating)
                xmp_fullpath = os.path.join(path, xmp.xmp_filename(photo.filename, idx))
                with open(xmp_fullpath, "w") as xmp_file:
                    xmp_file.write(xmp_content)

                metafile = xmp_fullpath + ".pprint.txt"
                with open(metafile, "w") as meta_file:
                    meta_file.write(pprint.pformat(ver.content))

            print((d * 2 * " ") + f"  - {photo.filename} [{idx}] " + "*" * photo.rating)

    for f0 in f.folders:
        process_folder(f0, d + 1, os.path.join(path, f0.name))

ap = library.ApertureLibrary(args.library)
process_folder(ap.all_projects(), 0, args.dest)

