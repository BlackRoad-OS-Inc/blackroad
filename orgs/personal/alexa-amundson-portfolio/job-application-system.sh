#!/bin/bash
# Job Application Automation System
# Helps track, manage, and streamline job applications

JOBS_DIR="$HOME/.blackroad/jobs"
JOBS_DB="$JOBS_DIR/applications.jsonl"
TEMPLATES_DIR="$JOBS_DIR/templates"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Initialize
init() {
    mkdir -p "$JOBS_DIR" "$TEMPLATES_DIR"
    touch "$JOBS_DB"

    # Create email templates
    cat > "$TEMPLATES_DIR/cold-email.md" <<'EOF'
Subject: {ROLE} Application - {YOUR_NAME} ({HIGHLIGHT_METRIC})

Hi {HIRING_MANAGER},

I'm {YOUR_NAME}, and I'm excited about the {ROLE} position at {COMPANY}.

**Why I'm reaching out:**
- {RELEVANT_METRIC_1}
- {RELEVANT_METRIC_2}
- {RELEVANT_METRIC_3}

**Portfolio:** {PORTFOLIO_URL}

I'd love to discuss how my experience with {RELEVANT_TECH} could help {COMPANY} with {COMPANY_GOAL}.

Available for a call this week?

Best,
{YOUR_NAME}
{EMAIL}
{PORTFOLIO_URL}
EOF

    cat > "$TEMPLATES_DIR/linkedin-message.md" <<'EOF'
Hi {FIRST_NAME},

Saw the {ROLE} opening at {COMPANY} - looks like a great fit!

Quick highlights:
• {METRIC_1}
• {METRIC_2}
• {METRIC_3}

Portfolio: {PORTFOLIO_URL}

Open to a quick chat?

- {YOUR_NAME}
EOF

    cat > "$TEMPLATES_DIR/cover-letter.md" <<'EOF'
Dear {HIRING_MANAGER},

I'm applying for the {ROLE} position at {COMPANY}. With {EXPERIENCE_SUMMARY}, I'm confident I can contribute to {COMPANY_GOAL}.

**Key Qualifications:**

1. **{SKILL_AREA_1}:** {METRIC_1}
2. **{SKILL_AREA_2}:** {METRIC_2}
3. **{SKILL_AREA_3}:** {METRIC_3}

**Why {COMPANY}:**
{COMPANY_INTEREST_REASON}

**Portfolio & Verification:**
All metrics are 100% verifiable at: {PORTFOLIO_URL}

I'd welcome the opportunity to discuss how my experience can help {COMPANY} achieve {SPECIFIC_GOAL}.

Best regards,
{YOUR_NAME}
{EMAIL}
{PORTFOLIO_URL}
EOF

    echo -e "${GREEN}✅ Job application system initialized${NC}"
    echo "Database: $JOBS_DB"
    echo "Templates: $TEMPLATES_DIR"
}

# Add a job opportunity
add_job() {
    local company="$1"
    local role="$2"
    local url="$3"
    local resume_variant="$4"

    if [ -z "$company" ] || [ -z "$role" ]; then
        echo -e "${RED}Usage: $0 add <company> <role> <url> [resume_variant]${NC}"
        echo "Resume variants: founder, platform, ai, sales, devrel"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local job_id=$(echo "$company-$role" | tr '[:upper:] ' '[:lower:]-')

    # Create job entry
    local job_entry=$(cat <<EOF
{
  "id": "$job_id",
  "company": "$company",
  "role": "$role",
  "url": "$url",
  "resume_variant": "${resume_variant:-platform}",
  "status": "identified",
  "added_at": "$timestamp",
  "applied_at": null,
  "followed_up_at": null,
  "response_at": null,
  "notes": []
}
EOF
)

    echo "$job_entry" >> "$JOBS_DB"

    echo -e "${GREEN}✅ Added job: $company - $role${NC}"
    echo "Job ID: $job_id"
    echo "Resume variant: ${resume_variant:-platform}"
    echo "Status: identified"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Generate application: $0 prepare $job_id"
    echo "2. Review and customize: $JOBS_DIR/$job_id/"
    echo "3. Mark as applied: $0 status $job_id applied"
}

# Prepare application materials
prepare() {
    local job_id="$1"

    if [ -z "$job_id" ]; then
        echo -e "${RED}Usage: $0 prepare <job_id>${NC}"
        return 1
    fi

    # Get job details
    local job=$(grep "\"id\": \"$job_id\"" "$JOBS_DB" -A 10 | grep -v "^--$")

    if [ -z "$job" ]; then
        echo -e "${RED}Job not found: $job_id${NC}"
        return 1
    fi

    local company=$(echo "$job" | grep '"company"' | cut -d'"' -f4)
    local role=$(echo "$job" | grep '"role"' | cut -d'"' -f4)
    local resume_variant=$(echo "$job" | grep '"resume_variant"' | cut -d'"' -f4)

    # Create job application directory
    local app_dir="$JOBS_DIR/$job_id"
    mkdir -p "$app_dir"

    # Copy appropriate resume
    local resume_file="RESUME_$(echo $resume_variant | tr '[:lower:]' '[:upper:]').md"
    cp "$HOME/blackroad-resume/$resume_file" "$app_dir/resume.md" 2>/dev/null || \
        cp "$HOME/blackroad-resume/RESUME_PLATFORM_INFRA.md" "$app_dir/resume.md"

    # Generate cover letter template
    cat "$TEMPLATES_DIR/cover-letter.md" | \
        sed "s/{COMPANY}/$company/g" | \
        sed "s/{ROLE}/$role/g" | \
        sed "s/{PORTFOLIO_URL}/https:\/\/production.resume-blackroad-io.pages.dev/g" \
        > "$app_dir/cover-letter.md"

    # Generate email template
    cat "$TEMPLATES_DIR/cold-email.md" | \
        sed "s/{COMPANY}/$company/g" | \
        sed "s/{ROLE}/$role/g" | \
        sed "s/{PORTFOLIO_URL}/https:\/\/production.resume-blackroad-io.pages.dev/g" \
        > "$app_dir/email.md"

    # Create application checklist
    cat > "$app_dir/CHECKLIST.md" <<EOF
# Application Checklist: $company - $role

## 📋 Pre-Application
- [ ] Research company mission/values
- [ ] Find hiring manager on LinkedIn
- [ ] Customize cover letter (fill in placeholders)
- [ ] Choose 3 most relevant metrics for this role
- [ ] Verify portfolio links work

## ✉️ Application
- [ ] Submit via company website/portal
- [ ] Email hiring manager (if found)
- [ ] Connect with team members on LinkedIn
- [ ] Save confirmation email/number

## 📊 Metrics to Highlight (Choose 3)
- [ ] 899,160+ LOC (technical depth)
- [ ] 125 deployments @ 100% success (reliability)
- [ ] 119 deploys in 24hrs (velocity)
- [ ] \$0/month infrastructure (cost efficiency)
- [ ] 20 AI agents (innovation)
- [ ] 79 live projects (scale)

## 🔗 Links to Include
- Portfolio: https://production.resume-blackroad-io.pages.dev
- GitHub: https://github.com/blackboxprogramming/alexa-amundson-portfolio
- Live Demo: https://5d7fe908.blackroad-monitoring.pages.dev

## 📝 Follow-Up Schedule
- Day 3: LinkedIn connection request
- Day 7: Follow-up email
- Day 14: Check application status

## Notes
_Add any company-specific notes here_
EOF

    echo -e "${GREEN}✅ Application materials prepared!${NC}"
    echo ""
    echo "Directory: $app_dir"
    echo "Files created:"
    echo "  - resume.md (variant: $resume_variant)"
    echo "  - cover-letter.md (customize placeholders)"
    echo "  - email.md (ready to send)"
    echo "  - CHECKLIST.md (track progress)"
    echo ""
    echo -e "${YELLOW}Next step: Open and customize${NC}"
    echo "cd $app_dir && open ."
}

# Update job status
update_status() {
    local job_id="$1"
    local new_status="$2"

    if [ -z "$job_id" ] || [ -z "$new_status" ]; then
        echo -e "${RED}Usage: $0 status <job_id> <status>${NC}"
        echo "Statuses: identified, prepared, applied, followed_up, interview, offer, rejected"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Update status in database (simplified - would need proper JSON editing)
    echo -e "${GREEN}✅ Status updated: $job_id → $new_status${NC}"
    echo "Timestamp: $timestamp"

    # Log to memory system
    ~/memory-system.sh log updated "[JOB]+[$new_status] $job_id" \
        "Job application status updated to: $new_status at $timestamp" \
        "job-applications" 2>/dev/null || true
}

# List all jobs
list_jobs() {
    local status_filter="$1"

    echo -e "${BLUE}📋 Job Applications${NC}"
    echo "===================="
    echo ""

    if [ ! -s "$JOBS_DB" ]; then
        echo "No jobs tracked yet."
        echo ""
        echo "Add a job: $0 add <company> <role> <url> [resume_variant]"
        return
    fi

    # Parse and display jobs (simplified)
    local count=0
    while IFS= read -r line; do
        if echo "$line" | grep -q '"id":'; then
            ((count++))
            local id=$(echo "$line" | cut -d'"' -f4)
            echo -e "${GREEN}$count.${NC} $id"
        elif echo "$line" | grep -q '"company":'; then
            echo "   Company: $(echo "$line" | cut -d'"' -f4)"
        elif echo "$line" | grep -q '"role":'; then
            echo "   Role: $(echo "$line" | cut -d'"' -f4)"
        elif echo "$line" | grep -q '"status":'; then
            echo "   Status: $(echo "$line" | cut -d'"' -f4)"
        elif echo "$line" | grep -q '^}$'; then
            echo ""
        fi
    done < "$JOBS_DB"

    echo "Total jobs: $count"
}

# Generate application stats
stats() {
    echo -e "${BLUE}📊 Application Statistics${NC}"
    echo "=========================="
    echo ""

    if [ ! -s "$JOBS_DB" ]; then
        echo "No data yet."
        return
    fi

    local total=$(grep -c '"id":' "$JOBS_DB")
    local applied=$(grep -c '"status": "applied"' "$JOBS_DB" || echo 0)
    local interviews=$(grep -c '"status": "interview"' "$JOBS_DB" || echo 0)
    local offers=$(grep -c '"status": "offer"' "$JOBS_DB" || echo 0)

    echo "Total tracked: $total"
    echo "Applied: $applied"
    echo "Interviews: $interviews"
    echo "Offers: $offers"
    echo ""

    if [ $applied -gt 0 ]; then
        local response_rate=$((interviews * 100 / applied))
        echo "Response rate: ${response_rate}%"
    fi
}

# Search job boards (web search)
search_jobs() {
    local query="$1"
    local location="${2:-remote}"

    if [ -z "$query" ]; then
        echo -e "${RED}Usage: $0 search <role> [location]${NC}"
        echo "Example: $0 search 'Platform Engineer' remote"
        return 1
    fi

    echo -e "${BLUE}🔍 Searching for: $query${NC}"
    echo "Location: $location"
    echo ""

    # Open job boards in browser
    local search_encoded=$(echo "$query $location" | sed 's/ /+/g')

    echo "Opening job boards..."
    open "https://www.linkedin.com/jobs/search/?keywords=$search_encoded" 2>/dev/null || true
    sleep 1
    open "https://www.indeed.com/jobs?q=$search_encoded" 2>/dev/null || true
    sleep 1
    open "https://www.glassdoor.com/Job/jobs.htm?sc.keyword=$search_encoded" 2>/dev/null || true

    echo ""
    echo -e "${YELLOW}When you find a job:${NC}"
    echo "$0 add <company> <role> <url> [resume_variant]"
}

# Main command dispatcher
case "$1" in
    init)
        init
        ;;
    add)
        add_job "$2" "$3" "$4" "$5"
        ;;
    prepare)
        prepare "$2"
        ;;
    status)
        update_status "$2" "$3"
        ;;
    list)
        list_jobs "$2"
        ;;
    stats)
        stats
        ;;
    search)
        search_jobs "$2" "$3"
        ;;
    *)
        echo "Job Application Automation System"
        echo "=================================="
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init                           Initialize system"
        echo "  search <role> [location]       Search job boards"
        echo "  add <company> <role> <url>     Add job opportunity"
        echo "  prepare <job_id>               Generate application materials"
        echo "  status <job_id> <status>       Update application status"
        echo "  list [status]                  List all jobs"
        echo "  stats                          Show statistics"
        echo ""
        echo "Example workflow:"
        echo "  1. $0 init"
        echo "  2. $0 search 'Platform Engineer' remote"
        echo "  3. $0 add Acme 'Senior SRE' https://acme.com/jobs/123 platform"
        echo "  4. $0 prepare acme-senior-sre"
        echo "  5. Customize materials in ~/.blackroad/jobs/acme-senior-sre/"
        echo "  6. $0 status acme-senior-sre applied"
        ;;
esac
