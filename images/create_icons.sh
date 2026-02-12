#!/bin/bash

# macOS App Icon Generator
# Generates all required icon sizes from a single 1024x1024 PNG image

set -e  # Exit on error

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input-image.png> [output-name]"
    echo "Example: $0 my-icon.png MyAppIcon"
    echo ""
    echo "Input image should be 1024x1024 PNG for best results"
    exit 1
fi

INPUT_IMAGE="$1"
OUTPUT_NAME="${2:-AppIcon}"

# Check if input file exists
if [ ! -f "$INPUT_IMAGE" ]; then
    echo "Error: Input file '$INPUT_IMAGE' not found"
    exit 1
fi

# Check if input is a PNG
if [[ ! "$INPUT_IMAGE" =~ \.png$ ]]; then
    echo "Warning: Input file should be a PNG for best results"
fi

ICONSET="${OUTPUT_NAME}.iconset"

echo "Creating iconset folder: $ICONSET"
mkdir -p "$ICONSET"

echo "Generating icon sizes..."

# Generate all required sizes
sips -z 16 16     "$INPUT_IMAGE" --out "$ICONSET/icon_16x16.png"
sips -z 32 32     "$INPUT_IMAGE" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     "$INPUT_IMAGE" --out "$ICONSET/icon_32x32.png"
sips -z 64 64     "$INPUT_IMAGE" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   "$INPUT_IMAGE" --out "$ICONSET/icon_128x128.png"
sips -z 256 256   "$INPUT_IMAGE" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   "$INPUT_IMAGE" --out "$ICONSET/icon_256x256.png"
sips -z 512 512   "$INPUT_IMAGE" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   "$INPUT_IMAGE" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$INPUT_IMAGE" --out "$ICONSET/icon_512x512@2x.png"

echo "Converting to .icns format..."
iconutil -c icns "$ICONSET"

echo ""
echo "✓ Success! Created ${OUTPUT_NAME}.icns"
echo ""
echo "Next steps:"
echo "1. Open your Xcode project"
echo "2. Go to Assets.xcassets"
echo "3. Select AppIcon"
echo "4. Drag ${OUTPUT_NAME}.icns into the icon slot"
echo ""
echo "Optional: Keep the ${ICONSET} folder if you need individual PNG files"
echo "         Otherwise, you can delete it: rm -rf ${ICONSET}"
