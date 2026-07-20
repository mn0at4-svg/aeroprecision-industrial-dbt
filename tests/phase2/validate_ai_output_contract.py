"""Local-only structural checks for the Phase 2 AI output contract."""

import json
from pathlib import Path


RULES = {
    "customer_explanation": (40, 800),
    "internal_rationale": (40, 800),
    "negotiation_option": (30, 500),
    "risk_note": (30, 500),
}


def is_valid(payload):
    if not isinstance(payload, dict) or set(payload) != set(RULES):
        return False
    for field, (minimum, maximum) in RULES.items():
        value = payload[field]
        if not isinstance(value, str) or not minimum <= len(value.strip()) <= maximum:
            return False
    return True


def main():
    case_path = Path(__file__).with_name("ai-explanation-output-cases.json")
    cases = json.loads(case_path.read_text(encoding="utf-8"))
    for case in cases:
        actual = is_valid(case["payload"])
        if actual != case["expected"]:
            raise AssertionError(f"{case['id']}: expected {case['expected']}, got {actual}")
    print("PASS: Phase 2 AI output contract checks")


if __name__ == "__main__":
    main()
