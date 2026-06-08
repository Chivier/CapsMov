#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -d "/Applications/Karabiner-Elements.app" ]] &&
  [[ ! -d "/Library/Application Support/org.pqrs/Karabiner-Elements" ]]; then
  echo "skip: Karabiner-Elements is not installed"
  exit 0
fi

tmp_home="$(mktemp -d)"
trap 'rm -rf "${tmp_home}"' EXIT

mkdir -p "${tmp_home}/.config/karabiner"
cat >"${tmp_home}/.config/karabiner/karabiner.json" <<'JSON'
{
  "profiles": [
    {
      "name": "Default profile",
      "selected": true
    }
  ]
}
JSON

HOME="${tmp_home}" "${repo_root}/install-macos-karabiner.sh" \
  --fix-iqunix-zonex75 \
  --no-open >/dev/null

CONFIG_FILE="${tmp_home}/.config/karabiner/karabiner.json" python3 <<'PY'
import json
import os
from pathlib import Path

config = json.loads(Path(os.environ["CONFIG_FILE"]).read_text())
profile = next((item for item in config["profiles"] if item.get("selected")), config["profiles"][0])
rules = profile.get("complex_modifications", {}).get("rules", [])

rule = next(
    (
        item for item in rules
        if item.get("description") == "Normalize IQUNIX ZONEX75 right-side modifiers"
    ),
    None,
)
assert rule, "IQUNIX ZONEX75 modifier normalization rule should be enabled"

condition = [
    {
        "type": "device_if",
        "identifiers": [
            {
                "vendor_id": 12815,
                "product_id": 20754,
                "is_keyboard": True,
            }
        ],
    }
]


def manipulator_exists(from_value, to_value):
    for manipulator in rule.get("manipulators", []):
        if manipulator.get("from") != from_value:
            continue
        if manipulator.get("to") != [to_value]:
            continue
        if manipulator.get("conditions") != condition:
            continue
        return True
    return False


assert manipulator_exists(
    {
        "key_code": "right_command",
        "modifiers": {
            "optional": [
                "any",
            ],
        },
    },
    {"key_code": "right_option"},
), "physical Right Opt currently emitted as Right Command should become Right Option"

assert manipulator_exists(
    {
        "key_code": "right_option",
        "modifiers": {
            "optional": [
                "any",
            ],
        },
    },
    {"key_code": "right_control"},
), "physical Right Ctrl currently emitted as Right Option should become Right Control"

assert manipulator_exists(
    {
        "apple_vendor_top_case_key_code": "keyboard_fn",
        "modifiers": {
            "optional": [
                "any",
            ],
        },
    },
    {"key_code": "right_control"},
), "external keyboard_fn should act as Right Control so Fn+C can produce Control+C"
PY

echo "ok: IQUNIX ZONEX75 external keyboard modifiers are normalized"
