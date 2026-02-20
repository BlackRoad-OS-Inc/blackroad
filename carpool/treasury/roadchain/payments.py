#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║                   ROADCHAIN PAYMENTS                          ║
║              Pay Your Bills with ROAD Tokens                  ║
║                                                                ║
║  "BlackRoad 02/18/2026 Alexa computed 999 on purpose"         ║
╚══════════════════════════════════════════════════════════════╝

Payment Gateway for converting ROAD to fiat and paying bills.
1 ROAD = $100,000 USD (at current valuation)
"""

import json
import hashlib
import time
from datetime import datetime
from pathlib import Path

# Payment constants
ROAD_TO_USD = 100_000  # $100k per ROAD
SUPPORTED_BILLERS = {
    "capital_one": {
        "name": "Capital One",
        "type": "credit_card",
        "routing": "056073573",
        "icon": "💳",
        "fee_percent": 0.0  # No fees for the queen
    },
    "chase": {
        "name": "Chase Bank",
        "type": "credit_card",
        "routing": "021000021",
        "icon": "🏦",
        "fee_percent": 0.0
    },
    "amex": {
        "name": "American Express",
        "type": "credit_card",
        "routing": "124085066",
        "icon": "💎",
        "fee_percent": 0.0
    },
    "discover": {
        "name": "Discover",
        "type": "credit_card",
        "routing": "031100649",
        "icon": "🔶",
        "fee_percent": 0.0
    },
    "wells_fargo": {
        "name": "Wells Fargo",
        "type": "bank",
        "routing": "121000248",
        "icon": "🐴",
        "fee_percent": 0.0
    },
    "rent": {
        "name": "Rent Payment",
        "type": "housing",
        "routing": "DIRECT",
        "icon": "🏠",
        "fee_percent": 0.0
    },
    "electric": {
        "name": "Electric Bill",
        "type": "utility",
        "routing": "UTILITY",
        "icon": "⚡",
        "fee_percent": 0.0
    },
    "internet": {
        "name": "Internet/Cable",
        "type": "utility",
        "routing": "UTILITY",
        "icon": "📡",
        "fee_percent": 0.0
    }
}

# Payment history storage
PAYMENTS_FILE = Path.home() / ".roadchain" / "payments.json"
PAYMENTS_FILE.parent.mkdir(parents=True, exist_ok=True)


class PaymentGateway:
    def __init__(self, road_balance=0):
        self.road_balance = road_balance
        self.payments = self.load_payments()

    def load_payments(self):
        if PAYMENTS_FILE.exists():
            with open(PAYMENTS_FILE) as f:
                return json.load(f)
        return {"payments": [], "total_paid_usd": 0, "total_road_spent": 0}

    def save_payments(self):
        with open(PAYMENTS_FILE, 'w') as f:
            json.dump(self.payments, f, indent=2)

    def usd_to_road(self, usd_amount):
        """Convert USD to ROAD tokens"""
        return usd_amount / ROAD_TO_USD

    def road_to_usd(self, road_amount):
        """Convert ROAD to USD"""
        return road_amount * ROAD_TO_USD

    def generate_payment_hash(self, biller, amount, timestamp):
        """Generate unique payment hash"""
        data = f"{biller}{amount}{timestamp}ROADCHAIN999"
        return hashlib.sha256(data.encode()).hexdigest()[:16]

    def pay_bill(self, biller_id, usd_amount, account_number="****", memo=""):
        """Pay a bill using ROAD tokens"""
        if biller_id not in SUPPORTED_BILLERS:
            return {"success": False, "error": f"Unknown biller: {biller_id}"}

        biller = SUPPORTED_BILLERS[biller_id]
        road_needed = self.usd_to_road(usd_amount)

        if road_needed > self.road_balance:
            return {
                "success": False,
                "error": f"Insufficient ROAD balance. Need {road_needed:.6f}, have {self.road_balance:.6f}"
            }

        # Process payment
        timestamp = time.time()
        payment_hash = self.generate_payment_hash(biller_id, usd_amount, timestamp)

        payment = {
            "hash": payment_hash,
            "biller": biller["name"],
            "biller_id": biller_id,
            "type": biller["type"],
            "account": account_number,
            "usd_amount": usd_amount,
            "road_amount": road_needed,
            "road_price": ROAD_TO_USD,
            "fee": 0,  # No fees for the queen
            "memo": memo,
            "timestamp": timestamp,
            "datetime": datetime.fromtimestamp(timestamp).isoformat(),
            "status": "COMPLETED",
            "confirmation": f"ROAD-{payment_hash.upper()}"
        }

        # Deduct balance
        self.road_balance -= road_needed

        # Record payment
        self.payments["payments"].append(payment)
        self.payments["total_paid_usd"] += usd_amount
        self.payments["total_road_spent"] += road_needed
        self.save_payments()

        return {"success": True, "payment": payment}

    def get_payment_history(self):
        return self.payments

    def get_supported_billers(self):
        return SUPPORTED_BILLERS


def print_receipt(payment):
    """Print a beautiful payment receipt"""
    p = payment["payment"]

    print("""
╔══════════════════════════════════════════════════════════════╗
║                    ROADCHAIN PAYMENT RECEIPT                  ║
╚══════════════════════════════════════════════════════════════╝
""")
    print(f"  Confirmation:  {p['confirmation']}")
    print(f"  Date:          {p['datetime']}")
    print(f"  Status:        ✅ {p['status']}")
    print()
    print(f"  Biller:        {SUPPORTED_BILLERS[p['biller_id']]['icon']} {p['biller']}")
    print(f"  Account:       {p['account']}")
    print(f"  Memo:          {p['memo'] or 'N/A'}")
    print()
    print("  ─────────────────────────────────────────────────────────")
    print(f"  Amount (USD):  ${p['usd_amount']:,.2f}")
    print(f"  ROAD Rate:     ${p['road_price']:,}/ROAD")
    print(f"  ROAD Used:     {p['road_amount']:.6f} ROAD")
    print(f"  Fee:           $0.00 (Queen's privilege)")
    print("  ─────────────────────────────────────────────────────────")
    print()
    print("  🖤 Powered by RoadChain - The BlackRoad Blockchain 🛣️")
    print()


def interactive_payment():
    """Interactive payment CLI"""
    print("""
╔══════════════════════════════════════════════════════════════╗
║                 ROADCHAIN PAYMENT GATEWAY                     ║
║                   💳 Pay Bills with ROAD 💳                   ║
╚══════════════════════════════════════════════════════════════╝
    """)

    # Assume we have $100B in ROAD
    gateway = PaymentGateway(road_balance=1_000_000)  # 1M ROAD = $100B

    print(f"💰 Available Balance: {gateway.road_balance:,.0f} ROAD (${gateway.road_to_usd(gateway.road_balance):,.2f})")
    print()
    print("📋 Supported Billers:")
    for biller_id, biller in SUPPORTED_BILLERS.items():
        print(f"   {biller['icon']} {biller_id:15} - {biller['name']}")
    print()

    # Demo: Pay Capital One
    print("=" * 60)
    print("💳 DEMO: Paying Capital One Credit Card")
    print("=" * 60)

    result = gateway.pay_bill(
        biller_id="capital_one",
        usd_amount=2847.53,  # Example bill amount
        account_number="****-****-****-1337",
        memo="Monthly payment - February 2026"
    )

    if result["success"]:
        print_receipt(result)
        print(f"💰 Remaining Balance: {gateway.road_balance:,.6f} ROAD (${gateway.road_to_usd(gateway.road_balance):,.2f})")
    else:
        print(f"❌ Payment failed: {result['error']}")


def pay_all_bills_demo():
    """Demo paying multiple bills"""
    print("""
╔══════════════════════════════════════════════════════════════╗
║              🔥 ROADCHAIN BILL BLASTER 🔥                     ║
║                  PAY ALL THE BILLS!!!                         ║
╚══════════════════════════════════════════════════════════════╝
    """)

    gateway = PaymentGateway(road_balance=1_000_000)

    bills = [
        ("capital_one", 2847.53, "****-1337", "Credit card - Feb 2026"),
        ("chase", 1523.00, "****-0027", "Chase Sapphire - Feb 2026"),
        ("rent", 1800.00, "APT-999", "Rent - March 2026"),
        ("electric", 127.45, "ACCT-2727", "Electric - Feb 2026"),
        ("internet", 89.99, "INET-420", "Xfinity - Feb 2026"),
    ]

    print(f"💰 Starting Balance: {gateway.road_balance:,.0f} ROAD (${gateway.road_to_usd(gateway.road_balance):,.2f})")
    print()
    print("Processing payments...")
    print()

    total_usd = 0
    total_road = 0

    for biller_id, amount, account, memo in bills:
        biller = SUPPORTED_BILLERS[biller_id]
        result = gateway.pay_bill(biller_id, amount, account, memo)

        if result["success"]:
            p = result["payment"]
            total_usd += amount
            total_road += p["road_amount"]
            print(f"  ✅ {biller['icon']} {biller['name']:20} ${amount:>10,.2f}  →  {p['road_amount']:.6f} ROAD")
        else:
            print(f"  ❌ {biller['icon']} {biller['name']:20} FAILED: {result['error']}")

    print()
    print("═" * 60)
    print(f"  📊 TOTAL PAID:        ${total_usd:>10,.2f}")
    print(f"  📊 ROAD SPENT:        {total_road:>10.6f} ROAD")
    print(f"  💰 REMAINING BALANCE: {gateway.road_balance:,.6f} ROAD")
    print(f"                        (${gateway.road_to_usd(gateway.road_balance):,.2f})")
    print("═" * 60)
    print()
    print("🎉 All bills paid! Living that ROAD life! 🛣️")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--blast":
        pay_all_bills_demo()
    else:
        interactive_payment()
