"""Local-only deterministic calculation checks for Phase 2.

This test uses synthetic values only. It performs no network, BigQuery, n8n,
credential, file-write, or external-send operation.
"""

from decimal import Decimal, getcontext


getcontext().prec = 28
EPSILON = Decimal("0.000001")


def safe_divide(numerator: Decimal, denominator: Decimal):
    """Match BigQuery SAFE_DIVIDE for this numeric test: zero returns None."""
    if denominator == 0:
        return None
    return numerator / denominator


def calculate(raw_material, surcharge, labor_hours, labor_rate, quantity, cfo_margin, proposed_price):
    raw_material = Decimal(str(raw_material))
    surcharge = Decimal(str(surcharge))
    labor_hours = Decimal(str(labor_hours))
    labor_rate = Decimal(str(labor_rate))
    quantity = Decimal(str(quantity))
    cfo_margin = Decimal(str(cfo_margin))
    proposed_price = Decimal(str(proposed_price))

    material_cost = raw_material * (Decimal("1") + surcharge)
    labor_cost = labor_hours * labor_rate
    unit_cost = material_cost + labor_cost
    total_cost = unit_cost * quantity
    minimum_price = safe_divide(total_cost, Decimal("1") - cfo_margin)
    realized_margin = safe_divide(proposed_price - total_cost, proposed_price)

    return {
        "material_cost_usd": material_cost,
        "labor_cost_usd": labor_cost,
        "unit_cost_usd": unit_cost,
        "total_cost_usd": total_cost,
        "minimum_cfo_approved_price_usd": minimum_price,
        "realized_gross_margin_pct": realized_margin,
    }


def margin_compliant(realized_margin, cfo_margin):
    if realized_margin is None:
        return False
    return realized_margin >= Decimal(str(cfo_margin)) - EPSILON


def assert_equal(actual, expected, label):
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected}, got {actual}")


def test_standard_case():
    result = calculate(100, "0.08", 2, 50, 10, "0.25", "2773.333333333333333333333333")
    assert_equal(result["material_cost_usd"], Decimal("108.00"), "material cost")
    assert_equal(result["labor_cost_usd"], Decimal("100"), "labor cost")
    assert_equal(result["unit_cost_usd"], Decimal("208.00"), "unit cost")
    assert_equal(result["total_cost_usd"], Decimal("2080.00"), "total cost")
    assert margin_compliant(result["realized_gross_margin_pct"], "0.25")


def test_negative_surcharge_case():
    result = calculate(100, "-0.05", 2, 50, 10, "0.25", 2600)
    assert_equal(result["material_cost_usd"], Decimal("95.00"), "negative-surcharge material cost")
    assert_equal(result["total_cost_usd"], Decimal("1950.00"), "negative-surcharge total cost")
    assert_equal(result["minimum_cfo_approved_price_usd"], Decimal("2600"), "negative-surcharge minimum price")
    assert margin_compliant(result["realized_gross_margin_pct"], "0.25")


def test_no_intermediate_rounding():
    result = calculate("0.01", "0.1", 0, 0, 3, "0.25", "0.044")
    assert_equal(result["material_cost_usd"], Decimal("0.011"), "unrounded material cost")
    assert_equal(result["total_cost_usd"], Decimal("0.033"), "unrounded total cost")
    assert_equal(result["minimum_cfo_approved_price_usd"], Decimal("0.044"), "unrounded minimum price")


def test_safe_divide_fail_closed():
    result = calculate(100, 0, 0, 0, 1, 1, 100)
    assert_equal(result["minimum_cfo_approved_price_usd"], None, "zero CFO denominator")
    assert not margin_compliant(result["realized_gross_margin_pct"], 1)


def test_margin_tolerance():
    assert margin_compliant(Decimal("0.249999"), "0.25")
    assert not margin_compliant(Decimal("0.2499989"), "0.25")


if __name__ == "__main__":
    test_standard_case()
    test_negative_surcharge_case()
    test_no_intermediate_rounding()
    test_safe_divide_fail_closed()
    test_margin_tolerance()
    print("PASS: Phase 2 deterministic calculation parity checks")
