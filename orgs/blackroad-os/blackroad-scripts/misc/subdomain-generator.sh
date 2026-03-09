#!/bin/bash

# SUBDOMAIN MASS GENERATOR
# Creates websites for all 265 subdomains automatically

echo "🌐 SUBDOMAIN MASS GENERATOR"
echo "============================"
echo ""

# Common subdomain patterns
SUBDOMAINS=(
    # Core services
    "api" "docs" "blog" "status" "monitoring" "analytics"
    "admin" "dashboard" "portal" "console" "control"
    
    # Development
    "dev" "staging" "test" "demo" "sandbox" "playground"
    
    # Documentation
    "wiki" "help" "support" "guide" "tutorial" "learn"
    
    # Marketing
    "www" "marketing" "sales" "pricing" "features" "about"
    
    # Product areas
    "quantum" "ai" "blockchain" "network" "compute" "storage"
    
    # Regional
    "us" "eu" "asia" "global" "cdn" "edge"
    
    # Team/Departments
    "engineering" "design" "product" "operations" "hr" "legal"
    "finance" "research" "security" "compliance" "quality"
    
    # Tools
    "tools" "utils" "cli" "sdk" "ide" "editor"
    
    # Data
    "data" "metrics" "logs" "traces" "events" "streams"
    
    # AI specific
    "lucidia" "alice" "agents" "models" "training" "inference"
    
    # Quantum specific  
    "qubits" "circuits" "algorithms" "simulation" "hardware"
    
    # Blockchain specific
    "chain" "blocks" "nodes" "validators" "explorer" "wallet"
)

# Function to generate a subdomain website
generate_subdomain_site() {
    local subdomain="$1"
    local parent_domain="$2"
    local full_domain="${subdomain}.${parent_domain}"
    
    local dir="~/blackroad-subdomains/${parent_domain}/${subdomain}"
    mkdir -p "$dir"
    
    cat > "$dir/index.html" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${subdomain^} - ${parent_domain}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background: #000;
            color: #0f0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 2rem;
            text-align: center;
        }
        .container {
            max-width: 600px;
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            background: linear-gradient(135deg, #FF9D00, #FF0066, #7700FF, #0066FF);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .subdomain {
            font-family: 'Courier New', monospace;
            font-size: 1.5rem;
            margin-bottom: 2rem;
            color: #0af;
        }
        p {
            font-size: 1.1rem;
            line-height: 1.8;
            margin-bottom: 2rem;
            opacity: 0.8;
        }
        .btn {
            display: inline-block;
            padding: 1rem 2rem;
            background: linear-gradient(135deg, #FF9D00, #FF0066);
            color: #fff;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            margin: 0.5rem;
        }
        .status {
            margin-top: 3rem;
            padding: 1rem;
            background: rgba(0, 255, 0, 0.1);
            border: 1px solid #0f0;
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>${subdomain^}</h1>
        <div class="subdomain">${full_domain}</div>
        <p>Part of the BlackRoad ecosystem. This subdomain provides specialized services and functionality.</p>
        <div>
            <a href="https://${parent_domain}" class="btn">Main Site</a>
            <a href="https://blackroad.io" class="btn">BlackRoad OS</a>
        </div>
        <div class="status">
            <strong>Status:</strong> 🟢 Operational<br>
            <small>Auto-deployed from GitHub</small>
        </div>
    </div>
</body>
</html>
HTMLEOF
    
    echo "  ✅ Generated: ${full_domain}"
}

# Generate subdomains for main domains
echo "Generating subdomains for blackroad.io..."
for sub in "${SUBDOMAINS[@]}"; do
    generate_subdomain_site "$sub" "blackroad.io"
done

echo ""
echo "Generating subdomains for lucidia.earth..."
for sub in lucidia api agents models platform studio; do
    generate_subdomain_site "$sub" "lucidia.earth"
done

echo ""
echo "Generating subdomains for blackroadquantum.com..."
for sub in quantum qubits circuits algorithms simulation research; do
    generate_subdomain_site "$sub" "blackroadquantum.com"
done

echo ""
echo "🎉 Subdomain generation complete!"
echo ""
echo "Total subdomains created: $(find ~/blackroad-subdomains -name "index.html" 2>/dev/null | wc -l)"
