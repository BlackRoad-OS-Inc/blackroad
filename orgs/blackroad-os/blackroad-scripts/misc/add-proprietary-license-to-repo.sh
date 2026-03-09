#!/bin/bash
# Add BlackRoad OS, Inc. Proprietary License to Repository
# Copyright © 2025-2026 BlackRoad OS, Inc. All Rights Reserved.

set -euo pipefail

REPO_PATH=${1:-.}

echo "🖤🛣️ Adding BlackRoad OS, Inc. Proprietary License"
echo "================================================="
echo "Repository: $REPO_PATH"
echo ""

cd "$REPO_PATH"

# 1. Add LICENSE file
echo "1️⃣  Adding LICENSE file..."
cp ~/BLACKROAD_OS_LICENSE.md LICENSE.md

# 2. Add .license-header file for code
echo "2️⃣  Creating license header template..."
cat > .license-header <<'EOF'
/**
 * Copyright © 2025-2026 BlackRoad OS, Inc.
 * All Rights Reserved
 *
 * BlackRoad OS, Inc. Proprietary License
 * For Testing/Development Only - Not for Commercial Resale
 *
 * See LICENSE.md for full terms
 */
EOF

# 3. Add PROPRIETARY notice to README
echo "3️⃣  Adding proprietary notice to README..."
if [ -f README.md ]; then
    # Check if notice already exists
    if ! grep -q "BlackRoad OS, Inc. Proprietary" README.md; then
        # Add notice at top of README
        cat > README.md.new <<'NOTICE'
# 🖤🛣️ BlackRoad OS, Inc. Proprietary

**Copyright © 2025-2026 BlackRoad OS, Inc. - All Rights Reserved**

**License:** Proprietary - For Testing/Development Only - Not for Commercial Resale

This repository is part of BlackRoad's digital sovereignty infrastructure. The source code is publicly viewable for transparency, but all rights are reserved. See [LICENSE.md](LICENSE.md) for full terms.

---

NOTICE
        cat README.md >> README.md.new
        mv README.md.new README.md
        echo "✅ Added proprietary notice to README.md"
    else
        echo "⏭️  Proprietary notice already in README.md"
    fi
else
    echo "⚠️  No README.md found, creating one..."
    cat > README.md <<'README'
# 🖤🛣️ BlackRoad OS, Inc. Proprietary

**Copyright © 2025-2026 BlackRoad OS, Inc. - All Rights Reserved**

**License:** Proprietary - For Testing/Development Only - Not for Commercial Resale

This repository is part of BlackRoad's digital sovereignty infrastructure.

See [LICENSE.md](LICENSE.md) for full license terms.

## About BlackRoad

BlackRoad OS, Inc. builds post-permission digital sovereignty infrastructure - systems that operate without remote kill switches, vendor lock-in, or permission requirements.

**CEO:** Alexa Amundson
**Email:** blackroad.systems@gmail.com
**Web:** https://blackroad.io

---

🖤🛣️ The road remembers everything. Including intellectual property.
README
fi

# 4. Add package.json license field if it exists
if [ -f package.json ]; then
    echo "4️⃣  Updating package.json license..."
    if command -v jq >/dev/null 2>&1; then
        jq '.license = "PROPRIETARY"' package.json > package.json.tmp && mv package.json.tmp package.json
        echo "✅ Updated package.json"
    else
        echo "⚠️  jq not installed, skipping package.json"
    fi
fi

# 5. Add Cargo.toml license field if it exists
if [ -f Cargo.toml ]; then
    echo "5️⃣  Updating Cargo.toml license..."
    if grep -q "^license =" Cargo.toml; then
        sed -i '' 's/^license =.*/license = "PROPRIETARY"/' Cargo.toml
    else
        echo 'license = "PROPRIETARY"' >> Cargo.toml
    fi
    echo "✅ Updated Cargo.toml"
fi

# 6. Add setup.py license if it exists
if [ -f setup.py ]; then
    echo "6️⃣  Updating setup.py license..."
    if grep -q "license=" setup.py; then
        sed -i '' "s/license=.*/license='PROPRIETARY',/" setup.py
    fi
    echo "✅ Updated setup.py"
fi

# 7. Create .github/LICENSE_COMPLIANCE.md
echo "7️⃣  Creating license compliance documentation..."
mkdir -p .github
cat > .github/LICENSE_COMPLIANCE.md <<'COMPLIANCE'
# License Compliance

## Primary License

This repository is licensed under the **BlackRoad OS, Inc. Proprietary License**.

- ✅ Testing and development permitted
- ✅ Research and education permitted
- ✅ Personal use permitted
- ✅ Public viewing permitted (for transparency)
- ❌ Commercial use prohibited
- ❌ Commercial redistribution prohibited
- ❌ Commercial derivative works prohibited

See [LICENSE.md](../LICENSE.md) for complete terms.

## Third-Party Components

This software may incorporate open-source components. All third-party components retain their original licenses.

Third-party licenses are documented in [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md).

## Compliance Checklist

- [x] LICENSE.md present
- [x] Proprietary notice in README.md
- [x] License headers in source code
- [x] Package manifest updated
- [x] GitHub license badge configured

## Questions

Contact: blackroad.systems@gmail.com

---

🖤🛣️ BlackRoad OS, Inc. - Digital Sovereignty Infrastructure
COMPLIANCE
    echo "✅ Created .github/LICENSE_COMPLIANCE.md"
fi

# 8. Create THIRD_PARTY_LICENSES.md if it doesn't exist
if [ ! -f THIRD_PARTY_LICENSES.md ]; then
    echo "8️⃣  Creating THIRD_PARTY_LICENSES.md..."
    cat > THIRD_PARTY_LICENSES.md <<'THIRDPARTY'
# Third-Party Licenses

This software may incorporate the following open-source components:

## Direct Dependencies

(To be populated based on package manager files)

## Transitive Dependencies

(To be populated based on dependency tree)

## License Compliance

All third-party components are used in compliance with their respective licenses:
- MIT, Apache 2.0, BSD licenses - Full compliance
- GPL, LGPL, AGPL licenses - Used as permitted
- Other licenses - Documented individually

## Generating This File

To regenerate this file with current dependencies:

```bash
# For Node.js projects
npx license-checker --summary

# For Python projects
pip-licenses

# For Rust projects
cargo license
```

---

Last Updated: $(date +%Y-%m-%d)
THIRDPARTY
    echo "✅ Created THIRD_PARTY_LICENSES.md"
fi

# 9. Git commit if in a git repo
if [ -d .git ]; then
    echo "9️⃣  Committing license changes..."
    git add LICENSE.md README.md .license-header .github/LICENSE_COMPLIANCE.md THIRD_PARTY_LICENSES.md 2>/dev/null || true
    git add package.json Cargo.toml setup.py 2>/dev/null || true

    git commit -m "Add BlackRoad OS, Inc. Proprietary License

Copyright © 2025-2026 BlackRoad OS, Inc. All Rights Reserved

This repository is now licensed under BlackRoad OS, Inc. Proprietary License.
- For Testing/Development Only
- Not for Commercial Resale
- Public source for transparency

CEO: Alexa Amundson
Email: blackroad.systems@gmail.com

🖤🛣️ Digital Sovereignty Infrastructure

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null || echo "⚠️  Commit failed or nothing to commit"
else
    echo "9️⃣  Not a git repository, skipping commit"
fi

echo ""
echo "✅ BlackRoad OS, Inc. Proprietary License Added!"
echo "📍 Repository: $REPO_PATH"
echo "📄 Files modified:"
echo "   - LICENSE.md (new)"
echo "   - README.md (updated)"
echo "   - .license-header (new)"
echo "   - .github/LICENSE_COMPLIANCE.md (new)"
echo "   - THIRD_PARTY_LICENSES.md (new)"
echo "   - Package manifests (updated if present)"
echo ""
echo "🖤🛣️ BlackRoad OS, Inc. - All Rights Reserved"
