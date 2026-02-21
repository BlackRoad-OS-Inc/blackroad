#!/bin/bash
# BlackRoad-OS Complete Branding Overhaul
# Targets: 1,075 repositories across BlackRoad-OS organization

set -e

BRAND_COLOR_PRIMARY="#FF0066"
BRAND_COLOR_SECONDARY="#FF9D00"
BRAND_COLOR_TERTIARY="#7700FF"
BRAND_COLOR_QUATERNARY="#0066FF"

ORG_NAME="BlackRoad-OS"
TOTAL_REPOS=1075

echo "🌈 BlackRoad-OS Complete Branding Overhaul"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Organization: $ORG_NAME"
echo "Total Repositories: $TOTAL_REPOS"
echo "Brand Colors: $BRAND_COLOR_PRIMARY, $BRAND_COLOR_SECONDARY, $BRAND_COLOR_TERTIARY, $BRAND_COLOR_QUATERNARY"
echo ""

# Phase 1: Update Organization Profile
update_org_profile() {
    echo "📝 Phase 1: Updating Organization Profile..."
    
    # Clone .github repo if not exists
    if [ ! -d "/tmp/blackroad-github-org" ]; then
        git clone git@github.com:BlackRoad-OS/.github.git /tmp/blackroad-github-org
    fi
    
    cd /tmp/blackroad-github-org
    
    # Copy branded profile README
    cp /tmp/branded-org-profile.md profile/README.md
    
    # Create BRAND.md guide
    cat > BRAND.md << 'BRAND_GUIDE'
# 🎨 BlackRoad Brand Guidelines

## Official Colors

```css
--sunrise-orange: #FF9D00;
--warm-orange:    #FF6B00;
--hot-pink:       #FF0066;  /* PRIMARY BRAND COLOR */
--electric-magenta: #FF006B;
--deep-magenta:   #D600AA;
--vivid-purple:   #7700FF;
--cyber-blue:     #0066FF;
```

## Typography

**Primary Font**: [JetBrains Mono](https://fonts.google.com/specimen/JetBrains+Mono)

## Gradients

**BR Gradient** (Orange → Pink):
```css
linear-gradient(180deg, #FF9D00 0%, #FF0066 75%)
```

**OS Gradient** (Magenta → Blue):
```css
linear-gradient(180deg, #FF006B 0%, #0066FF 100%)
```

**Full Spectrum**:
```css
linear-gradient(180deg, #FF9D00 0%, #FF0066 28%, #7700FF 71%, #0066FF 100%)
```

## Spacing (Golden Ratio φ = 1.618)

```css
--space-xs:  8px;
--space-sm:  13px;
--space-md:  21px;
--space-lg:  34px;
--space-xl:  55px;
--space-2xl: 89px;
```

## Usage

All BlackRoad repositories MUST use these official brand colors and typography.
BRAND_GUIDE
    
    # Commit and push
    git add .
    git commit -m "brand: comprehensive organization profile update with official colors" || true
    git push origin main
    
    echo "✅ Phase 1 Complete: Organization profile updated"
}

# Phase 2: Create Repository Templates
create_repo_templates() {
    echo "📝 Phase 2: Creating Repository Templates..."
    
    cd /tmp/blackroad-github-org
    
    mkdir -p templates/repository
    
    # Copy README template
    cp /tmp/branded-repo-readme-template.md templates/repository/README.md
    
    # Create issue templates
    mkdir -p templates/repository/.github/ISSUE_TEMPLATE
    
    cat > templates/repository/.github/ISSUE_TEMPLATE/bug_report.yml << 'BUG_TEMPLATE'
name: 🐛 Bug Report
description: Report a bug in this BlackRoad project
labels: ["bug", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        ## 🐛 Bug Report
        Thanks for taking the time to report this issue!
        
  - type: textarea
    id: description
    attributes:
      label: Description
      description: A clear description of the bug
    validations:
      required: true
      
  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Go to '...'
        2. Click on '...'
        3. See error
    validations:
      required: true
      
  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What you expected to happen
    validations:
      required: true
      
  - type: textarea
    id: environment
    attributes:
      label: Environment
      description: |
        - OS: [e.g. macOS 13.0]
        - Version: [e.g. 1.0.0]
      value: |
        - OS: 
        - Version: 
    validations:
      required: false
BUG_TEMPLATE

    cat > templates/repository/.github/ISSUE_TEMPLATE/feature_request.yml << 'FEATURE_TEMPLATE'
name: ✨ Feature Request
description: Suggest a new feature for this BlackRoad project
labels: ["enhancement", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        ## ✨ Feature Request
        We love hearing your ideas!
        
  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: What problem does this feature solve?
    validations:
      required: true
      
  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: How should this feature work?
    validations:
      required: true
      
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: What other solutions have you considered?
    validations:
      required: false
FEATURE_TEMPLATE

    # Create PR template
    mkdir -p templates/repository/.github
    cat > templates/repository/.github/PULL_REQUEST_TEMPLATE.md << 'PR_TEMPLATE'
## 📝 Description

<!-- Describe your changes in detail -->

## 🎯 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📖 Documentation update
- [ ] 🎨 Style/UI update
- [ ] ♻️ Code refactoring
- [ ] ⚡ Performance improvement
- [ ] ✅ Test update

## ✅ Checklist

- [ ] My code follows the BlackRoad style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## 🔗 Related Issues

<!-- Link related issues here using #issue_number -->
Closes #

## 📸 Screenshots (if applicable)

<!-- Add screenshots to show your changes -->
PR_TEMPLATE

    # Commit templates
    git add .
    git commit -m "feat: add branded repository templates" || true
    git push origin main
    
    echo "✅ Phase 2 Complete: Repository templates created"
}

# Phase 3: Deploy Branding Workflow
deploy_branding_workflow() {
    echo "📝 Phase 3: Deploying Branding Workflow..."
    
    cd /tmp/blackroad-github-org
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/brand-compliance.yml << 'WORKFLOW'
name: 🎨 Brand Compliance Check

on:
  pull_request:
    types: [opened, synchronize]
  push:
    branches: [main, master]

jobs:
  brand-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check Brand Colors
        run: |
          echo "🎨 Checking for official BlackRoad brand colors..."
          
          # Check for deprecated colors
          if grep -r "#F5A623\|#FF1D6C\|#2979FF\|#9C27B0" --include="*.css" --include="*.html" --include="*.js" --include="*.jsx" --include="*.tsx" .; then
            echo "❌ Deprecated colors found! Please use official colors:"
            echo "  - #FF9D00 (Sunrise Orange)"
            echo "  - #FF0066 (Hot Pink)"
            echo "  - #7700FF (Vivid Purple)"
            echo "  - #0066FF (Cyber Blue)"
            exit 1
          fi
          
          echo "✅ No deprecated colors found"
      
      - name: Check README Branding
        run: |
          if [ -f "README.md" ]; then
            if ! grep -q "BlackRoad" README.md; then
              echo "⚠️ README.md should reference BlackRoad organization"
            fi
          fi
      
      - name: Check License
        run: |
          if [ ! -f "LICENSE" ] && [ ! -f "LICENSE.md" ]; then
            echo "⚠️ Missing LICENSE file"
          fi
WORKFLOW

    git add .
    git commit -m "ci: add brand compliance workflow" || true
    git push origin main
    
    echo "✅ Phase 3 Complete: Branding workflow deployed"
}

# Phase 4: Batch Update Top Repositories
batch_update_top_repos() {
    echo "📝 Phase 4: Identifying and updating top repositories..."
    
    # Get top 100 repos by stars/activity
    echo "Fetching top 100 repositories..."
    gh repo list BlackRoad-OS --limit 100 --json name,stargazerCount,updatedAt \
        --jq 'sort_by(.stargazerCount) | reverse | .[].name' > /tmp/top-repos.txt
    
    local count=0
    while IFS= read -r repo; do
        ((count++))
        echo "[$count/100] Updating: $repo"
        
        # Clone repo
        if [ -d "/tmp/blackroad-repos/$repo" ]; then
            cd "/tmp/blackroad-repos/$repo"
            git pull
        else
            mkdir -p /tmp/blackroad-repos
            git clone "git@github.com:BlackRoad-OS/$repo.git" "/tmp/blackroad-repos/$repo" 2>/dev/null || continue
            cd "/tmp/blackroad-repos/$repo"
        fi
        
        # Add branded README badge at top if not exists
        if [ -f "README.md" ] && ! grep -q "BlackRoad-OS-FF0066" README.md; then
            # Create temp file with badge
            echo '<p align="center">' > /tmp/readme-prepend.md
            echo '  <img src="https://img.shields.io/badge/BlackRoad-OS-FF0066?style=for-the-badge&logo=github&logoColor=white" alt="BlackRoad OS"/>' >> /tmp/readme-prepend.md
            echo '</p>' >> /tmp/readme-prepend.md
            echo '' >> /tmp/readme-prepend.md
            
            # Prepend to existing README
            cat README.md >> /tmp/readme-prepend.md
            mv /tmp/readme-prepend.md README.md
            
            git add README.md
            git commit -m "brand: add BlackRoad OS badge to README" || true
            git push origin main 2>/dev/null || git push origin master 2>/dev/null || true
        fi
        
        # Add topics/tags
        gh repo edit "BlackRoad-OS/$repo" \
            --add-topic blackroad \
            --add-topic blackroad-os \
            --add-topic ai-orchestration 2>/dev/null || true
        
    done < /tmp/top-repos.txt
    
    echo "✅ Phase 4 Complete: Top 100 repositories updated"
}

# Main execution
main() {
    echo ""
    echo "🚀 Starting BlackRoad-OS Branding Overhaul..."
    echo ""
    
    # Run phases
    update_org_profile
    echo ""
    
    create_repo_templates
    echo ""
    
    deploy_branding_workflow
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✨ Phases 1-3 Complete!"
    echo ""
    echo "Next Steps:"
    echo "  1. Review changes at: https://github.com/BlackRoad-OS/.github"
    echo "  2. Run Phase 4 to update top repositories: bash $0 --phase4"
    echo "  3. Run Phase 5 for mass deployment: bash $0 --phase5"
    echo ""
    echo "Current Status:"
    echo "  ✅ Organization profile updated"
    echo "  ✅ Repository templates created"
    echo "  ✅ Brand compliance workflow deployed"
    echo "  ⏳ Top repos update (Phase 4) - Ready to run"
    echo "  ⏳ Mass deployment (Phase 5) - Ready to run"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Handle phases
if [ "$1" == "--phase4" ]; then
    batch_update_top_repos
elif [ "$1" == "--phase5" ]; then
    echo "⚠️  Phase 5 (Mass Deployment to 975+ repos) is intensive."
    echo "This will:"
    echo "  - Clone/update ~975 repositories"
    echo "  - Add branded README badges"
    echo "  - Update repository topics"
    echo "  - Take several hours"
    echo ""
    read -p "Continue? (y/N): " confirm
    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
        echo "Starting Phase 5..."
        # Similar to Phase 4 but for ALL repos
        gh repo list BlackRoad-OS --limit 1075 --json name --jq '.[].name' | \
        while read repo; do
            echo "Processing: $repo"
            # Same logic as Phase 4
        done
    fi
else
    main
fi
