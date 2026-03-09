#!/bin/bash
# BlackRoad 3D Printing Workflow
# SCAD → STL → gcode → OctoPrint → Print
#
# Usage: ./print-scad-workflow.sh <scad_file> [output_name]

set -e

# Configuration
OCTOPRINT_HOST="192.168.4.38:5000"
OCTOPRINT_API_KEY="8MZXHgIvhu8elaHDaELTZQUbT9ti7cGhvbAwl-Dby0A"
OPENSCAD_BIN="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
CURA_ENGINE="/Applications/UltiMaker-Cura.app/Contents/MacOS/CuraEngine"

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <scad_file> [output_name]"
    echo "Example: $0 structural_tube.scad my_tube"
    exit 1
fi

SCAD_FILE="$1"
OUTPUT_NAME="${2:-$(basename "$SCAD_FILE" .scad)}"
WORK_DIR="/tmp/3dprint-$$"

# Check if SCAD file exists
if [ ! -f "$SCAD_FILE" ]; then
    echo "Error: SCAD file not found: $SCAD_FILE"
    exit 1
fi

echo "========================================="
echo "BlackRoad 3D Printing Workflow"
echo "========================================="
echo "Input:  $SCAD_FILE"
echo "Output: $OUTPUT_NAME"
echo ""

# Create work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Copy SCAD file and dependencies
echo "[1/5] Copying SCAD files..."
cp "$SCAD_FILE" "$WORK_DIR/"
SCAD_DIR=$(dirname "$SCAD_FILE")
if [ -f "$SCAD_DIR/common.scad" ]; then
    cp "$SCAD_DIR/common.scad" "$WORK_DIR/"
fi

# Step 1: Render SCAD → STL
echo "[2/5] Rendering SCAD to STL..."
STL_FILE="$WORK_DIR/${OUTPUT_NAME}.stl"
"$OPENSCAD_BIN" -o "$STL_FILE" "$(basename "$SCAD_FILE")" 2>&1 | grep -v "WARNING" || true

if [ ! -f "$STL_FILE" ]; then
    echo "Error: STL file not generated"
    exit 1
fi

STL_SIZE=$(ls -lh "$STL_FILE" | awk '{print $5}')
echo "✓ STL generated: $STL_SIZE"

# Step 2: Slice STL → gcode (using CuraEngine or fallback to web slicer)
echo "[3/5] Slicing STL to gcode..."
GCODE_FILE="$WORK_DIR/${OUTPUT_NAME}.gcode"

if [ -f "$CURA_ENGINE" ]; then
    # Use CuraEngine CLI (requires profile setup)
    echo "Using CuraEngine..."
    # TODO: Add CuraEngine command with Ender 3 profile
    echo "Note: CuraEngine requires profile configuration"
    echo "Skipping to manual slice step..."
else
    echo "CuraEngine not found at: $CURA_ENGINE"
fi

# If gcode doesn't exist, provide instructions
if [ ! -f "$GCODE_FILE" ]; then
    echo ""
    echo "========================================="
    echo "MANUAL SLICE REQUIRED"
    echo "========================================="
    echo "1. Open Cura"
    echo "2. Drag this file: $STL_FILE"
    echo "3. Select: Creality Ender 3"
    echo "4. Click 'Slice'"
    echo "5. Save as: $GCODE_FILE"
    echo ""
    echo "Press ENTER when gcode file is ready..."
    read -r
fi

if [ ! -f "$GCODE_FILE" ]; then
    echo "Error: gcode file not found: $GCODE_FILE"
    exit 1
fi

GCODE_SIZE=$(ls -lh "$GCODE_FILE" | awk '{print $5}')
echo "✓ gcode generated: $GCODE_SIZE"

# Step 3: Upload to OctoPrint
echo "[4/5] Uploading to OctoPrint..."
UPLOAD_RESPONSE=$(curl -s -H "X-Api-Key: $OCTOPRINT_API_KEY" \
    -F "file=@$GCODE_FILE" \
    "http://$OCTOPRINT_HOST/api/files/local")

if echo "$UPLOAD_RESPONSE" | grep -q "\"done\":true"; then
    echo "✓ Uploaded to OctoPrint"
else
    echo "Error uploading to OctoPrint:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi

# Step 4: Start print
echo "[5/5] Starting print..."
START_RESPONSE=$(curl -s -H "X-Api-Key: $OCTOPRINT_API_KEY" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{\"command\":\"select\",\"print\":true}" \
    "http://$OCTOPRINT_HOST/api/files/local/${OUTPUT_NAME}.gcode")

# Check print status
sleep 2
STATUS=$(curl -s -H "X-Api-Key: $OCTOPRINT_API_KEY" \
    "http://$OCTOPRINT_HOST/api/job" | grep -o '"state":"[^"]*"' | cut -d'"' -f4)

echo ""
echo "========================================="
echo "Print Status: $STATUS"
echo "========================================="
echo "Monitor at: http://$OCTOPRINT_HOST"
echo ""
echo "Files saved in: $WORK_DIR"
echo "  - STL: $STL_FILE"
echo "  - gcode: $GCODE_FILE"
echo ""

# Cleanup option
echo "Keep work files? (y/n)"
read -r KEEP
if [ "$KEEP" != "y" ]; then
    rm -rf "$WORK_DIR"
    echo "Work files deleted"
fi

echo "Done!"
