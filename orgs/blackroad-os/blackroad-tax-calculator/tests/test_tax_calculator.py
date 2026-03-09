"""Tests for BlackRoad Tax Calculator."""

import pytest
from decimal import Decimal
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from tax_calculator import (
    TaxCalculatorService, TaxDatabase,
    FilingStatus, TaxCategory,
    US_2024_BRACKETS, US_2024_STANDARD_DEDUCTIONS
)


@pytest.fixture
def svc(tmp_path):
    db = TaxDatabase(tmp_path / "tax.db")
    return TaxCalculatorService(db)


def test_calculate_tax_zero_income(svc):
    calc = svc.calculate_tax(Decimal("0"), "US")
    assert calc.total_tax == Decimal("0")
    assert calc.effective_rate == Decimal("0")


def test_calculate_tax_below_standard_deduction(svc):
    # Income below standard deduction → $0 tax
    calc = svc.calculate_tax(Decimal("10000"), "US", filing_status=FilingStatus.SINGLE)
    assert calc.total_tax == Decimal("0")
    assert calc.taxable_income == Decimal("0")


def test_calculate_tax_single_bracket_10pct(svc):
    # $20,000 single: taxable = 20000 - 14600 = 5400; tax = 5400 * 10% = $540
    calc = svc.calculate_tax(Decimal("20000"), "US", filing_status=FilingStatus.SINGLE)
    assert calc.total_tax == Decimal("540.00")
    assert calc.marginal_rate == Decimal("0.10")


def test_calculate_tax_two_brackets(svc):
    # $60000 single: taxable = 60000 - 14600 = 45400
    # bracket 1: 11600 * 10% = 1160
    # bracket 2: (45400 - 11600) * 12% = 33800 * 12% = 4056
    # total = 5216
    calc = svc.calculate_tax(Decimal("60000"), "US", filing_status=FilingStatus.SINGLE)
    assert calc.total_tax == Decimal("5216.00")
    assert calc.marginal_rate == Decimal("0.12")


def test_calculate_tax_married_jointly(svc):
    calc = svc.calculate_tax(Decimal("100000"), "US", filing_status=FilingStatus.MARRIED_JOINTLY)
    assert calc.total_tax > Decimal("0")
    assert calc.effective_rate < Decimal("0.15")  # should be well under 15% at 100k MFJ


def test_effective_rate_increases_with_income(svc):
    rate1 = svc.get_effective_rate(Decimal("50000"), "US", FilingStatus.SINGLE)
    rate2 = svc.get_effective_rate(Decimal("150000"), "US", FilingStatus.SINGLE)
    rate3 = svc.get_effective_rate(Decimal("500000"), "US", FilingStatus.SINGLE)
    assert rate1 < rate2 < rate3


def test_tax_brackets_returns_all_brackets(svc):
    brackets = svc.tax_brackets("US", FilingStatus.SINGLE)
    assert len(brackets) == 7
    rates = [b.rate for b in brackets]
    assert Decimal("0.10") in rates
    assert Decimal("0.37") in rates


def test_unsupported_jurisdiction_raises(svc):
    with pytest.raises(ValueError, match="not supported"):
        svc.calculate_tax(Decimal("50000"), "UK")


def test_withholding_estimate_biweekly(svc):
    est = svc.withholding_estimate(Decimal("80000"), FilingStatus.SINGLE)
    assert est.per_paycheck_biweekly > Decimal("0")
    assert est.per_paycheck_biweekly < est.per_paycheck_monthly
    assert est.fica_social_security > Decimal("0")
    assert est.fica_medicare > Decimal("0")
    # Total should roughly equal annual / 26
    assert abs(est.per_paycheck_biweekly - est.total_annual_withholding / 26) < Decimal("5")


def test_fica_ss_wage_base_cap(svc):
    # High earner - SS should be capped at wage base
    est_high = svc.withholding_estimate(Decimal("300000"), FilingStatus.SINGLE)
    est_low = svc.withholding_estimate(Decimal("80000"), FilingStatus.SINGLE)
    # High earner SS should NOT be proportionally higher (capped)
    assert est_high.fica_social_security < est_high.gross_salary * Decimal("0.062")


def test_quarterly_estimate_q1(svc):
    est = svc.quarterly_estimate(
        ytd_income=Decimal("30000"),
        ytd_paid=Decimal("0"),
        quarter=1,
    )
    assert est.quarter == 1
    assert est.amount_due > Decimal("0")
    assert est.due_date == "April 15"


def test_quarterly_estimate_no_underpayment(svc):
    est = svc.quarterly_estimate(
        ytd_income=Decimal("30000"),
        ytd_paid=Decimal("10000"),
        quarter=1,
    )
    # If you've already paid enough, nothing due
    assert est.amount_due == Decimal("0")


def test_quarterly_estimate_invalid_quarter(svc):
    with pytest.raises(ValueError):
        svc.quarterly_estimate(Decimal("50000"), Decimal("0"), quarter=5)


def test_ltcg_rates_lower_than_ordinary(svc):
    income = Decimal("100000")
    ordinary = svc.calculate_tax(income, "US", category=TaxCategory.ORDINARY_INCOME)
    ltcg = svc.calculate_tax(income, "US", category=TaxCategory.CAPITAL_GAINS_LONG)
    assert ltcg.total_tax <= ordinary.total_tax


def test_export_brackets_csv(svc):
    csv_out = svc.export_brackets_csv(FilingStatus.SINGLE)
    assert "Rate" in csv_out
    assert "10%" in csv_out
    assert "37%" in csv_out
