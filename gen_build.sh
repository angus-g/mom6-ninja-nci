#!/bin/bash

srcdir=

if [[ -z "$srcdir" ]]; then
    printf "Set your source directory in gen_build.sh!\n"

    exit 1
fi

function gen_nfile() {
    nfile="\${srcdir}${1#$srcdir}"
}

function generate() {
    cat << EOF > config.ninja
srcdir = ${srcdir}
EOF

    cat << 'EOF' >> config.ninja
fc = mpif90
cc = mpicc
ld = mpifort
ar = ar

fflags = -g -fcray-pointer -fdefault-real-8 -fdefault-double-8
fflags_opt = $fflags -O2
fflags_dbg = $fflags -O0
cflags = -D__IFC -g

cppdefs = -Duse_libMPI -Duse_netCDF -DSPMD -DHAVE_GETTID
arflags = rv

rule fc
     command = $fc $fflags $cppdefs $incflags -c $in

rule cc
     command = $cc $cflags $cppdefs $incflags -c $in

rule link
     command = $ld $in -o $out $ldflags

rule archive
     command = $ar $arflags $out $in
EOF
}

if [ "$0" = "$BASH_SOURCE" ]; then
    generate
fi
