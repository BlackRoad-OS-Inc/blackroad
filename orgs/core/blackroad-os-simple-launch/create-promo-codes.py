#!/usr/bin/env python3
"""
Create Stripe promotional codes for BlackRoad OS campaigns
"""

import stripe
import os
import sys

# Stripe API key (load from environment or ~/.stripe_keys)
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')

if not stripe.api_key:
    try:
        with open(os.path.expanduser('~/.stripe_keys'), 'r') as f:
            for line in f:
                if line.startswith('STRIPE_SECRET_KEY='):
                    stripe.api_key = line.split('=', 1)[1].strip()
                    break
    except FileNotFoundError:
        print("❌ Error: ~/.stripe_keys not found")
        sys.exit(1)

if not stripe.api_key:
    print("❌ Error: STRIPE_SECRET_KEY not configured")
    sys.exit(1)

def create_promo_codes():
    """Create promotional discount codes for various campaigns"""

    promo_codes = []

    # 1. PRODUCTHUNT - Extra month free for Product Hunt launch
    print("Creating PRODUCTHUNT code...")
    ph_coupon = stripe.Coupon.create(
        percent_off=100,
        duration="once",  # 100% off for 1 month
        name="Product Hunt Launch - Free Extra Month"
    )

    ph_promo = stripe.PromotionCode.create(
        coupon=ph_coupon.id,
        code="PRODUCTHUNT",
        max_redemptions=500
    )
    promo_codes.append(("PRODUCTHUNT", "100% off first month", ph_promo.id))

    # 2. LAUNCH50 - 50% off first 3 months for general launch
    print("Creating LAUNCH50 code...")
    launch_coupon = stripe.Coupon.create(
        percent_off=50,
        duration="repeating",
        duration_in_months=3,
        name="Launch Special - 50% Off 3 Months"
    )

    launch_promo = stripe.PromotionCode.create(
        coupon=launch_coupon.id,
        code="LAUNCH50",
        max_redemptions=1000
    )
    promo_codes.append(("LAUNCH50", "50% off for 3 months", launch_promo.id))

    # 3. TWITTER20 - 20% off first month for Twitter audience
    print("Creating TWITTER20 code...")
    twitter_coupon = stripe.Coupon.create(
        percent_off=20,
        duration="once",
        name="Twitter Launch - 20% Off"
    )

    twitter_promo = stripe.PromotionCode.create(
        coupon=twitter_coupon.id,
        code="TWITTER20",
        max_redemptions=500
    )
    promo_codes.append(("TWITTER20", "20% off first month", twitter_promo.id))

    # 4. FRIEND25 - 25% off forever for referrals (simulated affiliate)
    print("Creating FRIEND25 code...")
    friend_coupon = stripe.Coupon.create(
        percent_off=25,
        duration="forever",  # Permanent 25% discount
        name="Friend Referral - 25% Off Forever"
    )

    friend_promo = stripe.PromotionCode.create(
        coupon=friend_coupon.id,
        code="FRIEND25",
        max_redemptions=100
    )
    promo_codes.append(("FRIEND25", "25% off FOREVER", friend_promo.id))

    # 5. BLACKFRIDAY - 60% off first year (for future use)
    print("Creating BLACKFRIDAY code...")
    bf_coupon = stripe.Coupon.create(
        percent_off=60,
        duration="repeating",
        duration_in_months=12,
        name="Black Friday 2025 - 60% Off Year"
    )

    bf_promo = stripe.PromotionCode.create(
        coupon=bf_coupon.id,
        code="BLACKFRIDAY",
        max_redemptions=200
    )
    promo_codes.append(("BLACKFRIDAY", "60% off for 12 months", bf_promo.id))

    # 6. STUDENT50 - 50% off forever for students
    print("Creating STUDENT50 code...")
    student_coupon = stripe.Coupon.create(
        percent_off=50,
        duration="forever",
        name="Student Discount - 50% Off Forever"
    )

    student_promo = stripe.PromotionCode.create(
        coupon=student_coupon.id,
        code="STUDENT50",
        max_redemptions=500
    )
    promo_codes.append(("STUDENT50", "50% off FOREVER (students)", student_promo.id))

    # 7. WELCOME10 - 10% off first month for newsletter signups
    print("Creating WELCOME10 code...")
    welcome_coupon = stripe.Coupon.create(
        percent_off=10,
        duration="once",
        name="Newsletter Welcome - 10% Off"
    )

    welcome_promo = stripe.PromotionCode.create(
        coupon=welcome_coupon.id,
        code="WELCOME10"
    )
    promo_codes.append(("WELCOME10", "10% off first month", welcome_promo.id))

    return promo_codes


def main():
    print("\n🎁 Creating Stripe Promotional Codes for BlackRoad OS...\n")
    print("=" * 70)

    try:
        promo_codes = create_promo_codes()

        print("\n" + "=" * 70)
        print("\n✅ SUCCESS! All promo codes created:\n")

        for code, description, promo_id in promo_codes:
            print(f"   {code:<20} → {description}")
            print(f"   {'Promo ID:':<20} {promo_id}")
            print()

        print("=" * 70)
        print("\n📋 How to Use These Codes:\n")
        print("1. Add to payment links:")
        print("   - Go to https://dashboard.stripe.com/payment-links")
        print("   - Edit each payment link")
        print("   - Enable 'Allow promotion codes'")
        print()
        print("2. Share codes in:")
        print("   - Product Hunt launch post")
        print("   - Twitter announcements")
        print("   - Email campaigns")
        print("   - Landing page banners")
        print()
        print("3. Track usage:")
        print("   - Dashboard → Coupons → View redemptions")
        print("   - See which campaigns perform best")
        print()
        print("=" * 70)
        print("\n💡 Pro Tips:\n")
        print("   • PRODUCTHUNT - Use in PH launch comment")
        print("   • LAUNCH50 - Feature on homepage banner")
        print("   • STUDENT50 - Share in student communities")
        print("   • FRIEND25 - Give to affiliates as referral code")
        print()
        print("=" * 70)

    except stripe.error.StripeError as e:
        print(f"\n❌ Error: {e}")
        print("\nMake sure your Stripe API key is correct and active.")


if __name__ == "__main__":
    main()
