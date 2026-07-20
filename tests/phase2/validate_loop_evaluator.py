"""Local-only tests for the Phase 2 bounded-loop evaluator.

No LLM, network, BigQuery, n8n, credentials, or external operation is used.
"""

import json
from pathlib import Path


REQUIRED_MINIMUM_LENGTHS = {
    "customer_explanation": 40,
    "internal_rationale": 40,
    "negotiation_option": 30,
    "risk_note": 30,
}

SECURITY_MARKERS = (
    "ignore previous instructions",
    "system prompt",
    "api key",
    "oauth token",
    "approve the quote immediately",
)


def evaluate(draft, attempt):
    if attempt > 3:
        return "FAILED_CLOSED"
    if not isinstance(draft, dict):
        return "FAILED_CLOSED"

    combined = " ".join(str(value) for value in draft.values()).lower()
    if any(marker in combined for marker in SECURITY_MARKERS):
        return "FAILED_CLOSED"
    if "http://" in combined or "https://" in combined:
        return "FAILED_CLOSED"
    if any(ord(char) in (0x200B, 0x200C, 0x200D, 0x200E, 0x200F) for char in combined):
        return "FAILED_CLOSED"

    for field, minimum in REQUIRED_MINIMUM_LENGTHS.items():
        value = draft.get(field)
        if not isinstance(value, str):
            return "FAILED_CLOSED"
        if len(value.strip()) < minimum:
            return "REVISE"

    return "ACCEPT"


def main():
    scenario_path = Path(__file__).with_name("loop-evaluation-scenarios.json")
    scenarios = json.loads(scenario_path.read_text(encoding="utf-8"))

    for scenario in scenarios:
        actual = evaluate(scenario["draft"], scenario["attempt"])
        expected = scenario["expected"]
        if actual != expected:
            raise AssertionError(f"{scenario['id']}: expected {expected}, got {actual}")

    print("PASS: Phase 2 bounded-loop evaluator checks")


if __name__ == "__main__":
    main()
