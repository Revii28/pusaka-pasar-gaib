#!/usr/bin/env python3
"""
Normalize 12 Sketchfab setan downloads into self-contained (embedded-texture)
FBX in assets/enemies/, replacing the primitive placeholders.

Runs Blender headless once per setan (scripts/_normalize_blender.py). Blender
cannot write into the Documents tree on this machine (Controlled Folder Access),
so the Blender side writes to a temp dir and this orchestrator moves the
results into assets/enemies/.

USAGE (repo root):
    .venv\\Scripts\\python scripts\\normalize_sketchfab.py
    .venv\\Scripts\\python scripts\\normalize_sketchfab.py --only Pocong
    .venv\\Scripts\\python scripts\\normalize_sketchfab.py --downloads "D:\\path\\sketchfab-downloads"

Per-setan failures are isolated (timeout / import error) — the batch continues.
"""
import os
import sys
import json
import shutil
import argparse
import tempfile
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(REPO, "assets", "enemies")
BLENDER_SIDE = os.path.join(REPO, "scripts", "_normalize_blender.py")
DOWNLOADS_DEFAULT = r"C:\Users\revir\Documents\sketchfab-downloads"
BLENDER = os.environ.get("BLENDER_PATH", r"C:\Program Files\Blender Foundation\Blender 4.5\blender.exe")
TMP_OUT = os.path.join(tempfile.gettempdir(), "pusaka_norm_out")
PER_SETAN_TIMEOUT = 360

ENEMIES = [
    "Pocong", "Kuntilanak", "Leak", "Genderuwo", "Tuyul", "SundelBolong",
    "Banaspati", "WeweGombel", "ButoIjo", "SetanPasar", "NagaKomodo", "BuddhaWraith",
]

MODEL_EXT_PRIORITY = (".fbx", ".glb", ".gltf", ".blend")


def find_model(folder):
    try:
        files = os.listdir(folder)
    except Exception:
        return None
    for ext in MODEL_EXT_PRIORITY:
        for f in files:
            if f.lower().endswith(ext):
                return os.path.join(folder, f)
    return None


def normalize_one(name, downloads):
    folder = os.path.join(downloads, name)
    if not os.path.isdir(folder):
        return {"name": name, "ok": False, "error": "download folder missing"}
    model = find_model(folder)
    if not model:
        return {"name": name, "ok": False, "error": "no model file (.fbx/.glb/.blend)"}
    os.makedirs(TMP_OUT, exist_ok=True)
    # clear stale temp outputs for this setan
    for suffix in (".fbx", "_preview.png"):
        p = os.path.join(TMP_OUT, name + suffix)
        if os.path.exists(p):
            os.remove(p)
    try:
        proc = subprocess.run(
            [BLENDER, "--background", "--python", BLENDER_SIDE, "--", name, model, folder, TMP_OUT],
            capture_output=True, text=True, timeout=PER_SETAN_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return {"name": name, "ok": False, "error": f"blender timeout {PER_SETAN_TIMEOUT}s"}

    result = None
    for line in proc.stdout.splitlines():
        if line.startswith("RESULT="):
            try:
                result = json.loads(line[len("RESULT="):])
            except Exception:
                pass
    if result is None:
        return {"name": name, "ok": False, "error": "no RESULT from blender",
                "stderr_tail": proc.stderr[-300:]}

    moved = []
    for suffix in (".fbx", "_preview.png"):
        src = os.path.join(TMP_OUT, name + suffix)
        if os.path.exists(src):
            dst = os.path.join(ASSETS, name + suffix)
            shutil.move(src, dst)
            moved.append(os.path.basename(dst))
    result["moved"] = moved
    result["ok"] = (name + ".fbx") in moved and "error" not in result
    return result


def main():
    ap = argparse.ArgumentParser(description="Normalize Sketchfab setan -> embedded FBX")
    ap.add_argument("--only", metavar="NAME", help="process a single setan")
    ap.add_argument("--downloads", default=DOWNLOADS_DEFAULT, help="sketchfab-downloads dir")
    args = ap.parse_args()

    if not os.path.exists(BLENDER):
        print(f"ERROR: blender not found at {BLENDER} (set BLENDER_PATH)")
        sys.exit(1)
    os.makedirs(ASSETS, exist_ok=True)

    targets = [args.only] if args.only else list(ENEMIES)
    if args.only and args.only not in ENEMIES:
        print(f"ERROR: unknown enemy '{args.only}'. Valid: {ENEMIES}")
        sys.exit(1)

    results = []
    ok_count = 0
    for name in targets:
        print(f"=== normalize {name} ===", flush=True)
        r = normalize_one(name, args.downloads)
        results.append(r)
        if r.get("ok"):
            ok_count += 1
        brief = {k: r.get(k) for k in ("ext", "tri_before", "tri_after", "images_with_data", "fbx_size", "error")}
        print(f"  {'OK' if r.get('ok') else 'FAIL'} {name}: {json.dumps(brief)}", flush=True)

    print(f"=== DONE: {ok_count}/{len(targets)} ok ===", flush=True)
    print("BATCH_SUMMARY=" + json.dumps(results))


if __name__ == "__main__":
    main()
