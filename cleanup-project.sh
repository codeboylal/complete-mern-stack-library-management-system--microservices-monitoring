#!/bin/bash

echo "🧹 LYBOOK Project Cleanup - Removing Unnecessary Files"
echo "======================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to safely remove files/directories
safe_remove() {
    local item="$1"
    local reason="$2"
    
    if [ -e "$item" ]; then
        echo -e "${YELLOW}🗑️  Removing: $item${NC} ($reason)"
        rm -rf "$item"
        echo -e "${GREEN}   ✅ Removed${NC}"
    else
        echo -e "${BLUE}   ℹ️  Not found: $item${NC}"
    fi
}

echo -e "${BLUE}📋 Files and directories that will be removed:${NC}"
echo ""

echo -e "${RED}🚫 UNNECESSARY FILES TO REMOVE:${NC}"
echo ""

# 1. Remove unused microservices architecture (we're using monolith)
echo -e "${YELLOW}1. Unused Microservices Architecture:${NC}"
safe_remove "microservices/" "Unused microservices setup - we're using monolith"
echo ""

# 2. Remove duplicate/old docker-compose files
echo -e "${YELLOW}2. Duplicate/Old Docker Compose Files:${NC}"
safe_remove "docker-compose.yml" "Old docker-compose (using enhanced version)"
safe_remove "docker-compose.fixed.yml" "Temporary fixed version (merged to enhanced)"
safe_remove "docker-compose.gcp.yml" "GCP-specific config (not needed for local dev)"
echo ""

# 3. Remove unused environment files
echo -e "${YELLOW}3. Unused Environment Files:${NC}"
safe_remove ".env" "Basic env file (using .env.enhanced)"
safe_remove ".env.aws" "AWS-specific config (not needed)"
echo ""

# 4. Remove CI/CD files (keep if needed for deployment)
echo -e "${YELLOW}4. CI/CD Files (Remove if not deploying):${NC}"
echo -e "${BLUE}   ℹ️  Keeping Jenkinsfile (comment out this line if not needed)${NC}"
# safe_remove "Jenkinsfile" "CI/CD pipeline config (remove if not deploying)"
echo ""

# 5. Remove old startup scripts (we have setup-mode.sh)
echo -e "${YELLOW}5. Old Startup Scripts:${NC}"
safe_remove "start-enhanced-env.sh" "Old startup script (using setup-mode.sh)"
safe_remove "start-enhanced.sh" "Old startup script (using setup-mode.sh)"
safe_remove "test-integration.sh" "Old integration test (using test-api-complete.sh)"
echo ""

# 6. Remove IDE specific files
echo -e "${YELLOW}6. IDE Specific Files:${NC}"
safe_remove ".vscode/" "VS Code specific settings (personal preference)"
echo ""

# 7. Remove WARP specific files
echo -e "${YELLOW}7. Development/Debug Files:${NC}"
safe_remove "WARP-PROMPT/" "Development prompt files"
echo ""

echo -e "${GREEN}✨ ESSENTIAL FILES KEPT:${NC}"
echo ""
echo "📂 Core Application:"
echo "   ✅ backend/ - Node.js API server"
echo "   ✅ frontend/ - React application"
echo "   ✅ api-gateway/ - Kong configuration"
echo "   ✅ monitoring/ - Prometheus configuration"
echo ""
echo "⚙️  Configuration:"
echo "   ✅ .env.enhanced - Environment variables"
echo "   ✅ docker-compose.enhanced.yml - Full setup"
echo "   ✅ docker-compose.core.yml - Basic setup"
echo "   ✅ mongo-init.js - Database initialization"
echo ""
echo "🧪 Testing & Management:"
echo "   ✅ test-api-complete.sh - Comprehensive API testing"
echo "   ✅ test-delete-functionality.sh - Delete functionality testing"
echo "   ✅ setup-mode.sh - Easy startup script"
echo "   ✅ check-status.sh - System health checker"
echo ""
echo "📚 Documentation:"
echo "   ✅ README-FIXED.md - Complete documentation"
echo "   ✅ .gitignore - Git ignore rules"
echo ""

# Create a directory structure summary
echo -e "${CYAN}📁 FINAL PROJECT STRUCTURE:${NC}"
echo ""
echo "LYBOOK/"
echo "├── 🔧 Setup & Management"
echo "│   ├── setup-mode.sh          # Start core or enhanced mode"
echo "│   ├── check-status.sh        # System health checker"
echo "│   └── cleanup-project.sh     # This cleanup script"
echo "│"
echo "├── 🧪 Testing Suite"
echo "│   ├── test-api-complete.sh   # Comprehensive API tests"
echo "│   └── test-delete-functionality.sh # Delete functionality tests"
echo "│"
echo "├── ⚙️  Configuration"
echo "│   ├── .env.enhanced          # Environment variables"
echo "│   ├── docker-compose.enhanced.yml # Full microservices setup"
echo "│   ├── docker-compose.core.yml     # Basic 4-service setup"
echo "│   ├── mongo-init.js          # Database initialization"
echo "│   └── .gitignore             # Git ignore rules"
echo "│"
echo "├── 🚀 Application"
echo "│   ├── backend/               # Node.js API (Express + MongoDB)"
echo "│   │   ├── models/Book.js     # Database model"
echo "│   │   ├── routes/books.js    # API routes"
echo "│   │   ├── server.js          # Main server"
echo "│   │   ├── Dockerfile         # Container config"
echo "│   │   └── package.json       # Dependencies"
echo "│   │"
echo "│   ├── frontend/              # React Application"
echo "│   │   ├── src/               # React source code"
echo "│   │   ├── public/            # Static assets"
echo "│   │   ├── Dockerfile         # Container config"
echo "│   │   └── package.json       # Dependencies"
echo "│   │"
echo "│   ├── api-gateway/           # Kong API Gateway"
echo "│   │   └── kong.yml           # Kong configuration"
echo "│   │"
echo "│   └── monitoring/            # Monitoring Stack"
echo "│       └── prometheus.yml     # Prometheus config"
echo "│"
echo "└── 📚 Documentation"
echo "    └── README-FIXED.md        # Complete setup guide"
echo ""

echo -e "${GREEN}🎯 CLEANUP COMPLETE!${NC}"
echo ""
echo -e "${CYAN}📊 Project Status:${NC}"

# Count remaining files
TOTAL_FILES=$(find . -type f | wc -l)
echo "📁 Total files remaining: $TOTAL_FILES"

# Get project size
PROJECT_SIZE=$(du -sh . | cut -f1)
echo "💾 Project size: $PROJECT_SIZE"

echo ""
echo -e "${GREEN}✅ Your LYBOOK project is now clean and production-ready!${NC}"
echo ""
echo -e "${YELLOW}🚀 Quick Start Commands:${NC}"
echo "# Start the application:"
echo "./setup-mode.sh core"
echo ""
echo "# Run comprehensive tests:"
echo "./test-api-complete.sh"
echo ""
echo "# Check system status:"
echo "./check-status.sh"
echo ""
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "1. Review README-FIXED.md for complete documentation"
echo "2. Run ./setup-mode.sh enhanced when you have good internet"
echo "3. Use ./test-api-complete.sh to verify all functionality"
echo "4. Access your app at http://localhost:3000"