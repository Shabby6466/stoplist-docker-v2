#!/bin/bash

# ETD Docker Setup Validation Script
# This script validates all configuration files and URLs

set -e

echo "🔍 Validating ETD Docker Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $1 exists${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 missing${NC}"
        return 1
    fi
}

# Function to check if URL is consistent
check_url() {
    local file="$1"
    local pattern="$2"
    local expected="$3"
    
    if grep -q "$pattern" "$file"; then
        local found=$(grep "$pattern" "$file" | head -1)
        if [[ "$found" == *"$expected"* ]]; then
            echo -e "${GREEN}✅ $file: URL is correct${NC}"
            return 0
        else
            echo -e "${RED}❌ $file: URL mismatch - found: $found${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  $file: Pattern not found${NC}"
        return 1
    fi
}

echo ""
echo "📁 Checking required files..."

# Check Docker Compose files
check_file "docker-compose.yml"
check_file "docker-compose.caddy.yml"
check_file "docker-compose.dev.yml"

# Check Dockerfiles
check_file "etd-frontend/Dockerfile"
check_file "etd-backend/Dockerfile"
check_file "etd-frontend/Dockerfile.dev"
check_file "etd-backend/Dockerfile.dev"

# Check Caddy configuration
check_file "Caddyfile"
check_file "Caddyfile.domain"

# Check startup scripts
check_file "start.sh"
check_file "start-dev.sh"
check_file "start-caddy.sh"
check_file "start-domain.sh"

# Check environment files
check_file "docker.env"
check_file "docker.server.env"
check_file "docker.caddy.env"
check_file "docker.domain.env"

echo ""
echo "🌐 Checking URL consistency..."

# Check Caddyfile domain
check_url "Caddyfile" "etd.dgip.gov.pk" "etd.dgip.gov.pk"

# Check docker-compose.caddy.yml
check_url "docker-compose.caddy.yml" "NEXT_PUBLIC_API_URL" "https://etd.dgip.gov.pk/api"

# Check environment files
check_url "docker.caddy.env" "NEXT_PUBLIC_API_URL" "https://etd.dgip.gov.pk/api"
check_url "docker.domain.env" "NEXT_PUBLIC_API_URL" "https://etd.dgip.gov.pk/api"

echo ""
echo "🔧 Checking Docker Compose configuration..."

# Check if all services are defined
services=("caddy" "stoplist-backend" "stoplist-frontend")
for service in "${services[@]}"; do
    if grep -q "container_name: $service" docker-compose.caddy.yml; then
        echo -e "${GREEN}✅ Service $service is defined${NC}"
    else
        echo -e "${RED}❌ Service $service is missing${NC}"
    fi
done

echo ""
echo "🔒 Checking SSL configuration..."

# Check Caddy SSL setup
if grep -q "etd.dgip.gov.pk" Caddyfile; then
    echo -e "${GREEN}✅ Domain configured in Caddyfile${NC}"
else
    echo -e "${RED}❌ Domain not configured in Caddyfile${NC}"
fi

# Check if ports are exposed
if grep -q '"80:80"' docker-compose.caddy.yml && grep -q '"443:443"' docker-compose.caddy.yml; then
    echo -e "${GREEN}✅ SSL ports (80, 443) are exposed${NC}"
else
    echo -e "${RED}❌ SSL ports not properly exposed${NC}"
fi

echo ""
echo "🗄️ Checking database configuration..."

# Check database environment variables in .env
if [ -f .env ]; then
    db_vars=("DB_HOST" "DB_PORT" "DB_USERNAME" "DB_PASSWORD" "DB_DATABASE")
    for var in "${db_vars[@]}"; do
        if grep -q "$var" .env; then
            echo -e "${GREEN}✅ Database variable $var is set in .env${NC}"
        else
            echo -e "${RED}❌ Database variable $var is missing in .env${NC}"
        fi
    done
else
    echo -e "${RED}❌ .env file missing - cannot check database configuration${NC}"
fi

echo ""
echo "🔗 Checking network configuration..."

# Check if all services are on the same network
if grep -q "stoplist-network" docker-compose.caddy.yml; then
    echo -e "${GREEN}✅ All services use stoplist-network${NC}"
else
    echo -e "${RED}❌ Network configuration issue${NC}"
fi

echo ""
echo "📋 Summary of URLs:"
echo "  Frontend URL: Check NEXT_PUBLIC_API_URL in .env"
echo "  Database: External"

echo ""
echo "🚀 To start the application:"
echo "  ./start-caddy.sh"

echo ""
echo "🔍 Validation complete!"

