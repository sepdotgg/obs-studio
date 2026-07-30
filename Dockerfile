FROM archlinux:latest

# Update system and install build dependencies
RUN pacman -Syu --noconfirm && pacman -S --noconfirm \
    # Build tools
    base-devel \
    cmake \
    ninja \
    git \
    extra-cmake-modules \
    # Core dependencies
    ffmpeg \
    jansson \
    curl \
    zlib \
    mbedtls \
    # Qt6
    qt6-base \
    qt6-svg \
    qt6-wayland \
    # Audio
    pulseaudio \
    pipewire \
    jack2 \
    alsa-lib \
    sndio \
    libfdk-aac \
    speexdsp \
    # Video
    libva \
    libdrm \
    x264 \
    vlc \
    libxcomposite \
    libxinerama \
    libxkbcommon-x11 \
    v4l-utils \
    ffnvcodec-headers \
    # Scripting
    luajit \
    python \
    swig \
    # Misc
    librist \
    srt \
    websocketpp \
    asio \
    nlohmann-json \
    qrencode \
    qrcodegencpp-cmake \
    freetype2 \
    rnnoise \
    libdatachannel \
    uthash \
    simde \
    && pacman -Scc --noconfirm

# Downgrade pciutils to 3.12 (Arch ships 3.15). Building against 3.15 records
# pci_fill_info@LIBPCI_3.15, which breaks SteamOS and other older distros.
ARG PCIUTILS_PKG=pciutils-3.12.0-1-x86_64.pkg.tar.zst
ARG PCIUTILS_SHA256=cd41ce7bb5597f50103e05400dcc3f7327c4dd77e4a8080cb7b710d99a0003f8
RUN curl -fsSLo "/tmp/$PCIUTILS_PKG" \
        "https://archive.archlinux.org/packages/p/pciutils/$PCIUTILS_PKG" \
    && echo "$PCIUTILS_SHA256  /tmp/$PCIUTILS_PKG" | sha256sum -c - \
    && pacman -U --noconfirm "/tmp/$PCIUTILS_PKG" \
    && rm "/tmp/$PCIUTILS_PKG" \
    && printf 'IgnorePkg = pciutils\n' >> /etc/pacman.conf \
    && pkg-config --modversion libpci | grep -qx '3.12.0'

WORKDIR /obs-studio

# Copy source
COPY . .

# Initialize submodules
RUN git submodule update --init --recursive

# Configure with CMake - disable CEF/browser
RUN cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_BROWSER=OFF \
    -DENABLE_VST=ON \
    -DENABLE_VLC=ON \
    -DENABLE_AJA=OFF \
    -DENABLE_JACK=ON \
    -DENABLE_PULSEAUDIO=ON \
    -DENABLE_PIPEWIRE=ON \
    -DENABLE_WAYLAND=ON \
    -DENABLE_LIBFDK=ON

# Build
RUN cmake --build build --parallel

# Guard against regressing to a newer libpci ABI.
RUN set -e; \
    found=0; \
    for f in $(find build -type f \( -name obs -o -name obs-ffmpeg.so \)); do \
      found=1; \
      if objdump -T "$f" | grep -qE 'LIBPCI_3\.(9|1[0-9])'; then \
        echo "FAIL: $f references a libpci version newer than LIBPCI_3.8"; \
        objdump -T "$f" | grep LIBPCI; \
        exit 1; \
      fi; \
    done; \
    test "$found" = 1 || { echo "FAIL: found no obs/obs-ffmpeg.so to check"; exit 1; }; \
    echo "OK: libpci symbol versions are <= LIBPCI_3.8"

CMD ["bash"]
