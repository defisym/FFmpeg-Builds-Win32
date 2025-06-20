#!/bin/bash

# Source
SCRIPT_REPO="https://git.code.sf.net/p/mingw-w64/mingw-w64.git"
SCRIPT_COMMIT="b45abfec4e116b33620de597b99b1f0af3ab6a6a"

# Mirror
# SCRIPT_REPO="https://github.com/mingw-w64/mingw-w64.git"
# 11.0.0
# SCRIPT_COMMIT="f9500e2d85b9400c0982518663660a127e1dc61a"
# 11.0.1
# SCRIPT_COMMIT="c3e587c067a00a561899d49d3e63a659e38802ec"
# Later version has an issue in 6.x
# 12.0.0
# SCRIPT_COMMIT="819a6ec2ea87c19814b287e21d65e0dc7f05abba"
# Latest
# SCRIPT_COMMIT="8700091928df67b2ee69ec46ac6f2c369a3e8c21"

ffbuild_enabled() {
    [[ $TARGET == win* ]] || return -1
    return 0
}

ffbuild_dockerlayer() {
    [[ $TARGET == winarm* ]] && return 0
    to_df "COPY --link --from=${SELFLAYER} /opt/mingw/. /"
    to_df "COPY --link --from=${SELFLAYER} /opt/mingw/. /opt/mingw"
}

ffbuild_dockerfinal() {
    [[ $TARGET == winarm* ]] && return 0
    to_df "COPY --link --from=${PREVLAYER} /opt/mingw/. /"
}

ffbuild_dockerdl() {
    echo "retry-tool sh -c \"rm -rf mingw && git clone '$SCRIPT_REPO' mingw\" && cd mingw && git checkout \"$SCRIPT_COMMIT\""
}

ffbuild_dockerbuild() {
    [[ $TARGET == winarm* ]] && return 0

    if [[ -z "$COMPILER_SYSROOT" ]]; then
        COMPILER_SYSROOT="$(${CC} -print-sysroot)/usr/${FFBUILD_TOOLCHAIN}"
    fi

    unset CC CXX LD AR CPP LIBS CCAS
    unset CFLAGS CXXFLAGS LDFLAGS CPPFLAGS CCASFLAGS
    unset PKG_CONFIG_LIBDIR

    ###
    ### mingw-w64-headers
    ###
    (
        cd mingw-w64-headers

        local myconf=(
            --prefix="$COMPILER_SYSROOT"
            --host="$FFBUILD_TOOLCHAIN"
            --with-default-win32-winnt="0x601"
            --with-default-msvcrt=ucrt
            --enable-idl
            --enable-sdk=all
            --enable-secure-api
        )

        ./configure "${myconf[@]}"
        make -j$(nproc)
        make install DESTDIR="/opt/mingw"
    )

    cp -a /opt/mingw/. /

    ###
    ### mingw-w64-crt
    ###
    (
        cd mingw-w64-crt

        local myconf=(
            --prefix="$COMPILER_SYSROOT"
            --host="$FFBUILD_TOOLCHAIN"
            --with-default-msvcrt=ucrt
            --enable-wildcard
        )

        ./configure "${myconf[@]}"
        make -j$(nproc)
        make install DESTDIR="/opt/mingw"
    )

    cp -a /opt/mingw/. /

    ###
    ### mingw-w64-libraries/winpthreads
    ###
    (
        cd mingw-w64-libraries/winpthreads

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
    )
}

ffbuild_configure() {
    echo --disable-w32threads --enable-pthreads
}
