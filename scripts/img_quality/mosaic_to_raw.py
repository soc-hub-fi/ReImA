#!/usr/bin/env python3
"""
Mosaic a ground-truth RGB image into the Bayer RAW8 format consumed by
tb_iap_core (src/tb/dphy_rx_model.sv, send_line(), INPUT=="IMG" path), and
compute the bit-exact RGB->YUV444 reference using the same fixed-point
formula as src/ip/ipu_color_conversion.sv, for later comparison against the
simulator's captured output_file.yuv.

Usage:
    python3 mosaic_to_raw.py INPUT_IMAGE OUT_PREFIX --width 512 --height 512 \
        --pattern RGGB

Outputs (under OUT_PREFIX):
    <prefix>.raw        Bayer RAW8 frame, repeated twice back-to-back
                         (tb_iap_core's PIC_TEST block calls send_frame()
                         twice against the same open file handle).
    <prefix>_y.npy       Full-resolution reference Y plane  (H x W, uint8)
    <prefix>_u_full.npy  Full-resolution reference U plane  (H x W, uint8)
    <prefix>_v_full.npy  Full-resolution reference V plane  (H x W, uint8)
    <prefix>_rgb.png     The exact cropped/resized ground-truth RGB used
                         (for visual sanity checking)

The U/V full-resolution planes are the hardware's "calculate UV for even
pixels only" result broadcast across the pixel pair (i.e. odd column j+1
reuses the U/V computed from column j), matching ipu_color_conversion.sv's
per-pixel-pair chroma subsampling *before* any further line-level 4:2:0
decimation that happens in the AXI write path. The scorer
(score_yuv420.py) handles the final horizontal+vertical decimation to
match the I420 planes actually captured from simulation, searching both
row parities since the exact row selected by the hardware's memory-write
path hasn't been independently confirmed yet.
"""
import argparse
import numpy as np
from PIL import Image

PATTERNS = {
    # 2x2 tile, indexed [row%2][col%2] -> 'R'/'G'/'B'
    "RGGB": [["R", "G"], ["G", "B"]],
    "BGGR": [["B", "G"], ["G", "R"]],
    "GRBG": [["G", "R"], ["B", "G"]],
    "GBRG": [["G", "B"], ["R", "G"]],
}


def mosaic(rgb: np.ndarray, pattern: str) -> np.ndarray:
    """rgb: (H, W, 3) uint8 -> (H, W) uint8 Bayer mosaic."""
    h, w, _ = rgb.shape
    tile = PATTERNS[pattern]
    out = np.zeros((h, w), dtype=np.uint8)
    chan_idx = {"R": 0, "G": 1, "B": 2}
    for r in range(2):
        for c in range(2):
            ch = chan_idx[tile[r][c]]
            out[r::2, c::2] = rgb[r::2, c::2, ch]
    return out


def rgb_to_yuv_hw(rgb: np.ndarray):
    """Bit-exact port of ipu_color_conversion.sv's fixed-point formula.

    Y computed per pixel. U/V computed only for even columns (per the
    RTL's `for (i = 0; i < 4; i += 2)` chroma loop) and broadcast to the
    following odd column, matching the hardware's YUYV-style horizontal
    4:2:2 chroma reuse prior to any further vertical/horizontal decimation
    performed downstream when writing to the I420 frame buffer.
    """
    r = rgb[:, :, 0].astype(np.int64)
    g = rgb[:, :, 1].astype(np.int64)
    b = rgb[:, :, 2].astype(np.int64)

    y = ((77 * r + 150 * g + 29 * b + 128) >> 8) & 0xFF

    # U = (((B*127 + 128) - (43R + 84G)) >> 8) + 128   (8-bit wraparound)
    u_full = (((b * 127 + 128) - (43 * r + 84 * g)) >> 8) & 0xFF
    u_full = (u_full + 128) & 0xFF

    # V = (((R*127 + 128) - (106G + 21B)) >> 8) + 128  (8-bit wraparound)
    v_full = (((r * 127 + 128) - (106 * g + 21 * b)) >> 8) & 0xFF
    v_full = (v_full + 128) & 0xFF

    # Broadcast even-column chroma to the following odd column (YUYV reuse)
    u_pairwise = u_full.copy()
    v_pairwise = v_full.copy()
    u_pairwise[:, 1::2] = u_full[:, 0::2]
    v_pairwise[:, 1::2] = v_full[:, 0::2]

    return y.astype(np.uint8), u_pairwise.astype(np.uint8), v_pairwise.astype(np.uint8)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input_image")
    ap.add_argument("out_prefix")
    ap.add_argument("--width", type=int, default=512)
    ap.add_argument("--height", type=int, default=512)
    ap.add_argument("--pattern", choices=PATTERNS.keys(), default="RGGB")
    args = ap.parse_args()

    img = Image.open(args.input_image).convert("RGB")
    img = img.resize((args.width, args.height), Image.LANCZOS)
    rgb = np.array(img, dtype=np.uint8)

    img.save(args.out_prefix + "_rgb.png")

    bayer = mosaic(rgb, args.pattern)
    with open(args.out_prefix + ".raw", "wb") as f:
        f.write(bayer.tobytes())
        f.write(bayer.tobytes())  # two frames back-to-back, see docstring

    y, u, v = rgb_to_yuv_hw(rgb)
    np.save(args.out_prefix + "_y.npy", y)
    np.save(args.out_prefix + "_u_full.npy", u)
    np.save(args.out_prefix + "_v_full.npy", v)

    print(f"Wrote {args.out_prefix}.raw "
          f"({bayer.nbytes * 2} bytes, {args.width}x{args.height}, {args.pattern}, "
          f"2 frames)")
    print(f"Wrote {args.out_prefix}_{{y,u_full,v_full}}.npy reference planes")


if __name__ == "__main__":
    main()
