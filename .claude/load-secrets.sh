#!/bin/bash
# LightWave Secrets Loader
# Loads secrets from AWS Secrets Manager into environment variables
#
# Usage:
#   source .claude/load-secrets.sh
#   source .claude/load-secrets.sh --all
#   source .claude/load-secrets.sh --cloudflare
#   source .claude/load-secrets.sh --django
#
# NOTE: Must be sourced (not executed) to export vars to current shell

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔐 LightWave Secrets Loader${NC}"
echo "=============================="
echo ""

# Verify AWS profile
CURRENT_PROFILE="${AWS_PROFILE:-default}"
if [ "$CURRENT_PROFILE" != "lightwave-admin-new" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Not using lightwave-admin-new profile${NC}"
    echo "Current profile: $CURRENT_PROFILE"
    echo ""
    echo "Setting AWS_PROFILE=lightwave-admin-new..."
    export AWS_PROFILE=lightwave-admin-new
fi

# Verify AWS credentials work
echo -n "Verifying AWS credentials... "
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}✗${NC}"
    echo -e "${RED}ERROR: AWS credentials not working${NC}"
    echo "Configure with: aws configure --profile lightwave-admin-new"
    return 1
fi
echo -e "${GREEN}✓${NC}"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$ACCOUNT" != "738605694078" ]; then
    echo -e "${RED}ERROR: Wrong AWS account${NC}"
    echo "Expected: 738605694078"
    echo "Current:  $ACCOUNT"
    return 1
fi

USER=$(aws sts get-caller-identity --query Arn --output text | awk -F'/' '{print $NF}')
echo -e "${GREEN}✓${NC} Connected as: $USER (Account: $ACCOUNT)"
echo ""

# Load function
load_secret() {
    local var_name=$1
    local secret_id=$2
    local description=$3

    echo -n "Loading $description... "

    if value=$(aws secretsmanager get-secret-value \
        --secret-id "$secret_id" \
        --query SecretString \
        --output text 2>/dev/null); then
        export "$var_name=$value"
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} (not found in Secrets Manager)"
        return 1
    fi
}

# Determine what to load
MODE="${1:---all}"

case "$MODE" in
    --cloudflare)
        echo "Loading Cloudflare secrets..."
        load_secret "CLOUDFLARE_API_TOKEN" "/lightwave/prod/cloudflare-api-token" "Cloudflare API Token"
        ;;

    --django)
        echo "Loading Django secrets..."
        load_secret "DJANGO_SECRET_KEY" "/lightwave/prod/django-secret-key" "Django Secret Key"
        load_secret "DATABASE_PASSWORD" "/lightwave/prod/database-password" "Database Password"
        ;;

    --stripe)
        echo "Loading Stripe secrets..."
        load_secret "STRIPE_SECRET_KEY" "/lightwave/prod/stripe-secret-key" "Stripe Secret Key"
        load_secret "STRIPE_WEBHOOK_SECRET" "/lightwave/prod/stripe-webhook-secret" "Stripe Webhook Secret"
        ;;

    --ai)
        echo "Loading AI service secrets..."
        load_secret "ANTHROPIC_API_KEY" "/lightwave/prod/anthropic-api-key" "Anthropic API Key"
        load_secret "OPENAI_API_KEY" "/lightwave/prod/openai-api-key" "OpenAI API Key"
        ;;

    --all)
        echo "Loading all secrets..."
        echo ""

        echo "Cloudflare:"
        load_secret "CLOUDFLARE_API_TOKEN" "/lightwave/prod/cloudflare-api-token" "  API Token"
        echo ""

        echo "Django/Backend:"
        load_secret "DJANGO_SECRET_KEY" "/lightwave/prod/django-secret-key" "  Secret Key"
        load_secret "DATABASE_PASSWORD" "/lightwave/prod/database-password" "  Database Password"
        echo ""

        echo "Stripe:"
        load_secret "STRIPE_SECRET_KEY" "/lightwave/prod/stripe-secret-key" "  Secret Key"
        load_secret "STRIPE_WEBHOOK_SECRET" "/lightwave/prod/stripe-webhook-secret" "  Webhook Secret"
        echo ""

        echo "AI Services:"
        load_secret "ANTHROPIC_API_KEY" "/lightwave/prod/anthropic-api-key" "  Anthropic"
        load_secret "OPENAI_API_KEY" "/lightwave/prod/openai-api-key" "  OpenAI"
        ;;

    --help|-h)
        echo "Usage: source .claude/load-secrets.sh [option]"
        echo ""
        echo "Options:"
        echo "  --all          Load all secrets (default)"
        echo "  --cloudflare   Load Cloudflare secrets only"
        echo "  --django       Load Django/backend secrets only"
        echo "  --stripe       Load Stripe secrets only"
        echo "  --ai           Load AI service secrets only"
        echo "  --help, -h     Show this help message"
        echo ""
        echo "Examples:"
        echo "  source .claude/load-secrets.sh"
        echo "  source .claude/load-secrets.sh --cloudflare"
        echo ""
        echo "Note: Must use 'source' (not './') to export vars to current shell"
        return 0
        ;;

    *)
        echo -e "${RED}ERROR: Unknown option: $MODE${NC}"
        echo "Use --help to see available options"
        return 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Secrets loaded successfully!${NC}"
echo ""
echo "Loaded environment variables:"
env | grep -E "CLOUDFLARE|DJANGO|STRIPE|ANTHROPIC|OPENAI|DATABASE" | cut -d'=' -f1 | sort | sed 's/^/  - /'
echo ""
echo "To verify:"
echo "  echo \$CLOUDFLARE_API_TOKEN | cut -c1-10"
echo ""
