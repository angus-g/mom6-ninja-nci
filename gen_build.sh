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
ld = mpif90
ar = ar

fflags = -fno-alias -auto -safe-cray-ptr -ftz -assume byterecl -i4 -r8 -nowarn -g
fflags_opt = $fflags -O2 -fp-model precise -qoverride-limits -xHost -traceback -flto
fflags_dbg = $fflags -O0 -check -check noarg_temp_created -check nopointer -warn -warn noerrors -traceback -assume nobuffered_io
cflags = -g -O2 -flto
ldflags = -fuse-ld=lld

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
