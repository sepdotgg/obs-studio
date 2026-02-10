# Maintainer: Custom Build
pkgname=obs-studio-custom
pkgver=32.0.2
pkgrel=4
pkgdesc="OBS Studio - patched build with replay-buffer-to-disk (no browser/CEF)"
arch=('x86_64')
url="https://obsproject.com"
license=('GPL-2.0-or-later')
depends=(
    'ffmpeg' 'jansson' 'libxinerama' 'libxkbcommon-x11' 'mbedtls' 'rnnoise'
    'pciutils' 'qt6-svg' 'curl' 'jack' 'gtk-update-icon-cache' 'pipewire'
    'libxcomposite' 'libdatachannel' 'uthash' 'simde' 'qrcodegencpp-cmake'
)
optdepends=(
    'libfdk-aac: FDK AAC codec support'
    'libva-intel-driver: hardware encoding'
    'libva-mesa-driver: hardware encoding'
    'luajit: scripting support'
    'python: scripting support'
    'sndio: Sndio input client'
    'v4l2loopback-dkms: virtual camera support'
)
makedepends=(
    'cmake' 'libfdk-aac' 'x264' 'swig' 'python' 'luajit' 'sndio' 'nlohmann-json'
    'ffnvcodec-headers' 'websocketpp' 'asio' 'extra-cmake-modules' 'git'
)
provides=('obs-studio')
conflicts=('obs-studio')

# Use local source already in container, but fetch the official Arch patch
source=(obs-studio-12328.patch::https://github.com/obsproject/obs-studio/pull/12328.patch)
sha256sums=('25322c692cf5cc88fc7d17cbb40a61b7e32d5ea675da647dd1a1996474ec2c8e')

prepare() {
    # Link the pre-copied source
    ln -sf /build/obs-studio-src "$srcdir/obs-studio"
    cd "$srcdir/obs-studio"
    git submodule update --init --recursive
    # Apply the same patch as official Arch package
    patch -Np1 -i "$srcdir"/obs-studio-12328.patch
}

build() {
    export CXXFLAGS+=" -Wno-error=deprecated-declarations"
    cmake -S obs-studio -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DENABLE_BROWSER=OFF \
        -DENABLE_VST=ON \
        -DENABLE_VLC=OFF \
        -DENABLE_NEW_MPEGTS_OUTPUT=OFF \
        -DENABLE_AJA=OFF \
        -DENABLE_JACK=ON \
        -DENABLE_LIBFDK=ON \
        -DENABLE_WEBRTC=ON \
        -DOBS_VERSION_OVERRIDE="$pkgver" \
        -DCALM_DEPRECATION=ON \
        -DENABLE_WEBSOCKET=ON \
        -Wno-dev
    cmake --build build --parallel
}

package() {
    DESTDIR="$pkgdir" cmake --install build
}
