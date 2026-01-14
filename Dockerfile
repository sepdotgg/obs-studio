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
    pciutils \
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

CMD ["bash"]
