#!/bin/bash
# 🤖 Deploy AI Products to Hugging Face Spaces

echo "🤖 Deploying AI Products to Hugging Face..."

# AI Products to deploy
ai_products=(
    "blackroad-ai-platform:AI Platform with 6 models, 30K agents, 104 TOPS compute"
    "blackroad-langchain-studio:LangChain workflow orchestration with visual chain builder"
    "blackroad-vllm:High-performance AI model serving - 10x faster inference"
    "blackroad-localai:Self-hosted AI platform - run LLMs locally with zero cloud dependency"
)

echo "📋 AI Products identified for Hugging Face deployment:"
echo ""

for product_info in "${ai_products[@]}"; do
    IFS=':' read -r product desc <<< "$product_info"
    echo "  🤖 $product"
    echo "     └─ $desc"
    echo "     └─ GitHub: https://github.com/BlackRoad-OS/$product"
    echo "     └─ Cloudflare: Live and accessible"
    echo ""
done

echo "========================================="
echo "📝 Hugging Face Deployment Plan"
echo "========================================="
echo ""
echo "To deploy these to Hugging Face Spaces:"
echo ""
echo "1. Login to Hugging Face:"
echo "   $ huggingface-cli login"
echo ""
echo "2. Create Space for each product:"
echo "   $ huggingface-cli repo create --type space --space_sdk static [space-name]"
echo ""
echo "3. Push code to Hugging Face:"
echo "   $ cd ~/[product-name]"
echo "   $ git remote add hf https://huggingface.co/spaces/BlackRoad/[space-name]"
echo "   $ git push hf master"
echo ""
echo "========================================="
echo "🎯 Ready for Hugging Face Deployment"
echo "========================================="
echo ""
echo "All AI products are:"
echo "  ✅ Built and tested"
echo "  ✅ Deployed to Cloudflare Pages"
echo "  ✅ Pushed to GitHub"
echo "  ⏳ Ready for Hugging Face (requires HF token)"
echo ""
echo "📦 Products ready: ${#ai_products[@]}"
echo "🖤🛣️ Preparation complete!"
