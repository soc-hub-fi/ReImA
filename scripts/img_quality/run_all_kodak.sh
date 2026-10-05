#!/usr/bin/env bash
# Run all 24 Kodak images through tb_iap_core's PIC_TEST flow, saving each
# run's output_file.yuv under kodak_raws/<name>_output.yuv for later scoring.
# Run from the root directory (same place you'd run `make run_test`).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAWS="$SCRIPT_DIR/kodak_raws"
ROOT_DIR="$SCRIPT_DIR/../../"
IMG_OUT="$ROOT_DIR/src/tb/img_out/output_file.yuv"

for n in $(seq -w 1 24); do
    name="kodim${n}"
    echo "=== $name ==="
    cp "$RAWS/${name}.raw" "$SCRIPT_DIR/current.raw"
    (cd "$ROOT_DIR" && make run_test)
    cp "$IMG_OUT" "$RAWS/${name}_output.yuv"
done

echo "Done. Outputs saved as $RAWS/kodimNN_output.yuv"
