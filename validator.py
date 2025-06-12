import os
import xml.etree.ElementTree as ET

# 🔄  Set the root folder you want to scan
ROOT = r"C:\Users\conch\OneDrive\Desktop\RW\RIMWORLD GA_MASTER\RimWorld-Irish-Gaeilge-\Core"

total_files = 0
bad_files   = []

for dirpath, _, filenames in os.walk(ROOT):
    for fname in filenames:
        if not fname.lower().endswith(".xml"):
            continue
        total_files += 1
        path = os.path.join(dirpath, fname)
        try:
            ET.parse(path)
        except ET.ParseError as err:
            bad_files.append((path, err))

print(f"\nScanned {total_files} XML files.")

if bad_files:
    print(f"❌  Malformed files: {len(bad_files)}\n")
    for p, err in bad_files:
        print(f"{p}\n  ↳ {err}\n")
else:
    print("✅  All XML files are well-formed!")
