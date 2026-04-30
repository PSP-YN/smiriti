#!/bin/bash

# Smriti Build Verification Script
# Run this before deployment to ensure all requirements are met

echo "🔍 Smriti Build Verification"
echo "=============================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAILED++))
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAILED++))
    fi
}

echo ""
echo "📁 Core Structure"
check_dir "lib/core" "Core directory"
check_dir "lib/data" "Data layer"
check_dir "lib/domain" "Domain layer"
check_dir "lib/presentation" "Presentation layer"

echo ""
echo "🔧 Configuration Files"
check_file "pubspec.yaml" "Pubspec configuration"
check_file "android/app/build.gradle.kts" "Android build config"
check_file "android/app/proguard-rules.pro" "ProGuard rules"

echo ""
echo "📚 Documentation"
check_file "README.md" "Project README"
check_file "DEPLOYMENT.md" "Deployment guide"

echo ""
echo "🔐 Security Files"
check_file "android/app/proguard-rules.pro" "ProGuard configuration"
check_file ".gitignore" "Git ignore rules"

echo ""
echo "⚙️ Core Components"
check_file "lib/main.dart" "Main entry point"
check_file "lib/core/di/injection.dart" "Dependency injection"
check_file "lib/core/theme/app_theme.dart" "App theme"
check_file "lib/core/constants/app_constants.dart" "App constants"

echo ""
echo "🗄️ Data Layer"
check_file "lib/data/objectbox_store.dart" "ObjectBox store"
check_file "lib/data/models/objectbox_document.dart" "ObjectBox document model"
check_file "lib/data/models/objectbox_chunk.dart" "ObjectBox chunk model"
check_file "lib/data/datasources/document_local_datasource.dart" "Local datasource"
check_file "lib/data/repositories/document_repository_impl.dart" "Repository implementation"

echo ""
echo "🎯 Domain Layer"
check_file "lib/domain/entities/document.dart" "Document entity"
check_file "lib/domain/entities/document_chunk.dart" "Chunk entity"
check_file "lib/domain/repositories/document_repository.dart" "Repository interface"
check_file "lib/domain/services/rag_orchestrator.dart" "RAG orchestrator"

echo ""
echo "🎨 Presentation Layer"
check_file "lib/presentation/bloc/document/document_bloc.dart" "Document BLoC"
check_file "lib/presentation/pages/home_page.dart" "Home page"
check_file "lib/presentation/pages/chat_page.dart" "Chat page"
check_file "lib/presentation/pages/settings_page.dart" "Settings page"
check_file "lib/presentation/widgets/document_card.dart" "Document card widget"
check_file "lib/presentation/widgets/chat_bubble.dart" "Chat bubble widget"

echo ""
echo "🔒 Security Services"
check_file "lib/core/services/embedding_service.dart" "Embedding service"
check_file "lib/core/services/encryption_service.dart" "Encryption service"
check_file "lib/core/services/secure_storage_service.dart" "Secure storage service"

echo ""
echo "=============================="
echo "📊 Results: $PASSED passed, $FAILED failed"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review.${NC}"
    exit 1
fi
