#!/bin/bash
# Automated Job Finder and Application Preparer
# Searches job boards and prepares application materials automatically

RESUME_DIR="$HOME/blackroad-resume"
JOBS_SYSTEM="$RESUME_DIR/job-application-system.sh"

# Target roles based on resume variants
declare -A ROLE_KEYWORDS=(
    ["platform"]="Platform Engineer,SRE,Site Reliability,DevOps Engineer,Infrastructure Engineer"
    ["founder"]="CTO,Technical Founder,VP Engineering,Engineering Director,Technical Architect"
    ["ai"]="AI Engineer,ML Engineer,LLM Engineer,AI Infrastructure,Machine Learning"
    ["sales"]="Solutions Engineer,Sales Engineer,Solutions Architect,Technical Account Manager"
    ["devrel"]="Developer Advocate,DevRel,Developer Relations,Technical Evangelist,Community Engineer"
)

# Target companies (top priority)
TARGET_COMPANIES=(
    "Cloudflare"
    "Anthropic"
    "Vercel"
    "Railway"
    "GitHub"
    "HuggingFace"
    "Supabase"
    "PlanetScale"
    "Modal"
    "Replicate"
    "Fly.io"
    "Netlify"
    "DigitalOcean"
    "OpenAI"
    "Anyscale"
)

# Job board URLs
search_linkedin() {
    local keywords="$1"
    local encoded=$(echo "$keywords" | sed 's/ /%20/g')
    echo "https://www.linkedin.com/jobs/search/?keywords=$encoded&location=Remote"
}

search_indeed() {
    local keywords="$1"
    local encoded=$(echo "$keywords" | sed 's/ /+/g')
    echo "https://www.indeed.com/jobs?q=$encoded&l=Remote"
}

search_wellfound() {
    local keywords="$1"
    local encoded=$(echo "$keywords" | sed 's/ /%20/g')
    echo "https://wellfound.com/jobs?keywords=$encoded"
}

# Auto-generate application for a specific company/role
auto_prepare() {
    local company="$1"
    local role="$2"
    local url="${3:-https://careers.$company.com}"
    local variant="${4:-platform}"

    echo "🤖 Auto-preparing application..."
    echo "Company: $company"
    echo "Role: $role"
    echo "Variant: $variant"
    echo ""

    # Add to tracking system
    "$JOBS_SYSTEM" add "$company" "$role" "$url" "$variant"

    # Prepare materials
    local job_id=$(echo "$company-$role" | tr '[:upper:] ' '[:lower:]-')
    "$JOBS_SYSTEM" prepare "$job_id"

    echo ""
    echo "✅ Application materials ready!"
    echo "📁 Location: ~/.blackroad/jobs/$job_id/"
    echo ""
    echo "Next steps:"
    echo "1. Review and customize cover letter"
    echo "2. Check company research"
    echo "3. Submit application"
    echo "4. Mark as applied: $JOBS_SYSTEM status $job_id applied"
}

# Batch prepare applications for target companies
batch_prepare() {
    local role_type="${1:-platform}"
    local roles="${ROLE_KEYWORDS[$role_type]}"

    echo "🚀 Batch preparing applications for: $role_type roles"
    echo "Target companies: ${#TARGET_COMPANIES[@]}"
    echo ""

    local count=0
    for company in "${TARGET_COMPANIES[@]}"; do
        # Get first matching role for this company
        local role=$(echo "$roles" | cut -d',' -f1)

        echo "[$((count+1))/${#TARGET_COMPANIES[@]}] Preparing: $company - $role"

        auto_prepare "$company" "$role" "https://careers.${company,,}.com" "$role_type"

        ((count++))
        echo ""
        sleep 1  # Brief pause between preparations
    done

    echo "✅ Batch preparation complete!"
    echo "Total applications prepared: $count"
    echo ""
    echo "View all: $JOBS_SYSTEM list"
}

# Search and display job URLs
search_all() {
    local query="$1"

    if [ -z "$query" ]; then
        echo "Usage: $0 search <role>"
        echo "Example: $0 search 'Platform Engineer'"
        return 1
    fi

    echo "🔍 Job Search: $query"
    echo "===================="
    echo ""

    echo "LinkedIn:"
    search_linkedin "$query"
    echo ""

    echo "Indeed:"
    search_indeed "$query"
    echo ""

    echo "Wellfound (AngelList):"
    search_wellfound "$query"
    echo ""

    echo "Company Career Pages:"
    for company in "${TARGET_COMPANIES[@]}"; do
        echo "  - $company: https://careers.${company,,}.com"
    done
}

# Generate application summary
summary() {
    echo "📊 Application System Summary"
    echo "=============================="
    echo ""

    echo "Available Resume Variants:"
    for variant in "${!ROLE_KEYWORDS[@]}"; do
        echo "  - $variant: ${ROLE_KEYWORDS[$variant]}"
    done
    echo ""

    echo "Target Companies (${#TARGET_COMPANIES[@]} total):"
    local i=1
    for company in "${TARGET_COMPANIES[@]}"; do
        echo "  $i. $company"
        ((i++))
    done
    echo ""

    echo "Portfolio URLs:"
    echo "  - Main: https://production.resume-blackroad-io.pages.dev"
    echo "  - GitHub: https://github.com/blackboxprogramming/alexa-amundson-portfolio"
    echo "  - Demo: https://5d7fe908.blackroad-monitoring.pages.dev"
    echo ""

    echo "Commands:"
    echo "  Search jobs: $0 search '<role>'"
    echo "  Prepare single: $0 prepare <company> <role> [url] [variant]"
    echo "  Batch prepare: $0 batch [platform|ai|devrel|sales|founder]"
    echo "  View status: $JOBS_SYSTEM list"
}

# Quick apply workflow
quick_apply() {
    echo "🚀 Quick Apply Workflow"
    echo "======================="
    echo ""
    echo "Step 1: Choose your primary role focus"
    echo "  platform  - Platform Engineer, SRE, DevOps"
    echo "  ai        - AI/ML Engineer, LLM Infrastructure"
    echo "  devrel    - Developer Advocate, DevRel"
    echo "  sales     - Solutions Engineer, Sales Engineer"
    echo "  founder   - CTO, VP Engineering, Technical Founder"
    echo ""
    echo -n "Enter role type [platform]: "
    read role_type
    role_type=${role_type:-platform}

    echo ""
    echo "Step 2: Batch preparing applications for ${#TARGET_COMPANIES[@]} companies..."
    sleep 1

    batch_prepare "$role_type"

    echo ""
    echo "Step 3: Next Actions"
    echo "-------------------"
    echo "1. Review prepared applications:"
    echo "   cd ~/.blackroad/jobs && ls -la"
    echo ""
    echo "2. Customize cover letters (find/replace placeholders)"
    echo ""
    echo "3. Post portfolio on LinkedIn:"
    echo "   'Just deployed my technical portfolio with 100% verified metrics:'"
    echo "   '🚀 899,160+ LOC | 125 deploys @ 100% success | $0/month infra'"
    echo "   'https://production.resume-blackroad-io.pages.dev'"
    echo ""
    echo "4. Start applying (goal: 5 per day)"
    echo ""
    echo "5. Track applications:"
    echo "   $JOBS_SYSTEM list"
}

# Main command dispatcher
case "$1" in
    search)
        search_all "$2"
        ;;
    prepare)
        auto_prepare "$2" "$3" "$4" "$5"
        ;;
    batch)
        batch_prepare "$2"
        ;;
    summary)
        summary
        ;;
    quick)
        quick_apply
        ;;
    *)
        echo "Automated Job Finder & Application System"
        echo "=========================================="
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  search <role>                    Search job boards for role"
        echo "  prepare <company> <role> [url]   Prepare single application"
        echo "  batch [variant]                  Batch prepare for all targets"
        echo "  quick                            Interactive quick apply"
        echo "  summary                          Show system overview"
        echo ""
        echo "Examples:"
        echo "  $0 search 'Platform Engineer'"
        echo "  $0 prepare Cloudflare 'Solutions Engineer'"
        echo "  $0 batch platform"
        echo "  $0 quick"
        echo ""
        echo "Target Companies: ${#TARGET_COMPANIES[@]}"
        echo "Resume Variants: ${#ROLE_KEYWORDS[@]}"
        echo "Portfolio: https://production.resume-blackroad-io.pages.dev"
        ;;
esac
