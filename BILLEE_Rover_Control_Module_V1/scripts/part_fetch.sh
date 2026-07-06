#!/bin/bash
# Before running dont forget to source your kicad-venv that should have easyeda2kicad installed

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

easyeda2kicad --full --overwrite --project-relative --output "$PROJECT_ROOT/lib/PDB_LCSC" --lcsc_id C42411118 C2150178 C97521 C20625731 C7519 C165948 C7668 C465737 C581062 C122552 C34740774 C880333 C129490 C462617 C98732 C474881