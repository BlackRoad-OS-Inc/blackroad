"""
BlackRoad Tax Calculator
=========================
US federal 2024 tax computation with full bracket logic,
effective rate calculation, withholding estimates, and quarterly estimates.
"""

from __future__ import annotations

import argparse
import csv
import io
import logging
import sqlite3
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal
from enum import Enum
from pathlib import Path
from typing import Dict, Generator, List, Optional, Tuple

# ─── Configuration ────────────────────────────────────────────────────────────
DB_PATH = Path.home() / ".blackroad" / "tax_calculator.db"
logging.basicConfig(format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("tax_calculator")

PRECISION = Decimal("0.01")
PRECISION_RATE = Decimal("0.0001")


# ─── Enumerations ─────────────────────────────────────────────────────────────
class FilingStatus(str, Enum):
    SINGLE = "single"
    MARRIED_JOINTLY = "married_jointly"
    MARRIED_SEPARATELY = "married_separately"
    HEAD_OF_HOUSEHOLD = "head_of_household"


class TaxCategory(str, Enum):
    ORDINARY_INCOME = "ordinary_income"
    CAPITAL_GAINS_SHORT = "capital_gains_short"
    CAPITAL_GAINS_LONG = "capital_gains_long"
    SELF_EMPLOYMENT = "self_employment"
    QUALIFIED_DIVIDENDS = "qualified_dividends"


# ─── Data Classes ─────────────────────────────────────────────────────────────
@dataclass
class TaxRule:
    jurisdiction: str
    rate: Decimal
    category: TaxCategory
    min_income: Decimal
    max_income: Optional[Decimal]  # None = unbounded
    filing_status: FilingStatus
    year: int

    def __post_init__(self):
        for attr in ("rate", "min_income"):
            val = getattr(self, attr)
            if isinstance(val, (int, float, str)):
                setattr(self, attr, Decimal(str(val)))
        if self.max_income is not None and isinstance(self.max_income, (int, float, str)):
            self.max_income = Decimal(str(self.max_income))
        if isinstance(self.category, str):
            self.category = TaxCategory(self.category)
        if isinstance(self.filing_status, str):
            self.filing_status = FilingStatus(self.filing_status)


@dataclass
class TaxBracket:
    rate: Decimal
    min_income: Decimal
    max_income: Optional[Decimal]
    tax_owed: Decimal = Decimal("0")
    income_in_bracket: Decimal = Decimal("0")


@dataclass
class TaxCalculation:
    gross_income: Decimal
    jurisdiction: str
    filing_status: FilingStatus
    year: int
    category: TaxCategory
    brackets_applied: List[TaxBracket]
    total_tax: Decimal
    effective_rate: Decimal
    marginal_rate: Decimal
    standard_deduction: Decimal
    taxable_income: Decimal
    calculated_at: datetime = field(default_factory=datetime.utcnow)

    @property
    def net_income(self) -> Decimal:
        return self.gross_income - self.total_tax


@dataclass
class WithholdingEstimate:
    gross_salary: Decimal
    filing_status: FilingStatus
    annual_tax: Decimal
    per_paycheck_monthly: Decimal
    per_paycheck_biweekly: Decimal
    per_paycheck_weekly: Decimal
    fica_social_security: Decimal
    fica_medicare: Decimal
    total_annual_withholding: Decimal


@dataclass
class QuarterlyEstimate:
    ytd_income: Decimal
    ytd_paid: Decimal
    quarter: int
    estimated_annual_income: Decimal
    estimated_annual_tax: Decimal
    amount_due: Decimal
    due_date: str


# ─── 2024 US Federal Tax Data ─────────────────────────────────────────────────
# Source: IRS Rev. Proc. 2023-34
US_2024_BRACKETS: Dict[FilingStatus, List[Tuple]] = {
    FilingStatus.SINGLE: [
        (Decimal("0.10"), Decimal("0"), Decimal("11600")),
        (Decimal("0.12"), Decimal("11600"), Decimal("47150")),
        (Decimal("0.22"), Decimal("47150"), Decimal("100525")),
        (Decimal("0.24"), Decimal("100525"), Decimal("191950")),
        (Decimal("0.32"), Decimal("191950"), Decimal("243725")),
        (Decimal("0.35"), Decimal("243725"), Decimal("609350")),
        (Decimal("0.37"), Decimal("609350"), None),
    ],
    FilingStatus.MARRIED_JOINTLY: [
        (Decimal("0.10"), Decimal("0"), Decimal("23200")),
        (Decimal("0.12"), Decimal("23200"), Decimal("94300")),
        (Decimal("0.22"), Decimal("94300"), Decimal("201050")),
        (Decimal("0.24"), Decimal("201050"), Decimal("383900")),
        (Decimal("0.32"), Decimal("383900"), Decimal("487450")),
        (Decimal("0.35"), Decimal("487450"), Decimal("731200")),
        (Decimal("0.37"), Decimal("731200"), None),
    ],
    FilingStatus.MARRIED_SEPARATELY: [
        (Decimal("0.10"), Decimal("0"), Decimal("11600")),
        (Decimal("0.12"), Decimal("11600"), Decimal("47150")),
        (Decimal("0.22"), Decimal("47150"), Decimal("100525")),
        (Decimal("0.24"), Decimal("100525"), Decimal("191950")),
        (Decimal("0.32"), Decimal("191950"), Decimal("243725")),
        (Decimal("0.35"), Decimal("243725"), Decimal("365600")),
        (Decimal("0.37"), Decimal("365600"), None),
    ],
    FilingStatus.HEAD_OF_HOUSEHOLD: [
        (Decimal("0.10"), Decimal("0"), Decimal("16550")),
        (Decimal("0.12"), Decimal("16550"), Decimal("63100")),
        (Decimal("0.22"), Decimal("63100"), Decimal("100500")),
        (Decimal("0.24"), Decimal("100500"), Decimal("191950")),
        (Decimal("0.32"), Decimal("191950"), Decimal("243700")),
        (Decimal("0.35"), Decimal("243700"), Decimal("609350")),
        (Decimal("0.37"), Decimal("609350"), None),
    ],
}

US_2024_STANDARD_DEDUCTIONS: Dict[FilingStatus, Decimal] = {
    FilingStatus.SINGLE: Decimal("14600"),
    FilingStatus.MARRIED_JOINTLY: Decimal("29200"),
    FilingStatus.MARRIED_SEPARATELY: Decimal("14600"),
    FilingStatus.HEAD_OF_HOUSEHOLD: Decimal("21900"),
}

# Long-term capital gains brackets (2024)
US_2024_LTCG_BRACKETS: Dict[FilingStatus, List[Tuple]] = {
    FilingStatus.SINGLE: [
        (Decimal("0.00"), Decimal("0"), Decimal("47025")),
        (Decimal("0.15"), Decimal("47025"), Decimal("518900")),
        (Decimal("0.20"), Decimal("518900"), None),
    ],
    FilingStatus.MARRIED_JOINTLY: [
        (Decimal("0.00"), Decimal("0"), Decimal("94050")),
        (Decimal("0.15"), Decimal("94050"), Decimal("583750")),
        (Decimal("0.20"), Decimal("583750"), None),
    ],
    FilingStatus.MARRIED_SEPARATELY: [
        (Decimal("0.00"), Decimal("0"), Decimal("47025")),
        (Decimal("0.15"), Decimal("47025"), Decimal("291850")),
        (Decimal("0.20"), Decimal("291850"), None),
    ],
    FilingStatus.HEAD_OF_HOUSEHOLD: [
        (Decimal("0.00"), Decimal("0"), Decimal("63000")),
        (Decimal("0.15"), Decimal("63000"), Decimal("551350")),
        (Decimal("0.20"), Decimal("551350"), None),
    ],
}

FICA_SOCIAL_SECURITY_RATE = Decimal("0.062")
FICA_SOCIAL_SECURITY_WAGE_BASE = Decimal("168600")
FICA_MEDICARE_RATE = Decimal("0.0145")
FICA_ADDITIONAL_MEDICARE_RATE = Decimal("0.009")
FICA_ADDITIONAL_MEDICARE_THRESHOLD_SINGLE = Decimal("200000")
SELF_EMPLOYMENT_RATE = Decimal("0.1530")  # 15.3% (both halves)
SELF_EMPLOYMENT_DEDUCTION_RATE = Decimal("0.5")  # deduct half


class TaxDatabase:
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_schema()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row
        return conn

    @contextmanager
    def transaction(self) -> Generator[sqlite3.Connection, None, None]:
        conn = self._connect()
        try:
            conn.execute("BEGIN")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _init_schema(self):
        with self.transaction() as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS tax_calculations (
                    id              TEXT PRIMARY KEY,
                    gross_income    TEXT NOT NULL,
                    jurisdiction    TEXT NOT NULL,
                    filing_status   TEXT NOT NULL,
                    year            INTEGER NOT NULL,
                    category        TEXT NOT NULL,
                    total_tax       TEXT NOT NULL,
                    effective_rate  TEXT NOT NULL,
                    marginal_rate   TEXT NOT NULL,
                    taxable_income  TEXT NOT NULL,
                    calculated_at   TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS custom_tax_rules (
                    id           TEXT PRIMARY KEY,
                    jurisdiction TEXT NOT NULL,
                    rate         TEXT NOT NULL,
                    category     TEXT NOT NULL,
                    min_income   TEXT NOT NULL,
                    max_income   TEXT,
                    filing_status TEXT NOT NULL,
                    year         INTEGER NOT NULL,
                    created_at   TEXT NOT NULL
                );
            """)

    def save_calculation(self, calc_id: str, calc: TaxCalculation):
        with self.transaction() as conn:
            conn.execute(
                """INSERT INTO tax_calculations
                   (id, gross_income, jurisdiction, filing_status, year,
                    category, total_tax, effective_rate, marginal_rate,
                    taxable_income, calculated_at)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    calc_id, str(calc.gross_income), calc.jurisdiction,
                    calc.filing_status.value, calc.year,
                    calc.category.value, str(calc.total_tax),
                    str(calc.effective_rate), str(calc.marginal_rate),
                    str(calc.taxable_income), calc.calculated_at.isoformat(),
                ),
            )


# ─── Tax Calculator Service ────────────────────────────────────────────────────
class TaxCalculatorService:
    """US Federal tax computation engine."""

    def __init__(self, db: Optional[TaxDatabase] = None):
        self.db = db or TaxDatabase()

    def tax_brackets(
        self,
        jurisdiction: str,
        filing_status: FilingStatus = FilingStatus.SINGLE,
        year: int = 2024,
        category: TaxCategory = TaxCategory.ORDINARY_INCOME,
    ) -> List[TaxRule]:
        """Return tax brackets for given jurisdiction/year/status."""
        if jurisdiction.upper() != "US":
            raise ValueError(f"Jurisdiction not supported: {jurisdiction}. Currently US only.")

        if category == TaxCategory.CAPITAL_GAINS_LONG:
            brackets_raw = US_2024_LTCG_BRACKETS.get(filing_status, [])
        else:
            brackets_raw = US_2024_BRACKETS.get(filing_status, [])

        return [
            TaxRule(
                jurisdiction=jurisdiction.upper(),
                rate=rate,
                category=category,
                min_income=min_inc,
                max_income=max_inc,
                filing_status=filing_status,
                year=year,
            )
            for rate, min_inc, max_inc in brackets_raw
        ]

    def calculate_tax(
        self,
        income: Decimal,
        jurisdiction: str,
        year: int = 2024,
        filing_status: FilingStatus = FilingStatus.SINGLE,
        category: TaxCategory = TaxCategory.ORDINARY_INCOME,
        itemized_deductions: Optional[Decimal] = None,
    ) -> TaxCalculation:
        """Calculate federal income tax using bracket method."""
        income = Decimal(str(income))
        if income < Decimal("0"):
            raise ValueError("Income cannot be negative")

        std_deduction = US_2024_STANDARD_DEDUCTIONS.get(filing_status, Decimal("0"))
        deduction = max(
            std_deduction,
            itemized_deductions if itemized_deductions else Decimal("0"),
        )

        # Self-employment: deduct half of SE tax first
        if category == TaxCategory.SELF_EMPLOYMENT:
            se_tax = income * SELF_EMPLOYMENT_RATE
            se_deduction = (se_tax * SELF_EMPLOYMENT_DEDUCTION_RATE).quantize(PRECISION)
            taxable_income = max(Decimal("0"), income - deduction - se_deduction)
        else:
            taxable_income = max(Decimal("0"), income - deduction)

        # Select bracket table
        if category == TaxCategory.CAPITAL_GAINS_LONG:
            brackets_raw = US_2024_LTCG_BRACKETS.get(filing_status, [])
        elif category == TaxCategory.QUALIFIED_DIVIDENDS:
            brackets_raw = US_2024_LTCG_BRACKETS.get(filing_status, [])
        else:
            brackets_raw = US_2024_BRACKETS.get(filing_status, [])

        applied_brackets: List[TaxBracket] = []
        total_tax = Decimal("0")
        marginal_rate = Decimal("0")

        for rate, min_inc, max_inc in brackets_raw:
            if taxable_income <= min_inc:
                break
            upper = max_inc if max_inc is not None else taxable_income
            income_in_bracket = min(taxable_income, upper) - min_inc
            if income_in_bracket <= Decimal("0"):
                continue
            tax_in_bracket = (income_in_bracket * rate).quantize(PRECISION, rounding=ROUND_HALF_UP)
            total_tax += tax_in_bracket
            marginal_rate = rate
            applied_brackets.append(TaxBracket(
                rate=rate,
                min_income=min_inc,
                max_income=max_inc,
                income_in_bracket=income_in_bracket,
                tax_owed=tax_in_bracket,
            ))

        # Add self-employment tax (SE = both halves)
        if category == TaxCategory.SELF_EMPLOYMENT:
            se_tax = (income * SELF_EMPLOYMENT_RATE).quantize(PRECISION, rounding=ROUND_HALF_UP)
            total_tax += se_tax

        effective_rate = (
            (total_tax / income).quantize(PRECISION_RATE, rounding=ROUND_HALF_UP)
            if income > Decimal("0")
            else Decimal("0")
        )

        return TaxCalculation(
            gross_income=income,
            jurisdiction=jurisdiction.upper(),
            filing_status=filing_status,
            year=year,
            category=category,
            brackets_applied=applied_brackets,
            total_tax=total_tax,
            effective_rate=effective_rate,
            marginal_rate=marginal_rate,
            standard_deduction=deduction,
            taxable_income=taxable_income,
        )

    def get_effective_rate(
        self,
        income: Decimal,
        jurisdiction: str,
        filing_status: FilingStatus = FilingStatus.SINGLE,
        year: int = 2024,
    ) -> Decimal:
        """Return effective tax rate as a decimal."""
        calc = self.calculate_tax(income, jurisdiction, year, filing_status)
        return calc.effective_rate

    def withholding_estimate(
        self,
        salary: Decimal,
        filing_status: FilingStatus = FilingStatus.SINGLE,
        allowances: int = 1,
        year: int = 2024,
    ) -> WithholdingEstimate:
        """Calculate paycheck withholding estimate."""
        salary = Decimal(str(salary))
        calc = self.calculate_tax(salary, "US", year, filing_status)

        # FICA
        ss_taxable = min(salary, FICA_SOCIAL_SECURITY_WAGE_BASE)
        fica_ss = (ss_taxable * FICA_SOCIAL_SECURITY_RATE).quantize(PRECISION)
        fica_medicare = (salary * FICA_MEDICARE_RATE).quantize(PRECISION)
        threshold = FICA_ADDITIONAL_MEDICARE_THRESHOLD_SINGLE
        if salary > threshold:
            fica_medicare += ((salary - threshold) * FICA_ADDITIONAL_MEDICARE_RATE).quantize(PRECISION)

        total_annual = calc.total_tax + fica_ss + fica_medicare

        return WithholdingEstimate(
            gross_salary=salary,
            filing_status=filing_status,
            annual_tax=calc.total_tax,
            per_paycheck_monthly=(total_annual / 12).quantize(PRECISION),
            per_paycheck_biweekly=(total_annual / 26).quantize(PRECISION),
            per_paycheck_weekly=(total_annual / 52).quantize(PRECISION),
            fica_social_security=fica_ss,
            fica_medicare=fica_medicare,
            total_annual_withholding=total_annual,
        )

    def quarterly_estimate(
        self,
        ytd_income: Decimal,
        ytd_paid: Decimal,
        quarter: int,
        filing_status: FilingStatus = FilingStatus.SINGLE,
        year: int = 2024,
    ) -> QuarterlyEstimate:
        """Estimate quarterly estimated tax payment."""
        if quarter not in (1, 2, 3, 4):
            raise ValueError("Quarter must be 1-4")

        ytd_income = Decimal(str(ytd_income))
        ytd_paid = Decimal(str(ytd_paid))

        months_elapsed = {1: 3, 2: 5, 3: 8, 4: 12}[quarter]
        annualized = (ytd_income * 12 / months_elapsed).quantize(PRECISION)

        calc = self.calculate_tax(annualized, "US", year, filing_status)
        estimated_annual_tax = calc.total_tax

        # Safe harbor: 110% of prior year tax (simplified: use same calc)
        safe_harbor = (estimated_annual_tax * Decimal("1.10")).quantize(PRECISION)

        # Due so far = fraction of annual * quarters / 4
        fraction = Decimal(str(quarter)) / Decimal("4")
        due_so_far = (min(estimated_annual_tax, safe_harbor) * fraction).quantize(PRECISION)
        amount_due = max(Decimal("0"), due_so_far - ytd_paid)

        due_dates = {1: "April 15", 2: "June 17", 3: "September 16", 4: "January 15"}

        return QuarterlyEstimate(
            ytd_income=ytd_income,
            ytd_paid=ytd_paid,
            quarter=quarter,
            estimated_annual_income=annualized,
            estimated_annual_tax=estimated_annual_tax,
            amount_due=amount_due,
            due_date=due_dates[quarter],
        )

    def export_brackets_csv(self, filing_status: FilingStatus = FilingStatus.SINGLE) -> str:
        """Export 2024 brackets as CSV."""
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["Rate", "Income From", "Income To", "Tax On Lower Brackets"])
        cumulative = Decimal("0")
        prev_max = Decimal("0")
        for rate, min_inc, max_inc in US_2024_BRACKETS[filing_status]:
            if prev_max > Decimal("0"):
                cumulative += (prev_max - min_inc if min_inc < prev_max else Decimal("0"))
            writer.writerow([
                f"{rate:.0%}",
                f"${min_inc:,.0f}",
                f"${max_inc:,.0f}" if max_inc else "unlimited",
                f"${cumulative:,.2f}",
            ])
            prev_max = max_inc if max_inc else Decimal("0")
        return output.getvalue()


# ─── CLI ───────────────────────────────────────────────────────────────────────
def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tax-calc",
        description="BlackRoad Tax Calculator — US Federal 2024",
    )
    parser.add_argument("--db", default=str(DB_PATH))
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("calculate", help="Calculate federal tax")
    p.add_argument("income")
    p.add_argument("--status", default="single", choices=[s.value for s in FilingStatus])
    p.add_argument("--year", type=int, default=2024)
    p.add_argument("--category", default="ordinary_income", choices=[c.value for c in TaxCategory])
    p.add_argument("--itemized", default=None)

    p = sub.add_parser("rate", help="Get effective tax rate")
    p.add_argument("income")
    p.add_argument("--status", default="single")

    p = sub.add_parser("brackets", help="Show tax brackets")
    p.add_argument("--status", default="single")
    p.add_argument("--csv", action="store_true")

    p = sub.add_parser("withholding", help="Estimate paycheck withholding")
    p.add_argument("salary")
    p.add_argument("--status", default="single")

    p = sub.add_parser("quarterly", help="Estimate quarterly payment")
    p.add_argument("ytd_income")
    p.add_argument("ytd_paid")
    p.add_argument("--quarter", type=int, default=1)
    p.add_argument("--status", default="single")

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    svc = TaxCalculatorService(TaxDatabase(Path(args.db)))

    if args.command == "calculate":
        fs = FilingStatus(args.status)
        cat = TaxCategory(args.category)
        itemized = Decimal(args.itemized) if args.itemized else None
        calc = svc.calculate_tax(Decimal(args.income), "US", args.year, fs, cat, itemized)
        print(f"\n{'='*55}")
        print(f"  US FEDERAL TAX CALCULATION {args.year}")
        print(f"{'='*55}")
        print(f"  Gross Income:       ${calc.gross_income:>12,.2f}")
        print(f"  Std Deduction:      ${calc.standard_deduction:>12,.2f}")
        print(f"  Taxable Income:     ${calc.taxable_income:>12,.2f}")
        print(f"{'─'*55}")
        for b in calc.brackets_applied:
            print(
                f"  {b.rate:>6.0%}  ${b.min_income:>10,.0f}"
                f"–${(b.max_income or b.min_income + b.income_in_bracket):>10,.0f}"
                f"  tax=${b.tax_owed:>10,.2f}"
            )
        print(f"{'─'*55}")
        print(f"  Total Tax:          ${calc.total_tax:>12,.2f}")
        print(f"  Effective Rate:     {calc.effective_rate:>12.2%}")
        print(f"  Marginal Rate:      {calc.marginal_rate:>12.0%}")
        print(f"  Net Income:         ${calc.net_income:>12,.2f}")

    elif args.command == "rate":
        rate = svc.get_effective_rate(Decimal(args.income), "US", FilingStatus(args.status))
        print(f"Effective rate: {rate:.2%}")

    elif args.command == "brackets":
        fs = FilingStatus(args.status)
        if args.csv:
            print(svc.export_brackets_csv(fs))
        else:
            print(f"\n2024 Federal Brackets ({fs.value})")
            print(f"{'Rate':<8} {'From':>12} {'To':>14}")
            print("─" * 38)
            for rate, min_inc, max_inc in US_2024_BRACKETS[fs]:
                upper = f"${max_inc:>12,.0f}" if max_inc else "   unlimited"
                print(f"{rate:>6.0%}   ${min_inc:>12,.0f}  {upper}")

    elif args.command == "withholding":
        est = svc.withholding_estimate(Decimal(args.salary), FilingStatus(args.status))
        print(f"\nWithholding Estimate (annual salary: ${est.gross_salary:,.2f})")
        print(f"  Annual income tax:  ${est.annual_tax:>10,.2f}")
        print(f"  FICA SS:            ${est.fica_social_security:>10,.2f}")
        print(f"  FICA Medicare:      ${est.fica_medicare:>10,.2f}")
        print(f"  Total annual:       ${est.total_annual_withholding:>10,.2f}")
        print(f"  Per paycheck (mo):  ${est.per_paycheck_monthly:>10,.2f}")
        print(f"  Per paycheck (bw):  ${est.per_paycheck_biweekly:>10,.2f}")
        print(f"  Per paycheck (wk):  ${est.per_paycheck_weekly:>10,.2f}")

    elif args.command == "quarterly":
        est = svc.quarterly_estimate(
            Decimal(args.ytd_income), Decimal(args.ytd_paid),
            args.quarter, FilingStatus(args.status),
        )
        print(f"\nQ{est.quarter} Estimated Tax")
        print(f"  YTD Income:         ${est.ytd_income:>10,.2f}")
        print(f"  Annualized Est.:    ${est.estimated_annual_income:>10,.2f}")
        print(f"  Est. Annual Tax:    ${est.estimated_annual_tax:>10,.2f}")
        print(f"  YTD Paid:           ${est.ytd_paid:>10,.2f}")
        print(f"  Amount Due:         ${est.amount_due:>10,.2f}")
        print(f"  Due Date:           {est.due_date}")


if __name__ == "__main__":
    main()
