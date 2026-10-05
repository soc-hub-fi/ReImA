#!/usr/bin/env python3
"""
Score tb_iap_core's captured output_file.yuv against the bit-exact
reference YUV produced by mosaic_to_raw.py.

output_file.yuv layout (see src/tb/tb_iap_core_pkg.sv: empty_queues() /
mon_port_req(), and the PTR0..PTR5 address map in tb_iap_core.sv):
    frame0: Y plane (H*W bytes), U plane (H/2 * W/2 bytes), V plane (same)
    frame1: Y plane, U plane, V plane   (second AXI buffer / PTR3..PTR5)
i.e. two back-to-back I420 frames, matching the two send_frame() calls in
the PIC_TEST block and the two 1.5*W*H-byte golden_file.yuv size.

Because the exact row parity used when the AXI/memory-write path decimates
4:2:2 chroma down to 4:2:0 (every other LINE, not just every other column)
hasn't been independently confirmed from the RTL, this script tries both
parities per frame and reports whichever gives the higher PSNR -- the
correct parity should win by a wide margin if the pipeline is otherwise
behaving, so this also doubles as a sanity check on that assumption.

Usage:
    python3 score_yuv420.py output_file.yuv REF_PREFIX --width 512 --height 512
"""
import argparse
import numpy as np
from skimage.metrics import peak_signal_noise_ratio as psnr
from skimage.metrics import structural_similarity as ssim


def read_i420_frames(path, w, h):
    y_size = w * h
    c_size = (w // 2) * (h // 2)
    frame_size = y_size + 2 * c_size
    data = np.fromfile(path, dtype=np.uint8)
    n_frames = data.size // frame_size
    frames = []
    for i in range(n_frames):
        base = i * frame_size
        y = data[base: base + y_size].reshape(h, w)
        u = data[base + y_size: base + y_size + c_size].reshape(h // 2, w // 2)
        v = data[base + y_size + c_size: base + frame_size].reshape(h // 2, w // 2)
        frames.append((y, u, v))
    leftover = data.size - n_frames * frame_size
    return frames, leftover, frame_size


def downsample_chroma(full_res, row_parity):
    """full_res: (H, W) uint8, already constant across each column-pair.
    Returns (H/2, W/2) by taking every other row (given parity) and every
    other column (offset 0 -- value is identical across the pair)."""
    return full_res[row_parity::2, 0::2]


def score_channel(ref, out, name):
    p = psnr(ref, out, data_range=255)
    s = ssim(ref, out, data_range=255)
    print(f"    {name}: PSNR={p:.2f} dB  SSIM={s:.4f}")
    return p, s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("output_yuv")
    ap.add_argument("ref_prefix")
    ap.add_argument("--width", type=int, default=512)
    ap.add_argument("--height", type=int, default=512)
    args = ap.parse_args()

    w, h = args.width, args.height
    frames, leftover, frame_size = read_i420_frames(args.output_yuv, w, h)
    print(f"Found {len(frames)} frame(s) in {args.output_yuv} "
          f"({frame_size} bytes/frame, {leftover} leftover bytes)")

    ref_y = np.load(args.ref_prefix + "_y.npy")
    ref_u_full = np.load(args.ref_prefix + "_u_full.npy")
    ref_v_full = np.load(args.ref_prefix + "_v_full.npy")

    results = []
    for i, (y, u, v) in enumerate(frames):
        print(f"\nFrame {i}:")
        py, sy = score_channel(ref_y, y, "Y")

        best = None
        for parity in (0, 1):
            ref_u = downsample_chroma(ref_u_full, parity)
            ref_v = downsample_chroma(ref_v_full, parity)
            pu = psnr(ref_u, u, data_range=255)
            pv = psnr(ref_v, v, data_range=255)
            if best is None or (pu + pv) > (best[1] + best[2]):
                best = (parity, pu, pv, ref_u, ref_v)
        parity, pu, pv, ref_u, ref_v = best
        su = ssim(ref_u, u, data_range=255)
        sv = ssim(ref_v, v, data_range=255)
        print(f"    U (row_parity={parity}): PSNR={pu:.2f} dB  SSIM={su:.4f}")
        print(f"    V (row_parity={parity}): PSNR={pv:.2f} dB  SSIM={sv:.4f}")

        results.append({"Y": (py, sy), "U": (pu, su), "V": (pv, sv)})

    if results:
        for ch in ("Y", "U", "V"):
            mean_p = np.mean([r[ch][0] for r in results])
            mean_s = np.mean([r[ch][1] for r in results])
            print(f"\nMean {ch} over {len(results)} frame(s): "
                  f"PSNR={mean_p:.2f} dB  SSIM={mean_s:.4f}")


if __name__ == "__main__":
    main()
