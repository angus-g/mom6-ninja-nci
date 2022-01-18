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

# srcdir = ../../src -> Path("../../src")
srcdir = Path(
    open("../config.ninja", "r")
    .readline()
    .split("=")[-1]
    .strip()
)

with pushd(str(srcdir / "FMS")):
    res = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True)
    git_rev = res.stdout.strip()

modules_res = subprocess.run("module list -t", shell=True, capture_output=True, text=True)
modules = modules_res.stdout.strip().split("\n")[2:]

hash_res = subprocess.run(["sha256sum", sys.argv[1]], capture_output=True, text=True)
file_hash = hash_res.stdout.strip().split()[0]

data = {
    "exe": sys.argv[1],
    "sha256": file_hash,
    "build-date": datetime.date.today(),
    "git": [
        {"component": "FMS", "ref": git_rev}
    ],
    "modules": modules,
}

with open(sys.argv[2], "w") as f:
    yaml.dump(data, f)
