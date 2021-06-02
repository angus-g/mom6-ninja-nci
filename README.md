# mom6-ninja-nci
Painless shell scripts to set up a ninja build of MOM6 on NCI with Intel compilers. As prerequisites, I recommend you have the latest `intel-compiler` module loaded, `netcdf`, and a modern version of OpenMPI (4.0.x).

## Setup
1. Clone https://github.com/NOAA-GFDL/MOM6-examples to your home directory
2. From within the `MOM6-examples` directory run `git submodule update --init --recursive` to fetch the rest of the components
3. (Optional) In `MOM6-examples/src/MOM6` and `MOM6-examples/src/FMS`, run `git checkout dev/gfdl` and `git checkout xanadu`, respectively to track the latest versions
4. Clone this repository (preferably on `/scratch`, as the directories will fill up with object files and executables)
5. Go inside `mom6-ninja-nci` directory and edit `./gen_build.sh` to point the `srcdir` variable to the `src` directory of MOM6-examples (e.g. `$HOME/MOM6-examples/src`)
6. Run `./gen_build.sh` to generate the overall config file for compiler flags (you may edit the `config.ninja` file afterwards to change these)
7. Make sure you have the [ninja](https://github.com/ninja-build/ninja/releases) executable somewhere in your `PATH`

## Building FMS
The `shared` subdirectory is to build the FMS library against which MOM6 is linked.

1. In `shared`, run `./gen_build.sh` to generate the build script
2. (Optional) Check `build.ninja` seems sensibly populated
3. *Build it!* Run `ninja`

## Building MOM6
The `ocean_only_symmetric` subdirectory contains configuration for the ocean only (i.e. no sea ice or other coupling), symmetric C-grid, dynamic memory version of the model. Build steps are identical to FMS:

1. In `ocean_only_symmetric`, run `./gen_build.sh` to generate the build script
2. (Optional) Check `build.ninja` seems sensibly populated
3. *Build it!* Run `ninja`

You now have a `MOM6` executable.

## Updating the source
Most of the time, you will only be tweaking MOM6 source, so only MOM6 itself needs to be rebuilt. In many cases, changes to the source won't change the dependency order, so you can just re-run `ninja`, which will recompile only what is necessary, as any build system would. If the dependency order is changed (usually from added `use` statements here and there), re-run `./gen_build.sh`.
