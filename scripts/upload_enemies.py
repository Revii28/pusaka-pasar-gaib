#!/usr/bin/env python3
"""
Phase 8 — upload the 7 PROCEED setan FBX to Roblox Open Cloud as new Model
assets (POST /v1/assets). Reads ROBLOX_API_KEY + OWNER_USER_ID from .env
(gitignored). Does NOT write EnemyMeshIds.lua — wiring is a separate reviewed
step. Prints per-setan asset IDs + a RESULT_JSON line.

403 (moderation/permission) or 401 (bad/expired key) => STOP the batch (do not
hammer a moderated account).

USAGE (repo root):
    .venv\\Scripts\\python scripts\\upload_enemies.py --only Pocong   # gate test
    .venv\\Scripts\\python scripts\\upload_enemies.py                  # all 7 PROCEED

The 4 SKIP setan (Tuyul, SundelBolong, WeweGombel, BuddhaWraith) and Leak are
intentionally NOT uploaded (moderation audit: docs/asset_moderation_audit.md).
"""
import os
import sys
import json
import time
import argparse

import requests
from dotenv import load_dotenv

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_PATH = os.path.join(REPO, ".env")
ASSETS_DIR = os.path.join(REPO, "assets", "enemies")

PROCEED = ["Pocong", "Kuntilanak", "Genderuwo", "Banaspati", "ButoIjo", "SetanPasar", "NagaKomodo"]

ASSETS_ENDPOINT = "https://apis.roblox.com/assets/v1/assets"
OP_ENDPOINT = "https://apis.roblox.com/assets/v1/operations/{}"
RETRIES = 3
POLL_INTERVAL = 2
POLL_TIMEOUT = 90
SLEEP_BETWEEN = 3


def log(m):
    print(m, flush=True)


def load_creds():
    load_dotenv(ENV_PATH)
    key = os.environ.get("ROBLOX_API_KEY")
    uid = os.environ.get("OWNER_USER_ID")
    if not key or not uid:
        log("ERROR: ROBLOX_API_KEY / OWNER_USER_ID missing in .env")
        sys.exit(2)
    log(f"creds loaded (key ...{key[-4:]}, userId {uid})")
    return key, uid


def upload_one(name, key, uid):
    fbx = os.path.join(ASSETS_DIR, name + ".fbx")
    if not os.path.exists(fbx):
        return None, "MISSING_FBX", fbx
    with open(fbx, "rb") as f:
        data = f.read()
    req = {
        "assetType": "Model",
        "displayName": f"{name}Mesh",
        "description": f"PUSAKA Pasar Gaib - {name} realistic Sketchfab asset",
        "creationContext": {"creator": {"userId": str(uid)}},
    }
    for attempt in range(1, RETRIES + 1):
        files = {
            "request": (None, json.dumps(req), "application/json"),
            "fileContent": (name + ".fbx", data, "model/fbx"),
        }
        try:
            r = requests.post(ASSETS_ENDPOINT, headers={"x-api-key": key}, files=files, timeout=180)
        except Exception as e:
            log(f"  [{name}] attempt {attempt} exception: {e!r}")
            time.sleep(2 ** attempt)
            continue
        if r.status_code == 403:
            return None, "FORBIDDEN_403", r.text[:400]
        if r.status_code == 401:
            return None, "UNAUTHORIZED_401", r.text[:400]
        if r.status_code == 429 or r.status_code >= 500:
            log(f"  [{name}] HTTP {r.status_code}, backoff {2 ** attempt}s")
            time.sleep(2 ** attempt)
            continue
        if r.status_code not in (200, 201):
            return None, f"HTTP_{r.status_code}", r.text[:400]
        op = r.json()
        op_id = op.get("path", "").split("/")[-1] or op.get("operationId")
        if not op_id:
            aid = (op.get("response") or {}).get("assetId")
            return (aid, "OK", None) if aid else (None, "NO_OP", json.dumps(op)[:300])
        deadline = time.time() + POLL_TIMEOUT
        while time.time() < deadline:
            time.sleep(POLL_INTERVAL)
            try:
                pr = requests.get(OP_ENDPOINT.format(op_id), headers={"x-api-key": key}, timeout=20)
            except Exception:
                continue
            if pr.status_code != 200:
                continue
            pj = pr.json()
            if pj.get("done"):
                aid = (pj.get("response") or {}).get("assetId")
                return (aid, "OK", None) if aid else (None, "DONE_NO_ID", json.dumps(pj)[:300])
        return None, "POLL_TIMEOUT", f"{POLL_TIMEOUT}s"
    return None, "RETRY_EXHAUSTED", None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", metavar="NAME", help="upload a single PROCEED setan")
    args = ap.parse_args()
    if args.only and args.only not in PROCEED:
        log(f"ERROR: '{args.only}' not in PROCEED {PROCEED}")
        sys.exit(2)

    key, uid = load_creds()
    targets = [args.only] if args.only else list(PROCEED)
    ids = {}
    stopped = None
    for name in targets:
        log(f"[{name}] uploading {name}.fbx ...")
        aid, status, detail = upload_one(name, key, uid)
        if status == "OK":
            ids[name] = aid
            log(f"[{name}] OK asset_id={aid}")
        else:
            log(f"[{name}] FAIL status={status} detail={detail}")
            if status in ("FORBIDDEN_403", "UNAUTHORIZED_401"):
                log(f"STOP_SIGNAL {status}: aborting batch (do not hammer).")
                stopped = status
                break
        if not args.only:
            time.sleep(SLEEP_BETWEEN)
    log("RESULT_JSON=" + json.dumps({"ids": ids, "stopped": stopped}))


if __name__ == "__main__":
    main()
