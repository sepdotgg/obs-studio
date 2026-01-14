#!/bin/bash
set -e

echo "Creating dist directories..."
mkdir -p dist/bin/bin/linux
mkdir -p dist/bin/obs-plugins/linux
mkdir -p dist/bin/data/obs-plugins
mkdir -p dist/artifacts
mkdir -p dist/tmp/lib

echo "Starting container to extract files..."
CONTAINER_ID=$(podman create obs-pkg)

echo "Extracting executables to dist/tmp/..."
podman cp "$CONTAINER_ID:/build/pkg/obs-studio-custom/usr/bin/." dist/tmp/

echo "Extracting main library .so files to dist/tmp/lib/..."
podman cp "$CONTAINER_ID:/build/pkg/obs-studio-custom/usr/lib/." dist/tmp/lib/

echo "Extracting plugin .so files to dist/bin/obs-plugins/linux/..."
podman cp "$CONTAINER_ID:/build/pkg/obs-studio-custom/usr/lib/obs-plugins/." dist/bin/obs-plugins/linux/

echo "Extracting plugin data files to dist/bin/data/obs-plugins/..."
podman cp "$CONTAINER_ID:/build/pkg/obs-studio-custom/usr/share/obs/obs-plugins/." dist/bin/data/obs-plugins/

echo "Extracting all build artifacts to dist/artifacts/..."
podman cp "$CONTAINER_ID:/build/pkg/obs-studio-custom/usr/." dist/artifacts/

echo "Cleaning up container..."
podman rm "$CONTAINER_ID"

echo "Copying executables and libraries to final location..."
# Copy executables
cp dist/tmp/obs dist/bin/bin/linux/ 2>/dev/null || true
cp dist/tmp/obs-ffmpeg-mux dist/bin/bin/linux/ 2>/dev/null || true
cp dist/tmp/obs-nvenc-test dist/bin/bin/linux/ 2>/dev/null || true

# Copy only top-level .so files (not subdirectories)
find dist/tmp/lib -maxdepth 1 -type f -name "*.so*" -exec cp {} dist/bin/bin/linux/ \;
find dist/tmp/lib -maxdepth 1 -type l -name "*.so*" -exec cp -P {} dist/bin/bin/linux/ \;

echo "Cleaning up temporary directory..."
rm -rf dist/tmp

echo ""
echo "Extraction complete!"
echo ""
echo "Executables in dist/bin/bin/linux/:"
ls -lh dist/bin/bin/linux/obs* 2>/dev/null || echo "  (none found)"
echo ""
echo "Main libraries in dist/bin/bin/linux/:"
ls -lh dist/bin/bin/linux/*.so* 2>/dev/null | head -5 || echo "  (none found)"
echo ""
echo "Plugin .so files in dist/bin/obs-plugins/linux/:"
ls -lh dist/bin/obs-plugins/linux/*.so 2>/dev/null | head -10 || echo "  (none found)"
echo ""
echo "Plugin data directories in dist/bin/data/obs-plugins/:"
ls -d dist/bin/data/obs-plugins/*/ 2>/dev/null | head -5 || echo "  (none found)"
echo ""
echo "All artifacts extracted to dist/artifacts/"
du -sh dist/artifacts/
