#!/bin/bash

# Generate all BlackRoad domain websites from templates

generate_website() {
    local domain="$1"
    local title="$2"
    local description="$3"
    local tagline="$4"
    local icon="$5"
    local color_scheme="$6" # quantum, ai, blockchain, corporate

    local dir="~/blackroad-websites/generated/$domain"
    mkdir -p "$dir"

    # Set gradient based on scheme
    local gradient=""
    case $color_scheme in
        quantum) gradient="linear-gradient(135deg, #7700FF 0%, #0066FF 50%, #00FFFF 100%)" ;;
        ai) gradient="linear-gradient(135deg, #FF0066 0%, #D600AA 50%, #7700FF 100%)" ;;
        blockchain) gradient="linear-gradient(135deg, #FF9D00 0%, #FF6B00 50%, #FF0066 100%)" ;;
        corporate) gradient="linear-gradient(135deg, #0066FF 0%, #00AAFF 50%, #00FFFF 100%)" ;;
        *) gradient="linear-gradient(135deg, #FF9D00 0%, #FF0066 50%, #7700FF 100%)" ;;
    esac

    cat > "$dir/index.html" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <meta name="description" content="$description">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background: #000000;
            color: #FFFFFF;
            line-height: 1.6;
        }
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 4rem 2rem;
            background: radial-gradient(circle, rgba(119, 0, 255, 0.15), transparent 70%);
        }
        h1 {
            font-size: clamp(3rem, 8vw, 6rem);
            font-weight: 800;
            margin-bottom: 2rem;
            background: $gradient;
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .icon { font-size: 6rem; margin-bottom: 2rem; }
        .tagline {
            font-size: clamp(1.25rem, 3vw, 2rem);
            color: rgba(255, 255, 255, 0.8);
            margin-bottom: 3rem;
        }
        .btn {
            display: inline-block;
            padding: 1rem 2.5rem;
            background: $gradient;
            color: #FFF;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
            transition: transform 0.3s;
            margin: 0.5rem;
        }
        .btn:hover { transform: translateY(-2px); }
        .footer {
            text-align: center;
            padding: 3rem 2rem;
            color: rgba(255, 255, 255, 0.5);
        }
    </style>
</head>
<body>
    <div class="hero">
        <div>
            <div class="icon">$icon</div>
            <h1>$title</h1>
            <p class="tagline">$tagline</p>
            <a href="https://blackroad.io" class="btn">Explore BlackRoad OS</a>
            <a href="https://github.com/BlackRoad-OS" class="btn">GitHub</a>
        </div>
    </div>
    <footer class="footer">
        <p>&copy; 2025 BlackRoad. Part of the BlackRoad OS ecosystem.</p>
    </footer>
</body>
</html>
HTMLEOF

    echo "✅ Generated: $domain"
}

echo "🎨 Generating all domain websites..."
echo ""

# Quantum domains
generate_website "blackroadquantum-info" "BlackRoad Quantum Research" "Quantum computing research and information" "Research Papers • Quantum Theory • Publications" "📚" "quantum"
generate_website "blackroadquantum-net" "BlackRoad Quantum Network" "Quantum network infrastructure" "Quantum Internet • Entanglement • Secure Communication" "🌐" "quantum"
generate_website "blackroadquantum-shop" "BlackRoad Quantum Shop" "Quantum computing merchandise and products" "Merch • Books • Hardware" "🛍️" "quantum"
generate_website "blackroadquantum-store" "BlackRoad Quantum Store" "Quantum products and services" "Software • Services • Consulting" "💎" "quantum"

# AI domains
generate_website "blackroadai-com" "BlackRoad AI" "AI products and services" "Enterprise AI • Automation • Intelligence" "🤖" "ai"
generate_website "blackroadqi-com" "BlackRoad QI" "Quantum Intelligence framework" "QI Framework • Quantum AI • Research" "🧠" "ai"
generate_website "lucidiaqi-com" "Lucidia QI" "Lucidia quantum intelligence system" "AI Consciousness • Quantum Models • Research" "✨" "ai"
generate_website "aliceqi-com" "Alice QI" "Alice quantum intelligence agent" "Migration AI • Autonomous Agent • QI System" "🌟" "ai"
generate_website "lucidia-studio" "Lucidia Studio" "Creative AI studio" "AI Art • Music • Content Creation" "🎨" "ai"

# Blockchain domains
generate_website "roadchain-io" "RoadChain" "Blockchain platform for the road" "Decentralized • Transparent • Verified" "⛓️" "blockchain"
generate_website "roadcoin-io" "RoadCoin" "Cryptocurrency of the road" "Digital Currency • Trading • Staking" "🪙" "blockchain"

# Other domains
generate_website "blackboxprogramming-io" "Blackbox Programming" "Developer portfolio and projects" "Code • Projects • Open Source" "💻" "corporate"
generate_website "blackroadinc-us" "BlackRoad Inc" "Corporate entity and legal information" "Company • Legal • Corporate" "🏢" "corporate"
generate_website "blackroad-network" "BlackRoad Network" "Network infrastructure and services" "Infrastructure • CDN • Services" "🌐" "corporate"

echo ""
echo "🎉 All websites generated!"
echo "Total: 15 new websites"
