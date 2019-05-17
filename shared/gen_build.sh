#!/bin/bash

. ../gen_build.sh

# recursively expand globs
shopt -s globstar

cat << 'EOF' > build.ninja
include ../config.ninja

incflags = -I${srcdir}/FMS/include -I${srcdir}/FMS/mosaic -I${srcdir}/FMS/drifters -I${srcdir}/FMS/fms -I${srcdir}/FMS/mpp/include
fflags = $fflags_opt
EOF

# lists of source files
fsrc_files=(${srcdir}/FMS/**/*.[fF]90)
csrc_files=(${srcdir}/FMS/**/*.c)
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
    deps=$(sed -rn 's/^\s*use\s+(\w+).*/\1/ip' "$file" | uniq | tr '[:upper:]' '[:lower:]')
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
