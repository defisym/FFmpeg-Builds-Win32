#!/bin/bash

set -x
echo "=== ENV ==="
env | sort

echo "=== Check /opt/ffbuild top-level ==="
ls -la /opt || true
ls -la /opt/ffbuild || true
ls -la /opt/ffbuild/lib || true
ls -la /opt/ffbuild/include || true
ls -la /opt/ffbuild/lib/pkgconfig || true

echo "=== pkg-config (host and cross) ==="
which pkg-config || true
which i686-w64-mingw32-pkg-config || true
PKG_CONFIG_PATH=/opt/ffbuild/lib/pkgconfig pkg-config --modversion zlib || true
PKG_CONFIG_PATH=/opt/ffbuild/lib/pkgconfig pkg-config --cflags zlib || true

echo "=== lib files (file output shows arch) ==="
for f in /opt/ffbuild/lib/libz* /opt/ffbuild/lib/libfftw3* /opt/ffbuild/lib/lib*.a; do
  [ -e "$f" ] && file "$f" || true
done

echo "=== pkgconfig files content (if present) ==="
for pc in /opt/ffbuild/lib/pkgconfig/*.pc; do
  echo "== $pc =="; [ -e "$pc" ] && sed -n '1,120p' "$pc" || true
done

SCRIPT_REPO="https://github.com/acoustid/chromaprint.git"
SCRIPT_COMMIT="ac31acc8431defbb134ec54eb11daf9146c74170"

ffbuild_depends() {
    echo base
    echo fftw3
}

ffbuild_enabled() {
    # pkg-config check is currently only available in master
    [[ $ADDINS_STR == *4.4* ]] && return -1
    [[ $ADDINS_STR == *5.0* ]] && return -1
    [[ $ADDINS_STR == *5.1* ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" -DBUILD_SHARED_LIBS=OFF -DBUILD_TOOLS=OFF -DBUILD_TESTS=OFF -DFFT_LIB=fftw3 ..
    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"

    echo "Libs.private: -lfftw3 -lstdc++" >> "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libchromaprint.pc
    echo "Cflags.private: -DCHROMAPRINT_NODLL" >> "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libchromaprint.pc
}

ffbuild_configure() {
    echo --enable-chromaprint
}

ffbuild_unconfigure() {
    echo --disable-chromaprint
}
