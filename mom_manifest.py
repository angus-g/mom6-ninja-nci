import argparse
import datetime
import os
import subprocess
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

parser = argparse.ArgumentParser(description="Generate MOM6 build manifest")
parser.add_argument("executable")
parser.add_argument("manifest")
parser.add_argument(
    "--srcdir",
    type=Path,
    help="the MOM6 source directory containing subcomponents"
)
parser.add_argument(
    "--fflags",
    help="flags for compiling Fortran files"
)
parser.add_argument(
    "--cflags",
    help="flags for compiling C files"
)
args = parser.parse_args()

component_revs = []
for component in ["MOM6", "SIS2", "FMS", "atmos_null", "coupler", "ice_param", "icebergs", "land_null"]:
    with pushd(str(args.srcdir / component)):
        res = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True)
        component_revs.append({"component": component, "ref": res.stdout.strip()})

modules_res = subprocess.run("module list -t", shell=True, capture_output=True, text=True)
modules = modules_res.stdout.strip().split("\n")[2:]

hash_res = subprocess.run(["sha256sum", args.executable], capture_output=True, text=True)
file_hash = hash_res.stdout.strip().split()[0]

data = {
    "exe": args.executable,
    "sha256": file_hash,
    "build-date": datetime.date.today(),
    "git": component_revs,
    "modules": modules,
    "fflags": args.fflags,
    "cflags": args.cflags,
}

with open(args.manifest, "w") as f:
    yaml.dump(data, f, sort_keys=False)
