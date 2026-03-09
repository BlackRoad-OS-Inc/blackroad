#!/bin/bash
# 🔐 Integrate Clerk Authentication Across All BlackRoad Products
# Adds enterprise-grade authentication to all 24 products

echo "🔐 BlackRoad Clerk Authentication Integration"
echo "========================================="
echo ""

# All 24 products
PRODUCTS=(
    "roadauth"
    "roadapi"
    "roadbilling"
    "blackroad-ai-platform"
    "blackroad-langchain-studio"
    "roadsupport"
    "blackroad-admin-portal"
    "blackroad-meet"
    "blackroad-minio"
    "blackroad-docs-site"
    "blackroad-vllm"
    "blackroad-keycloak"
    "roadlog-monitoring"
    "roadvpn"
    "blackroad-localai"
    "roadnote"
    "roadscreen"
    "genesis-road"
    "roadgateway"
    "roadmobile"
    "roadcli"
    "roadauth-pro"
    "roadstudio"
    "roadmarket"
)

integrated_count=0
skipped_count=0

echo "📝 Clerk Configuration Setup"
echo "========================================="
echo ""

# Create Clerk configuration template
cat > "$HOME/clerk-config.json" <<EOF
{
  "clerk": {
    "publishableKey": "pk_test_YOUR_PUBLISHABLE_KEY",
    "secretKey": "sk_test_YOUR_SECRET_KEY",
    "frontendApi": "clerk.YOUR_DOMAIN.com",
    "features": {
      "socialLogin": ["google", "github", "apple"],
      "mfa": true,
      "passwordless": true,
      "organizations": true
    },
    "appearance": {
      "theme": "dark",
      "variables": {
        "colorPrimary": "#F5A623",
        "colorDanger": "#FF1D6C",
        "colorSuccess": "#2ECC71",
        "colorWarning": "#F5A623",
        "fontFamily": "SF Pro Display, -apple-system, sans-serif",
        "borderRadius": "13px"
      }
    }
  }
}
EOF

echo "✅ Clerk configuration template created: ~/clerk-config.json"
echo ""

# Create Clerk integration script for each product
echo "========================================="
echo "🔧 Creating Clerk Integration Components"
echo "========================================="
echo ""

for product in "${PRODUCTS[@]}"; do
    product_dir="$HOME/$product"

    if [ ! -d "$product_dir" ]; then
        echo "⚠️  $product - Directory not found, SKIPPING"
        ((skipped_count++))
        continue
    fi

    echo "📦 Integrating: $product"

    # Create clerk-integration directory
    clerk_dir="$product_dir/clerk-integration"
    mkdir -p "$clerk_dir"

    # Create Clerk HTML components
    cat > "$clerk_dir/clerk-auth.html" <<'CLERK_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In - BlackRoad</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'SF Pro Display', -apple-system, sans-serif;
            background: #000;
            color: #FFF;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .auth-container {
            width: 100%;
            max-width: 450px;
            padding: 34px;
        }
        .auth-header {
            text-align: center;
            margin-bottom: 34px;
        }
        .auth-logo {
            font-size: 55px;
            margin-bottom: 21px;
        }
        .auth-title {
            font-size: 34px;
            font-weight: 700;
            background: linear-gradient(135deg, #F5A623 38.2%, #2979FF 61.8%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 13px;
        }
        .auth-subtitle {
            font-size: 16px;
            opacity: 0.7;
        }
        #clerk-auth {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 13px;
            padding: 34px;
        }
        .loading {
            text-align: center;
            padding: 55px;
            opacity: 0.7;
        }
    </style>
</head>
<body>
    <div class="auth-container">
        <div class="auth-header">
            <div class="auth-logo">🖤</div>
            <h1 class="auth-title">Welcome to BlackRoad</h1>
            <p class="auth-subtitle">Sign in to continue</p>
        </div>
        <div id="clerk-auth">
            <div class="loading">Loading authentication...</div>
        </div>
    </div>

    <!-- Clerk SDK -->
    <script
        async
        crossorigin="anonymous"
        data-clerk-publishable-key="pk_test_YOUR_PUBLISHABLE_KEY"
        src="https://YOUR_FRONTEND_API/npm/@clerk/clerk-js@latest/dist/clerk.browser.js"
        type="text/javascript"
    ></script>

    <script>
        window.addEventListener('load', async () => {
            await Clerk.load();

            const signInDiv = document.getElementById('clerk-auth');

            // Mount Clerk sign-in component
            Clerk.mountSignIn(signInDiv, {
                appearance: {
                    elements: {
                        rootBox: 'w-full',
                        card: 'bg-transparent border-none shadow-none'
                    },
                    variables: {
                        colorPrimary: '#F5A623',
                        colorText: '#FFFFFF',
                        colorBackground: '#000000',
                        fontFamily: 'SF Pro Display, -apple-system, sans-serif'
                    }
                },
                afterSignInUrl: '/dashboard',
                signUpUrl: '/sign-up'
            });

            // Check if user is already signed in
            if (Clerk.user) {
                window.location.href = '/dashboard';
            }
        });
    </script>
</body>
</html>
CLERK_HTML

    # Create protected route wrapper
    cat > "$clerk_dir/clerk-protected.js" <<'CLERK_JS'
// 🔐 Clerk Protected Route Wrapper
// Add this to any page that requires authentication

(function() {
    // Wait for Clerk to load
    window.addEventListener('load', async () => {
        // Check if Clerk is loaded
        if (typeof Clerk === 'undefined') {
            console.error('Clerk not loaded');
            return;
        }

        await Clerk.load();

        // Check if user is authenticated
        if (!Clerk.user) {
            // Redirect to sign-in
            window.location.href = '/clerk-integration/clerk-auth.html';
            return;
        }

        // User is authenticated
        console.log('✅ User authenticated:', Clerk.user.fullName);

        // Add user info to page
        addUserInfo(Clerk.user);

        // Add sign-out button
        addSignOutButton();
    });

    function addUserInfo(user) {
        const userInfoDiv = document.createElement('div');
        userInfoDiv.id = 'clerk-user-info';
        userInfoDiv.style.cssText = `
            position: fixed;
            top: 21px;
            right: 21px;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 13px;
            padding: 13px 21px;
            display: flex;
            align-items: center;
            gap: 13px;
            z-index: 1000;
        `;

        userInfoDiv.innerHTML = `
            <img src="${user.profileImageUrl}" alt="${user.fullName}"
                 style="width: 34px; height: 34px; border-radius: 50%;">
            <div>
                <div style="font-weight: 600; font-size: 14px;">${user.fullName || user.username}</div>
                <div style="font-size: 12px; opacity: 0.7;">${user.primaryEmailAddress.emailAddress}</div>
            </div>
        `;

        document.body.appendChild(userInfoDiv);
    }

    function addSignOutButton() {
        const signOutBtn = document.createElement('button');
        signOutBtn.textContent = 'Sign Out';
        signOutBtn.style.cssText = `
            position: fixed;
            top: 89px;
            right: 21px;
            background: linear-gradient(135deg, #F5A623 38.2%, #FF1D6C 61.8%);
            color: white;
            border: none;
            border-radius: 8px;
            padding: 8px 21px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            z-index: 1000;
        `;

        signOutBtn.addEventListener('click', async () => {
            await Clerk.signOut();
            window.location.href = '/clerk-integration/clerk-auth.html';
        });

        document.body.appendChild(signOutBtn);
    }
})();
CLERK_JS

    # Create integration README
    cat > "$clerk_dir/README.md" <<EOF
# Clerk Authentication Integration for $product

## Setup Instructions

### 1. Get Clerk API Keys

1. Sign up at [clerk.com](https://clerk.com)
2. Create a new application
3. Get your publishable key (pk_test_...) and secret key (sk_test_...)
4. Update the keys in:
   - \`clerk-auth.html\` (line 66)
   - Main \`index.html\` (add Clerk SDK)

### 2. Update Main HTML File

Add Clerk SDK to \`index.html\` before closing \`</body>\`:

\`\`\`html
<!-- Clerk SDK -->
<script
    async
    crossorigin="anonymous"
    data-clerk-publishable-key="pk_test_YOUR_KEY"
    src="https://YOUR_FRONTEND_API/npm/@clerk/clerk-js@latest/dist/clerk.browser.js"
></script>

<!-- Clerk Protected Route -->
<script src="./clerk-integration/clerk-protected.js"></script>
\`\`\`

### 3. Configure Clerk Dashboard

1. **Allowed Origins**: Add your domain(s)
   - http://localhost:*
   - https://YOUR_CLOUDFLARE_PAGES.pages.dev
   - https://YOUR_CUSTOM_DOMAIN.com

2. **Social Login** (optional):
   - Enable Google, GitHub, Apple
   - Configure OAuth apps

3. **Appearance**:
   - Theme: Dark
   - Primary color: #F5A623

### 4. Deploy

\`\`\`bash
# Update Clerk keys in files
# Deploy to Cloudflare Pages
wrangler pages deploy .
\`\`\`

### 5. Test

1. Visit your site
2. You'll be redirected to sign-in
3. Create account or sign in
4. Access protected content

## Features Enabled

✅ Email/password authentication
✅ Social login (Google, GitHub, Apple)
✅ Multi-factor authentication (MFA)
✅ Passwordless sign-in
✅ User profile management
✅ Session management
✅ Organization support (teams)

## Files Created

- \`clerk-auth.html\` - Sign-in/sign-up page
- \`clerk-protected.js\` - Route protection script
- \`README.md\` - This file

## API Usage

\`\`\`javascript
// Get current user
const user = Clerk.user;

// Sign out
await Clerk.signOut();

// Check authentication
if (Clerk.user) {
    console.log('Authenticated');
}
\`\`\`

🖤🛣️ Secure authentication powered by Clerk
EOF

    ((integrated_count++))
    echo "   ✅ Clerk integration created: $clerk_dir"
    echo ""
done

# Create master Clerk setup guide
echo "========================================="
echo "📚 Creating Master Setup Guide"
echo "========================================="
echo ""

cat > "$HOME/CLERK_INTEGRATION_GUIDE.md" <<'GUIDE'
# 🔐 BlackRoad Clerk Authentication - Master Guide

Complete guide for integrating Clerk authentication across all 24 BlackRoad products.

## Overview

Clerk provides enterprise-grade authentication with:
- **Email/Password**: Traditional authentication
- **Social Login**: Google, GitHub, Apple, Microsoft
- **Passwordless**: Magic links, SMS codes
- **Multi-Factor**: TOTP, SMS, email codes
- **Organizations**: Team/workspace support
- **Session Management**: Secure JWT tokens

## Quick Start

### 1. Create Clerk Account

```bash
# Visit Clerk
open https://clerk.com

# Create account and application
# Get API keys from dashboard
```

### 2. Update Configuration

Edit `~/clerk-config.json`:
```json
{
  "publishableKey": "pk_test_YOUR_KEY",
  "secretKey": "sk_test_YOUR_SECRET",
  "frontendApi": "clerk.YOUR_APP.com"
}
```

### 3. Integrate Products

Each product in `~/[product]/clerk-integration/` contains:
- `clerk-auth.html` - Sign-in page
- `clerk-protected.js` - Route protection
- `README.md` - Product-specific setup

### 4. Deploy

```bash
# For each product:
cd ~/[product]

# Update Clerk keys in clerk-integration files
# Deploy to Cloudflare
wrangler pages deploy .
```

## Product-Specific Integration

### RoadAuth Pro
- Already has auth system, enhance with Clerk
- Enable SSO integration
- Add MFA enforcement

### RoadMarket
- Protect seller dashboard
- User verification for payments
- Organization support for teams

### RoadStudio
- Protect video projects
- Team collaboration features
- Cloud storage authentication

### BlackRoad AI Platform
- API key management via Clerk
- Usage tracking per user
- Organization billing

## Advanced Features

### Custom Branding

```javascript
Clerk.load({
  appearance: {
    variables: {
      colorPrimary: '#F5A623',
      colorBackground: '#000000',
      colorText: '#FFFFFF',
      fontFamily: 'SF Pro Display'
    }
  }
});
```

### Organization Support

```javascript
// Create organization
await Clerk.createOrganization({
  name: "BlackRoad Team"
});

// Switch organization
await Clerk.setActiveOrganization(orgId);
```

### Webhooks

Configure webhooks in Clerk dashboard:
- `user.created` - Send welcome email
- `session.created` - Track logins
- `organization.membership.created` - Team notifications

## Security Best Practices

1. **Never commit API keys** - Use environment variables
2. **Enable MFA** for admin accounts
3. **Use organizations** for team features
4. **Implement RBAC** with Clerk metadata
5. **Monitor sessions** via Clerk dashboard

## Pricing

- **Free**: 10,000 MAUs
- **Pro**: $25/mo + $0.02/MAU
- **Enterprise**: Custom pricing

## Resources

- [Clerk Docs](https://clerk.com/docs)
- [React Integration](https://clerk.com/docs/quickstarts/react)
- [API Reference](https://clerk.com/docs/reference/backend-api)
- [Community](https://clerk.com/discord)

## Support

Issues? Contact:
- Clerk: support@clerk.com
- BlackRoad: blackroad.systems@gmail.com

🖤🛣️ Secure. Simple. Scalable.
GUIDE

echo "✅ Master guide created: ~/CLERK_INTEGRATION_GUIDE.md"
echo ""

# Summary
echo "========================================="
echo "📊 Integration Summary"
echo "========================================="
echo ""
echo "✅ Products integrated: $integrated_count"
echo "⏭️  Products skipped: $skipped_count"
echo ""
echo "📦 Created Files:"
echo "   - ~/clerk-config.json (Clerk configuration)"
echo "   - ~/CLERK_INTEGRATION_GUIDE.md (Master guide)"
echo "   - ~/[product]/clerk-integration/ (Integration files for each product)"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "1. Create Clerk account:"
echo "   https://clerk.com"
echo ""
echo "2. Get API keys from Clerk dashboard"
echo ""
echo "3. Update keys in:"
echo "   - ~/clerk-config.json"
echo "   - Each product's clerk-integration files"
echo ""
echo "4. Configure Clerk dashboard:"
echo "   - Add allowed origins (Cloudflare Pages domains)"
echo "   - Enable social providers (Google, GitHub, Apple)"
echo "   - Set up appearance (dark theme, BlackRoad colors)"
echo ""
echo "5. Deploy products with Clerk integration:"
echo "   cd ~/[product] && wrangler pages deploy ."
echo ""
echo "📚 Read the master guide:"
echo "   cat ~/CLERK_INTEGRATION_GUIDE.md"
echo ""
echo "🖤🛣️ Enterprise Authentication Ready!"
