#!/usr/bin/env python3
"""
Adds new UI text to the ARB files. Santali gets the Hindi text as a
placeholder until translated. Run from the project root:

    python3 tools/merge_strings.py tools/v3_strings.json

Safe to run more than once; existing keys are updated.
"""
import json
import pathlib
import sys

if len(sys.argv) != 2:
    sys.exit(__doc__)
additions = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
l10n = pathlib.Path("lib/core/l10n")
if not l10n.exists():
    sys.exit("Run from the project root (lib/core/l10n not found).")

for code, source in (("en", "en"), ("hi", "hi"), ("sat", "hi")):
    path = l10n / f"app_{code}.arb"
    arb = json.loads(path.read_text(encoding="utf-8"))
    for key, value in additions[source].items():
        if key.startswith("@") and code != "en":
            continue  # placeholder metadata lives only in the English template
        arb[key] = value
    path.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"updated {path}")
