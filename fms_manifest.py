#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "PyYAML",
# ]
# ///

import argparse
import datetime
import os
import subprocess
import sys
import yaml

from contextlib import contextmanager
from pathlib import Path


@contextmanager
def pushd(new_dir):
    prev_dir = os.getcwd()
    os.chdir(new_dir)
    try:
        yield
    finally:
        os.chdir(prev_dir)


def file_information(library):
    if not library:
        return {}

    hash_res = subprocess.run(["sha256sum", library], capture_output=True, text=True)
    file_hash = hash_res.stdout.strip().split()[0]

    return {
        "exe": library,
        "sha256": file_hash,
    }


def git_information():
    # srcdir = ../../src -> Path("../../src")
    srcdir = Path(open("../config.ninja", "r").readline().split("=")[-1].strip())

    with pushd(srcdir / "FMS"):
        res = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
        )
        git_rev = res.stdout.strip()

        tag = subprocess.run(
            ["git", "tag", "--points-at", "HEAD"],
            capture_output=True,
            text=True,
        )
        git_tag = tag.stdout.strip()

    component = {
        "component": "FMS",
        "ref": git_rev,
    }
    if git_tag:
        component["tag"] = git_tag

    return {"git": [component]}


def module_information():
    modules_res = subprocess.run(
        "module list -t", shell=True, capture_output=True, text=True
    )
    modules = modules_res.stdout.strip().split("\n")[2:]

    return {"modules": modules}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="fms_manifest",
        description="Create a manifest description of the FMS library",
    )

    parser.add_argument("library", nargs="?", default=None, help="shared library file")
    parser.add_argument("-o", "--output", help="YAML file to store output (overwrites)")
    args = parser.parse_args()

    manifest_data = {
        "build-date": datetime.date.today(),
    }
    manifest_data.update(file_information(args.library))
    manifest_data.update(git_information())
    manifest_data.update(module_information())

    if args.output:
        outfile = Path(args.output)
        if outfile.exists():
            print("Output file exists, not overwriting")
            sys.exit(1)

        with open(outfile, "w") as f:
            yaml.dump(manifest_data, f)

    else:
        print(manifest_data)
