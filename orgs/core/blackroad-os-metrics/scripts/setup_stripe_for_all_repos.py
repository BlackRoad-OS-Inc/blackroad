#!/usr/bin/env python3
"""
Stripe Integration Setup for All BlackRoad OS Repositories
Adds Stripe payment infrastructure to monetize every repo

Author: Alexa Amundson
Copyright: BlackRoad OS, Inc.
"""

import os
import json

# Stripe configuration
STRIPE_CONFIG = {
    "products": {
        "open_source_support": {
            "name": "Open Source Support",
            "description": "Support BlackRoad OS development",
            "prices": {
                "monthly_5": {"amount": 500, "interval": "month"},
                "monthly_25": {"amount": 2500, "interval": "month"},
                "monthly_100": {"amount": 10000, "interval": "month"},
                "one_time_10": {"amount": 1000, "interval": "one_time"},
                "one_time_50": {"amount": 5000, "interval": "one_time"},
                "one_time_500": {"amount": 50000, "interval": "one_time"}
            }
        },
        "commercial_license": {
            "name": "Commercial License",
            "description": "Use BlackRoad OS in commercial products",
            "prices": {
                "startup": {"amount": 49900, "interval": "year"},
                "business": {"amount": 99900, "interval": "year"},
                "enterprise": {"amount": 249900, "interval": "year"}
            }
        },
        "consulting": {
            "name": "Consulting & Integration",
            "description": "Expert help integrating BlackRoad OS",
            "prices": {
                "hourly": {"amount": 25000, "interval": "one_time"},
                "daily": {"amount": 150000, "interval": "one_time"},
                "project": {"amount": 500000, "interval": "one_time"}
            }
        },
        "priority_support": {
            "name": "Priority Support",
            "description": "24/7 priority support with SLA",
            "prices": {
                "monthly": {"amount": 49900, "interval": "month"}
            }
        }
    }
}

def generate_stripe_funding_file():
    """Generate .github/FUNDING.yml for all repos"""
    return """# BlackRoad OS Funding
# Support the development of BlackRoad OS

github: [blackboxprogramming]
custom: ['https://buy.stripe.com/blackroad-os-support', 'https://blackroad.io/sponsor']
"""

def generate_stripe_payment_page_html():
    """Generate Stripe payment page HTML"""
    return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Support BlackRoad OS</title>
    <script src="https://js.stripe.com/v3/"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            max-width: 1000px;
            width: 100%;
        }

        .header {
            background: white;
            padding: 40px;
            border-radius: 15px 15px 0 0;
            text-align: center;
        }

        h1 {
            font-size: 2.5em;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }

        .subtitle {
            color: #666;
            font-size: 1.2em;
        }

        .content {
            background: white;
            padding: 40px;
            border-radius: 0 0 15px 15px;
        }

        .pricing-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 25px;
            margin-top: 30px;
        }

        .pricing-card {
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            transition: all 0.3s ease;
            cursor: pointer;
        }

        .pricing-card:hover {
            border-color: #667eea;
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.2);
        }

        .pricing-card.featured {
            border-color: #667eea;
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.05), rgba(118, 75, 162, 0.05));
        }

        .pricing-title {
            font-size: 1.5em;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }

        .pricing-amount {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
            margin: 20px 0;
        }

        .pricing-interval {
            color: #999;
            font-size: 0.9em;
        }

        .pricing-description {
            color: #666;
            margin: 15px 0;
            font-size: 0.95em;
        }

        .pricing-features {
            list-style: none;
            margin: 20px 0;
            text-align: left;
        }

        .pricing-features li {
            padding: 8px 0;
            color: #555;
        }

        .pricing-features li:before {
            content: "✓ ";
            color: #667eea;
            font-weight: bold;
            margin-right: 8px;
        }

        button {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 15px 40px;
            border-radius: 8px;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            width: 100%;
            margin-top: 20px;
        }

        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }

        .badge {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.85em;
            margin-bottom: 15px;
        }

        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Support BlackRoad OS</h1>
            <p class="subtitle">Help build the future of AI infrastructure</p>
        </div>

        <div class="content">
            <h2 style="margin-bottom: 10px;">One-Time Support</h2>
            <p style="color: #666; margin-bottom: 25px;">Make a one-time contribution to support development</p>

            <div class="pricing-grid">
                <div class="pricing-card" onclick="checkout('one_time_10')">
                    <div class="pricing-title">Coffee</div>
                    <div class="pricing-amount">$10</div>
                    <div class="pricing-description">Buy us a coffee ☕</div>
                    <button>Support $10</button>
                </div>

                <div class="pricing-card" onclick="checkout('one_time_50')">
                    <div class="pricing-title">Supporter</div>
                    <div class="pricing-amount">$50</div>
                    <div class="pricing-description">Meaningful support 🙏</div>
                    <button>Support $50</button>
                </div>

                <div class="pricing-card featured" onclick="checkout('one_time_500')">
                    <span class="badge">Most Popular</span>
                    <div class="pricing-title">Champion</div>
                    <div class="pricing-amount">$500</div>
                    <div class="pricing-description">Serious impact 🚀</div>
                    <button>Support $500</button>
                </div>
            </div>

            <h2 style="margin: 50px 0 10px;">Monthly Support</h2>
            <p style="color: #666; margin-bottom: 25px;">Recurring support for sustainable development</p>

            <div class="pricing-grid">
                <div class="pricing-card" onclick="checkout('monthly_5')">
                    <div class="pricing-title">Friend</div>
                    <div class="pricing-amount">$5<span class="pricing-interval">/mo</span></div>
                    <div class="pricing-description">Join the community</div>
                    <button>Subscribe $5/mo</button>
                </div>

                <div class="pricing-card featured" onclick="checkout('monthly_25')">
                    <span class="badge">Recommended</span>
                    <div class="pricing-title">Supporter</div>
                    <div class="pricing-amount">$25<span class="pricing-interval">/mo</span></div>
                    <div class="pricing-description">Sustainable support</div>
                    <button>Subscribe $25/mo</button>
                </div>

                <div class="pricing-card" onclick="checkout('monthly_100')">
                    <div class="pricing-title">Sponsor</div>
                    <div class="pricing-amount">$100<span class="pricing-interval">/mo</span></div>
                    <div class="pricing-description">Major sponsor recognition</div>
                    <button>Subscribe $100/mo</button>
                </div>
            </div>

            <h2 style="margin: 50px 0 10px;">Commercial Licensing</h2>
            <p style="color: #666; margin-bottom: 25px;">Use BlackRoad OS in your commercial products</p>

            <div class="pricing-grid">
                <div class="pricing-card" onclick="checkout('license_startup')">
                    <div class="pricing-title">Startup</div>
                    <div class="pricing-amount">$499<span class="pricing-interval">/year</span></div>
                    <div class="pricing-description">For startups < $1M revenue</div>
                    <ul class="pricing-features">
                        <li>Commercial use license</li>
                        <li>Email support</li>
                        <li>Updates & patches</li>
                    </ul>
                    <button>Get License</button>
                </div>

                <div class="pricing-card featured" onclick="checkout('license_business')">
                    <span class="badge">Best Value</span>
                    <div class="pricing-title">Business</div>
                    <div class="pricing-amount">$999<span class="pricing-interval">/year</span></div>
                    <div class="pricing-description">For established businesses</div>
                    <ul class="pricing-features">
                        <li>Commercial use license</li>
                        <li>Priority support</li>
                        <li>Custom integrations</li>
                        <li>Dedicated account manager</li>
                    </ul>
                    <button>Get License</button>
                </div>

                <div class="pricing-card" onclick="checkout('license_enterprise')">
                    <div class="pricing-title">Enterprise</div>
                    <div class="pricing-amount">$2,499<span class="pricing-interval">/year</span></div>
                    <div class="pricing-description">For large organizations</div>
                    <ul class="pricing-features">
                        <li>Unlimited commercial use</li>
                        <li>24/7 priority support</li>
                        <li>Custom development</li>
                        <li>SLA guarantee</li>
                        <li>On-site training</li>
                    </ul>
                    <button>Contact Sales</button>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>© 2023-2025 BlackRoad OS, Inc. All Rights Reserved.</p>
            <p style="margin-top: 10px; opacity: 0.8;">
                Payments processed securely by <strong>Stripe</strong>
            </p>
        </div>
    </div>

    <script>
        // Checkout via pay.blackroad.io payment gateway
        const PAY_GATEWAY = 'https://pay.blackroad.io';

        const tierMap = {
            'monthly_5': { tier: 'pro', interval: 'month' },
            'monthly_25': { tier: 'pro', interval: 'month' },
            'monthly_100': { tier: 'enterprise', interval: 'month' },
            'license_startup': { tier: 'pro', interval: 'year' },
            'license_business': { tier: 'enterprise', interval: 'year' },
            'license_enterprise': null, // contact sales
        };

        async function checkout(priceId) {
            const mapping = tierMap[priceId];
            if (!mapping) {
                window.location.href = 'mailto:blackroad.systems@gmail.com?subject=Enterprise%20License%20Inquiry';
                return;
            }
            try {
                const res = await fetch(PAY_GATEWAY + '/checkout', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(mapping),
                });
                const data = await res.json();
                if (data.url) window.location.href = data.url;
                else alert(data.error || 'Checkout failed');
            } catch (e) {
                alert('Network error. Try again.');
            }
        }
    </script>
</body>
</html>
"""

def generate_sponsor_readme():
    """Generate SPONSORS.md for all repos"""
    return """# Sponsors & Supporters

Thank you to all our sponsors and supporters who make BlackRoad OS possible!

## 🏆 Platinum Sponsors ($100+/month)

*Be the first! [Become a Platinum Sponsor](https://blackroad.io/sponsor)*

## 🥈 Gold Sponsors ($25+/month)

*Be the first! [Become a Gold Sponsor](https://blackroad.io/sponsor)*

## 🥉 Silver Sponsors ($5+/month)

*Be the first! [Become a Silver Sponsor](https://blackroad.io/sponsor)*

## 💝 One-Time Supporters

*Thank you to everyone who has made a one-time contribution!*

---

## Become a Sponsor

Support BlackRoad OS development:

- **$5/month** - Friend tier (community access)
- **$25/month** - Supporter tier (priority issues)
- **$100/month** - Sponsor tier (logo on website)
- **$500+** - Custom sponsorship package

[💝 Support Now](https://blackroad.io/sponsor)

---

## Commercial Licensing

Use BlackRoad OS in your commercial products:

- **Startup:** $499/year (< $1M revenue)
- **Business:** $999/year (established businesses)
- **Enterprise:** $2,499/year (unlimited use + SLA)

[📄 Get Commercial License](https://blackroad.io/license)

---

## Why Sponsor?

- ✅ Support open source AI infrastructure
- ✅ Get priority support and bug fixes
- ✅ Influence roadmap and features
- ✅ Company logo on our website
- ✅ Monthly sponsor updates

---

**BlackRoad OS, Inc.** - Building the future of AI infrastructure

*All sponsorships are tax-deductible for US businesses*
"""

def generate_stripe_webhook_handler():
    """Generate Stripe webhook handler"""
    return """#!/usr/bin/env python3
\"\"\"
Stripe Webhook Handler for BlackRoad OS
Handles payment events and updates sponsor database

Copyright: BlackRoad OS, Inc.
\"\"\"

import os
import json
from flask import Flask, request, jsonify
import stripe

app = Flask(__name__)

# Configure Stripe
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET')

@app.route('/webhook', methods=['POST'])
def webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, webhook_secret
        )
    except ValueError as e:
        return jsonify({'error': 'Invalid payload'}), 400
    except stripe.error.SignatureVerificationError as e:
        return jsonify({'error': 'Invalid signature'}), 400

    # Handle the event
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        handle_successful_payment(session)

    elif event['type'] == 'customer.subscription.created':
        subscription = event['data']['object']
        handle_new_subscription(subscription)

    elif event['type'] == 'customer.subscription.deleted':
        subscription = event['data']['object']
        handle_cancelled_subscription(subscription)

    return jsonify({'status': 'success'}), 200

def handle_successful_payment(session):
    # Update sponsor database
    # Send thank you email
    # Add to SPONSORS.md
    pass

def handle_new_subscription(subscription):
    # Add to recurring sponsors list
    # Send welcome email
    pass

def handle_cancelled_subscription(subscription):
    # Update sponsor status
    # Send follow-up email
    pass

if __name__ == '__main__':
    app.run(port=4242)
"""

def main():
    print("🚀 Setting up Stripe for all BlackRoad OS repositories...")

    # Generate files
    files_created = {
        'FUNDING.yml': generate_stripe_funding_file(),
        'sponsor.html': generate_stripe_payment_page_html(),
        'SPONSORS.md': generate_sponsor_readme(),
        'stripe_webhook.py': generate_stripe_webhook_handler()
    }

    # Save files
    for filename, content in files_created.items():
        with open(f'stripe/{filename}', 'w') as f:
            f.write(content)

    print(f"✅ Generated {len(files_created)} Stripe integration files")

    # Generate setup instructions
    instructions = {
        "setup_steps": [
            "1. Create Stripe account at https://stripe.com",
            "2. Get API keys from Stripe Dashboard",
            "3. Create products in Stripe for each pricing tier",
            "4. Update checkout URLs in sponsor.html",
            "5. Deploy webhook handler to Cloudflare Workers or Railway",
            "6. Add FUNDING.yml to all repos (.github/FUNDING.yml)",
            "7. Deploy sponsor.html to Cloudflare Pages (blackroad.io/sponsor)",
            "8. Update README.md in all repos with sponsor badge"
        ],
        "stripe_products_to_create": STRIPE_CONFIG['products'],
        "estimated_revenue_potential": {
            "monthly_recurring_low": 100,
            "monthly_recurring_mid": 500,
            "monthly_recurring_high": 2500,
            "one_time_annual_low": 5000,
            "one_time_annual_mid": 25000,
            "one_time_annual_high": 100000,
            "licensing_annual_conservative": 50000,
            "licensing_annual_optimistic": 500000
        }
    }

    with open('stripe/SETUP_INSTRUCTIONS.json', 'w') as f:
        json.dump(instructions, f, indent=2)

    print("\n📋 Setup Instructions:")
    for step in instructions['setup_steps']:
        print(f"   {step}")

    print("\n💰 Revenue Potential:")
    print(f"   Monthly (Low): ${instructions['estimated_revenue_potential']['monthly_recurring_low']}")
    print(f"   Monthly (Mid): ${instructions['estimated_revenue_potential']['monthly_recurring_mid']}")
    print(f"   Monthly (High): ${instructions['estimated_revenue_potential']['monthly_recurring_high']}")
    print(f"   Annual Licensing: ${instructions['estimated_revenue_potential']['licensing_annual_conservative']} - ${instructions['estimated_revenue_potential']['licensing_annual_optimistic']}")

    print("\n✅ Stripe integration files ready in stripe/ directory")
    print("   Next: Follow SETUP_INSTRUCTIONS.json to complete setup")

if __name__ == "__main__":
    # Create stripe directory
    os.makedirs('stripe', exist_ok=True)
    main()
