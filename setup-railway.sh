#!/bin/bash
# Fides Railway Deployment Setup Script

set -e

echo "=========================================="
echo "  Fides Railway Deployment Helper"
echo "=========================================="
echo ""

# Check for required tools
command -v openssl >/dev/null 2>&1 || {
    echo "Error: openssl is required but not installed."
    exit 1
}

# Generate secrets
echo "Generating secure secrets..."
echo ""

APP_KEY=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
OAUTH_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
DRP_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)
REDIS_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)

echo "Generated secrets (save these!):"
echo ""
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
echo "REDIS_PASSWORD=$REDIS_PASSWORD"
echo "FIDES__SECURITY__APP_ENCRYPTION_KEY=$APP_KEY"
echo "FIDES__SECURITY__OAUTH_ROOT_CLIENT_SECRET=$OAUTH_SECRET"
echo "FIDES__SECURITY__DRP_JWT_SECRET=$DRP_SECRET"
echo ""

# Create .env file
cat > .env.railway << EOF
# Fides Railway Environment Variables
# Copy these to Railway Variables in each service

POSTGRES_PASSWORD=$POSTGRES_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD

# Security (API and Worker services)
FIDES__SECURITY__APP_ENCRYPTION_KEY=$APP_KEY
FIDES__SECURITY__OAUTH_ROOT_CLIENT_ID=fidesadmin
FIDES__SECURITY__OAUTH_ROOT_CLIENT_SECRET=$OAUTH_SECRET
FIDES__SECURITY__DRP_JWT_SECRET=$DRP_SECRET

# Database (API and Worker)
FIDES__DATABASE__SERVER=fides-db
FIDES__DATABASE__PORT=5432
FIDES__DATABASE__USER=postgres
FIDES__DATABASE__PASSWORD=$POSTGRES_PASSWORD
FIDES__DATABASE__DB=fides

# Redis (API and Worker)
FIDES__REDIS__HOST=redis
FIDES__REDIS__PORT=6379
FIDES__REDIS__PASSWORD=$REDIS_PASSWORD

# General
FIDES__LOGGING__LEVEL=INFO
FIDES__DEV_MODE=false
FIDES__USER__ANALYTICS_OPT_OUT=true
FIDES__CONFIG_PATH=/fides/.fides/fides.toml
EOF

echo "Created .env.railway with your secrets"
echo ""

# Create fides.toml
cat > .fides/fides.toml.production << EOF
[database]
server = "fides-db"
user = "postgres"
password = "$POSTGRES_PASSWORD"
port = "5432"
db = "fides"
load_samples = false

[redis]
host = "redis"
password = "$REDIS_PASSWORD"
port = 6379
db_index = 0

[security]
env = "prod"
cors_origins = [ "http://localhost:8080", "http://localhost:3001", "http://localhost:3000" ]
app_encryption_key = "$APP_KEY"
oauth_root_client_id = "fidesadmin"
oauth_root_client_secret = "$OAUTH_SECRET"
root_username = "root_user"
root_password = "Testpassword1!"

[execution]
require_manual_request_approval = true

[cli]
server_host = "0.0.0.0"
server_port = 8080

[user]
username = "root_user"
password = "Testpassword1!"

[logging]
level = "INFO"
log_pii = false

[consent]
tcf_enabled = false

[redis_db]
index = 0
EOF

echo "Created .fides/fides.toml.production"
echo ""

# Instructions
cat << 'INSTRUCTIONS'

==========================================
  NEXT STEPS
==========================================

1. COMMIT AND PUSH:
   git add -A
   git commit -m "Add Railway deployment config"
   git push origin main

2. IN RAILWAY:
   - Create a new Railway project
   - Add each service from your GitHub repo
   - See RAILWAY_DEPLOY.md for detailed instructions

3. ADD SERVICES IN RAILWAY:
   
   a) fides-db (PostgreSQL):
      - Add PostgreSQL from database templates
      - Set POSTGRES_DB=fides
   
   b) redis:
      - Add Redis from database templates
   
   c) fides-api:
      - Build: uv pip install --python /opt/fides/bin/python -e . --no-deps
      - Start: fides webserver
      - Add all FIDES__* variables from .env.railway
   
   d) worker:
      - Build: uv pip install --python /opt/fides/bin/python -e . --no-deps
      - Start: fides worker
      - Add all FIDES__* variables from .env.railway
   
   e) fides-ui:
      - Dockerfile: Dockerfile.railway
      - NEXT_PUBLIC_FIDESCTL_API_SERVER=http://fides-api:8080
   
   f) privacy-center:
      - Dockerfile: Dockerfile.railway-pc
      - NEXT_PUBLIC_FIDESCTL_API_SERVER=http://fides-api:8080

4. DEFAULT LOGIN:
   - Admin UI: root_user / Testpassword1!

==========================================
INSTRUCTIONS
