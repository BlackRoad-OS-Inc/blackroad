# BlackRoad Tax Calculator

> US Federal 2024 income tax computation: bracket logic, effective rate, withholding estimates, and quarterly payments.

Part of the [BlackRoad OS](https://github.com/BlackRoad-OS) platform.

## Features

- **2024 brackets**: All 7 federal brackets for Single, MFJ, MFS, HoH
- **Effective & marginal rates**: `get_effective_rate()`, `calculate_tax()`
- **Multiple categories**: Ordinary income, long-term capital gains, self-employment, qualified dividends
- **Withholding**: Per-paycheck estimates (monthly/biweekly/weekly) with FICA
- **Quarterly estimates**: Q1–Q4 due amounts with safe-harbor 110% rule
- **W4 allowances**: Adjusts taxable income by allowances and standard deduction

## Usage

```bash
# Calculate tax
python src/tax_calculator.py calculate 75000 --status single

# Effective rate
python src/tax_calculator.py rate 150000

# Show brackets
python src/tax_calculator.py brackets --status married_jointly

# Withholding estimate
python src/tax_calculator.py withholding 90000 --status single

# Quarterly estimate
python src/tax_calculator.py quarterly 45000 2500 --quarter 2
```

## Architecture

- `src/tax_calculator.py` — 610+ lines: `TaxRule`, `TaxCalculation`, `WithholdingEstimate`, `TaxCalculatorService`
- `tests/` — 15 test functions with bracket math verified
- Seeded with IRS Rev. Proc. 2023-34 (2024 brackets)

## License

Proprietary — © BlackRoad OS, Inc. All rights reserved.
