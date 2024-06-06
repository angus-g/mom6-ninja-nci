#!/bin/bash

. ../gen_build.sh

# find include directories
inc_dirs=($(find -L ${srcdir}/FMS -type d -name 'include') "${srcdir}/FMS/constants" "${srcdir}/FMS/constants4" "${srcdir}/FMS/fms")
fdefs="-Duse_deprecated_io"

cat << EOF > build.ninja
include ../config.ninja

rule manifest
     command = python3 ../fms_manifest.py \$in \$out

incflags = $(printf -- "-I%s " "${inc_dirs[@]}")
fflags = \$fflags_opt $fdefs
EOF

# lists of source files
fsrc_files=($(find -L ${srcdir}/FMS -path ${srcdir}/FMS/test_fms -prune -o -iname '*.f90' -print))
csrc_files=($(find -L ${srcdir}/FMS -name '*.c'))
objs=()

# c file rules
for file in "${csrc_files[@]}"; do
    obj="$(basename "${file%.*}").o"
    objs+=("$obj")
    gen_nfile "$file"
    printf 'build %s: cc %s\n' "$obj" "$nfile" >> build.ninja
done

# build module provides for fortran files
declare -A modules products
for file in "${fsrc_files[@]}"; do
    provided=$(sed -rn '/\bprocedure\b/I! s/^\s*module\s+(\w+).*/\1/ip' "$file" | tr '[:upper:]' '[:lower:]')
    gen_nfile "$file"
    for m in $provided; do
	modules[$m]="$nfile"
	products[$file]+="${m}.mod "
    done
done

# fortran file rules
for file in "${fsrc_files[@]}"; do
    deps=$(gfortran -E $(printf -- "-I%s " "${inc_dirs[@]}") $fdefs "$file" 2>/dev/null | sed -rn 's/^\s*use\s+(\w+).*/\1/ip' | uniq | tr '[:upper:]' '[:lower:]')
    mods=()
    srcs=()
    gen_nfile "$file"

    for dep in $deps; do
	if [[ ! -z ${modules[$dep]} && ${modules[$dep]} != $nfile ]]; then
	    srcs+=("${modules[$dep]}")
	    mods+=("$(basename "${modules[$dep]%.*}").o")
	fi
    done

    obj="$(basename "${file%.*}").o"
    objs+=("$obj")

    printf 'build %s %s: fc %s' "$obj" "${products[$file]}" "$nfile" >> build.ninja

    # print source files and modules, if any
    printf '%s' "${srcs[@]+ | }" >> build.ninja
    printf '%s ' "${srcs[@]}" >> build.ninja
    printf '%s' "${mods[@]+ || }" >> build.ninja
    printf '%s ' "${mods[@]}" >> build.ninja
    printf '\n' >> build.ninja
done

printf 'build libfms.a: archive ' >> build.ninja
printf '%s ' "${objs[@]}" >> build.ninja
printf '\n' >> build.ninja
printf 'build manifest.yaml: manifest libfms.a\n' >> build.ninja
