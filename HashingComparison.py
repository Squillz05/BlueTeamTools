#!/usr/bin/env python3

"""
Directory Snapshot Comparison Tool (Blue Team)

This script:
- Loads a previous snapshot (JSON)
- Detects snapshot format automatically
- Re-hashes a target directory
- Compares differences
- Prints results to console
- Saves a NEW snapshot file with appended comparison report

Output file format:
<OldSnapshotName>_<YYYYMMDD_HHMMSS>_ComparisonSnapshot.json

Usage:
("Usage: python3 compare.py <old_snapshot.json> <directory>")

⚠️ Safety:
- READ-ONLY: Does NOT modify any files
"""

import os
import hashlib
import json
import sys
from datetime import datetime


# -----------------------------
# Hashing Function
# -----------------------------
def compute_sha256(file_path, chunk_size=8192):
    sha256 = hashlib.sha256()

    try:
        with open(file_path, "rb") as f:
            while chunk := f.read(chunk_size):
                sha256.update(chunk)
        return sha256.hexdigest()

    except (PermissionError, FileNotFoundError) as e:
        print(f"[!] Skipping {file_path}: {e}")
        return None


# -----------------------------
# Directory Snapshot
# -----------------------------
def snapshot_directory(root_path):
    snapshot = {}

    for dirpath, dirnames, filenames in os.walk(root_path):
        for filename in filenames:
            full_path = os.path.abspath(os.path.join(dirpath, filename))
            file_hash = compute_sha256(full_path)

            if file_hash:
                snapshot[full_path] = file_hash

    return snapshot


# -----------------------------
# Load Previous Snapshot (FIXED)
# -----------------------------
def load_snapshot(file_path):
    try:
        with open(file_path, "r") as f:
            data = json.load(f)

        # Case 1: Comparison snapshot format
        if isinstance(data, dict) and "snapshot" in data:
            print("[*] Detected comparison snapshot format. Extracting snapshot...")
            snapshot = data["snapshot"]

        else:
            snapshot = data

        # Safety check: ensure it's a valid mapping of path -> hash
        if not isinstance(snapshot, dict):
            raise ValueError("Snapshot is not a valid dictionary.")

        # Ensure values look like hashes (strings)
        cleaned_snapshot = {}
        for k, v in snapshot.items():
            if isinstance(k, str) and isinstance(v, str):
                cleaned_snapshot[k] = v
            else:
                print(f"[!] Skipping invalid entry in snapshot: {k}")

        return cleaned_snapshot

    except Exception as e:
        print(f"[!] Failed to load snapshot: {e}")
        sys.exit(1)


# -----------------------------
# Compare Snapshots
# -----------------------------
def compare_snapshots(old, new):
    old_files = set(old.keys())
    new_files = set(new.keys())

    added = sorted(list(new_files - old_files))
    removed = sorted(list(old_files - new_files))

    changed = []
    unchanged = []

    for file in old_files & new_files:
        if old[file] != new[file]:
            changed.append(file)
        else:
            unchanged.append(file)

    return sorted(added), sorted(removed), sorted(changed), sorted(unchanged)


# -----------------------------
# Generate Output Filename
# -----------------------------
def generate_output_filename(directory):
    folder_name = os.path.basename(os.path.abspath(directory))
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return f"{folder_name}_{timestamp}_Snapshot.json"

# -----------------------------
# Print Results
# -----------------------------
def print_results(added, removed, changed, unchanged):
    print("\n====== COMPARISON RESULTS ======\n")

    print(f"[+] New Files: {len(added)}")
    for f in added:
        print(f"    + {f}")

    print(f"\n[-] Missing Files: {len(removed)}")
    for f in removed:
        print(f"    - {f}")

    print(f"\n[*] Changed Files: {len(changed)}")
    for f in changed:
        print(f"    * {f}")

    print(f"\n[=] Unchanged Files: {len(unchanged)}")
    # Comment out below if too verbose
    for f in unchanged:
        print(f"    = {f}")


# -----------------------------
# Save Combined Output
# -----------------------------
def save_output(output_file, new_snapshot, report):
    try:
        combined = {
            "snapshot": new_snapshot,
            "comparison_report": report
        }

        with open(output_file, "w") as f:
            json.dump(combined, f, indent=4)

        print(f"\n[+] Comparison snapshot saved to: {output_file}")

    except Exception as e:
        print(f"[!] Failed to save output: {e}")


# -----------------------------
# Main
# -----------------------------
def main():
    if len(sys.argv) != 3:
        print("Usage: python3 compare.py <old_snapshot.json> <directory>")
        sys.exit(1)

    old_snapshot_file = sys.argv[1]
    directory = sys.argv[2]

    if not os.path.isfile(old_snapshot_file):
        print("[!] Invalid snapshot file.")
        sys.exit(1)

    if not os.path.isdir(directory):
        print("[!] Invalid directory.")
        sys.exit(1)

    print(f"[+] Loading snapshot: {old_snapshot_file}")
    old_snapshot = load_snapshot(old_snapshot_file)

    print(f"[+] Scanning current directory: {directory}")
    new_snapshot = snapshot_directory(directory)

    print(f"[+] Comparing snapshots...")
    added, removed, changed, unchanged = compare_snapshots(old_snapshot, new_snapshot)

    # Print results
    print_results(added, removed, changed, unchanged)

    # Build report
    report = {
        "new_files": added,
        "missing_files": removed,
        "changed_files": changed,
        "unchanged_files": unchanged,
        "summary": {
            "new": len(added),
            "missing": len(removed),
            "changed": len(changed),
            "unchanged": len(unchanged)
        }
    }

    # Save output
    output_file = generate_output_filename(old_snapshot_file)
    save_output(output_file, new_snapshot, report)


if __name__ == "__main__":
    main()
