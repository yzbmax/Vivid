#!/usr/bin/env python3
import os
import shutil
import math

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILTER_DIR = os.path.join(ROOT, "entry/src/main/resources/rawfile/filters")
BACKUP_DIR = os.path.join(ROOT, "tools/filters_backup")

TARGET_SIZE = 16

RESAMPLE_FILES = [
    "Canopy.cube",
    "DuskTide.cube",
    "Fieldnote.cube",
    "Heartland.cube",
    "Lowsun.cube",
    "Matinee.cube",
    "Meridian.cube",
    "NightMarket.cube",
    "Postcard.cube",
    "Skylight.cube",
    "VEL_Film_Fade.cube",
    "VEL_Mono_Contrast.cube",
    "VEL_Moody_Blue.cube",
    "VEL_Vintage_Chrome.cube",
    "VEL_Warm_Film.cube",
    "VEL_Warm_Pastel.cube",
    "YT_Moody_Dark.cube",
]

def ensure_backup(files):
    os.makedirs(BACKUP_DIR, exist_ok=True)
    for fname in files:
        src = os.path.join(FILTER_DIR, fname)
        dst = os.path.join(BACKUP_DIR, fname)
        if not os.path.exists(dst):
            shutil.copy2(src, dst)
            print(f"Backed up {fname} -> {dst}")
        else:
            print(f"Backup already exists for {fname}")

def mix(c0, c1, t):
    return (
        c0[0] * (1.0 - t) + c1[0] * t,
        c0[1] * (1.0 - t) + c1[1] * t,
        c0[2] * (1.0 - t) + c1[2] * t,
    )

def resample_cube(fname):
    src = os.path.join(BACKUP_DIR, fname)
    with open(src, "r", encoding="utf-8") as f:
        lines = f.readlines()

    header_lines = []
    nodes = []
    source_size = None
    title = None

    for line in lines:
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if s.startswith("TITLE"):
            title = s
            continue
        if s.startswith("LUT_3D_SIZE"):
            parts = s.split()
            source_size = int(parts[1])
            continue
        if s.startswith("DOMAIN_"):
            continue
        
        parts = s.split()
        if len(parts) == 3:
            try:
                nodes.append((float(parts[0]), float(parts[1]), float(parts[2])))
            except ValueError:
                pass

    if source_size is None or len(nodes) != source_size ** 3:
        raise ValueError(f"Invalid cube {fname}: size={source_size}, nodes={len(nodes)}")

    def idx(r, g, b):
        return (b * source_size * source_size) + (g * source_size) + r

    s_max = float(source_size - 1)
    t_max = float(TARGET_SIZE - 1)

    new_nodes = []
    for b_idx in range(TARGET_SIZE):
        w = float(b_idx) / t_max
        z = w * s_max
        b0 = int(math.floor(z))
        b1 = min(b0 + 1, source_size - 1)
        tb = z - float(b0)

        for g_idx in range(TARGET_SIZE):
            v = float(g_idx) / t_max
            y = v * s_max
            g0 = int(math.floor(y))
            g1 = min(g0 + 1, source_size - 1)
            tg = y - float(g0)

            for r_idx in range(TARGET_SIZE):
                u = float(r_idx) / t_max
                x = u * s_max
                r0 = int(math.floor(x))
                r1 = min(r0 + 1, source_size - 1)
                tr = x - float(r0)

                c000 = nodes[idx(r0, g0, b0)]
                c100 = nodes[idx(r1, g0, b0)]
                c010 = nodes[idx(r0, g1, b0)]
                c110 = nodes[idx(r1, g1, b0)]
                c001 = nodes[idx(r0, g0, b1)]
                c101 = nodes[idx(r1, g0, b1)]
                c011 = nodes[idx(r0, g1, b1)]
                c111 = nodes[idx(r1, g1, b1)]

                x00 = mix(c000, c100, tr)
                x10 = mix(c010, c110, tr)
                x01 = mix(c001, c101, tr)
                x11 = mix(c011, c111, tr)

                y0 = mix(x00, x10, tg)
                y1 = mix(x01, x11, tg)

                res = mix(y0, y1, tb)
                new_nodes.append(res)

    out_path = os.path.join(FILTER_DIR, fname)
    with open(out_path, "w", encoding="utf-8") as out:
        if title:
            out.write(f"{title}\n")
        else:
            base_name = os.path.splitext(fname)[0]
            out.write(f"TITLE \"{base_name}\"\n")
        out.write(f"LUT_3D_SIZE {TARGET_SIZE}\n")
        for rgb in new_nodes:
            out.write(f"{rgb[0]:.6f} {rgb[1]:.6f} {rgb[2]:.6f}\n")

    orig_size = os.path.getsize(src)
    new_size = os.path.getsize(out_path)
    ratio = (1.0 - new_size / float(orig_size)) * 100
    print(f"Resampled {fname}: {orig_size / 1024:.1f}KB -> {new_size / 1024:.1f}KB (-{ratio:.1f}%)")

def main():
    print("Step 1: Backup original files...")
    ensure_backup(RESAMPLE_FILES)
    print("\nStep 2: Resampling to 16x16x16 standard grid...")
    for fname in RESAMPLE_FILES:
        resample_cube(fname)
    print("\nFinished all resampling!")

if __name__ == "__main__":
    main()
