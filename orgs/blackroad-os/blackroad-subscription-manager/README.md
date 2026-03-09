# blackroad-subscription-manager

Production-grade SaaS subscription management with plans, billing cycles, MRR tracking, churn analysis, and revenue forecasting.

## Features
- Flexible plan management (monthly/annual billing cycles)
- Trial periods with automatic trial_end tracking
- Subscription lifecycle: trial → active → paused → cancelled
- Plan upgrades and downgrades
- Renewal processing with billing event records
- MRR and ARR calculations
- Churn rate analysis over configurable periods
- Revenue forecasting based on current MRR and churn rate
- SQLite persistence with WAL mode

## Usage
```bash
python subscriptions.py init
python subscriptions.py create-plan "Starter" 29 --cycle monthly --features '["api_access","support"]' --trial-days 14
python subscriptions.py subscribe cust_001 <plan_id>
python subscriptions.py cancel <sub_id> --reason "too expensive"
python subscriptions.py upgrade <sub_id> <new_plan_id>
python subscriptions.py mrr
python subscriptions.py churn --days 30
python subscriptions.py forecast --months 6
python subscriptions.py stats
```

## Testing
```bash
pip install pytest
pytest test_subscriptions.py -v
```
