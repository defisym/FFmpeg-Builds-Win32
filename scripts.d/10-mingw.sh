#!/bin/bash

# SCRIPT_REPO="https://git.code.sf.net/p/mingw-w64/mingw-w64.git"
# SCRIPT_COMMIT="14315e632e362c6925737ccdf62eb11af63e2ef6"
SCRIPT_REPO="https://github.com/mingw-w64/mingw-w64.git"
# 11.0.0
# SCRIPT_COMMIT="f9500e2d85b9400c0982518663660a127e1dc61a"
# 11.0.1
# SCRIPT_COMMIT="c3e587c067a00a561899d49d3e63a659e38802ec"
# Latest
SCRIPT_COMMIT="257321cea601182e515d4ba9e04309bc5152360c"

ffbuild_enabled() {
    [[ $TARGET == win* ]] || return -1
    return 0
}

ffbuild_dockerlayer() {
    [[ $TARGET == winarm* ]] && return 0
    to_df "COPY --from=${SELFLAYER} /opt/mingw/. /"
    to_df "COPY --from=${SELFLAYER} /opt/mingw/. /opt/mingw"
}

ffbuild_dockerfinal() {
    [[ $TARGET == winarm* ]] && return 0
    to_df "COPY --from=${PREVLAYER} /opt/mingw/. /"
}

ffbuild_dockerdl() {
    echo "retry-tool sh -c \"rm -rf mingw && git clone '$SCRIPT_REPO' mingw\" && cd mingw && git checkout \"$SCRIPT_COMMIT\""
}

ffbuild_dockerbuild() {
    [[ $TARGET == winarm* ]] && return 0

    cd mingw-w64-headers

    unset CFLAGS
    unset CXXFLAGS
    unset LDFLAGS
    unset PKG_CONFIG_LIBDIR

    if [[ -z "$COMPILER_SYSROOT" ]]; then
        COMPILER_SYSROOT="$(${CC} -print-sysroot)/usr/${FFBUILD_TOOLCHAIN}"
    fi

    local myconf=(
        --prefix="$COMPILER_SYSROOT"
        --host="$FFBUILD_TOOLCHAIN"
        --with-default-win32-winnt="0x601"
        --with-default-msvcrt=ucrt
        --enable-idl
    )

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install DESTDIR="/opt/mingw"

    cd ../mingw-w64-libraries/winpthreads

    local myconf=(
        --prefix="$COMPILER_SYSROOT"
        --host="$FFBUILD_TOOLCHAIN"
        --with-pic
        --disable-shared
        --enable-static
    )

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install DESTDIR="/opt/mingw"
}

ffbuild_configure() {
    echo --disable-w32threads --enable-pthreads
}
