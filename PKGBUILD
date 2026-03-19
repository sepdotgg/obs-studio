# Maintainer: Custom Build
pkgname=obs-studio-custom
pkgver=32.1.0
pkgrel=1
pkgdesc="OBS Studio - custom build (no browser/CEF)"
arch=('x86_64')
url="https://obsproject.com"
license=('GPL-2.0-only')
depends=(
    'ffmpeg' 'jansson' 'libxinerama' 'libxkbcommon-x11' 'mbedtls' 'rnnoise'
    'pciutils' 'qt6-svg' 'curl' 'jack' 'gtk-update-icon-cache' 'pipewire'
    'libxcomposite' 'libdatachannel' 'uthash' 'simde' 'qrcodegencpp-cmake'
    'python'
)
optdepends=(
    'libfdk-aac: FDK AAC codec support'
    'libva-intel-driver: hardware encoding for older Intel GPUs'
    'intel-media-driver: hardware encoding for recent Intel GPUs'
    'libva-mesa-driver: hardware encoding'
    'luajit: scripting support'
    'sndio: Sndio input client'
    'v4l2loopback-dkms: virtual camera support'
    'xdg-desktop-portal-impl: Wayland window/screen capture'
)
makedepends=(
    'cmake' 'libfdk-aac' 'x264' 'swig' 'luajit' 'sndio' 'nlohmann-json'
    'ffnvcodec-headers' 'websocketpp' 'asio' 'extra-cmake-modules'
)
provides=('obs-studio')
conflicts=('obs-studio')

# Use local source already in container
source=()
sha256sums=()

prepare() {
    # Link the pre-copied source
    ln -sf /build/obs-studio-src "$srcdir/obs-studio"
    cd "$srcdir/obs-studio"
    git submodule update --init --recursive
}

build() {
    export CXXFLAGS+=" -Wno-error=deprecated-declarations"
    cmake -B build -S obs-studio \
        -DCMAKE_INSTALL_PREFIX="/usr" \
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
    cmake --build build
}

package() {
    DESTDIR="$pkgdir" cmake --install build
}
