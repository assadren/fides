# Fides on Railway - Deployment Guide

This is a guide to deploying Fides (Privacy Engineering Platform) on Railway.

## Architecture Overview

Fides requires these services:
- **fides-db**: PostgreSQL 16 database
- **redis**: Redis for caching and Celery broker
- **fides-api**: Main FastAPI server (Python)
- **worker**: Celery background worker (Python)
- **fides-ui**: Admin UI (Next.js/Node.js)
- **privacy-center**: Privacy Center (Next.js/Node.js)

## Prerequisites

1. [Railway account](https://railway.app) 
2. [GitHub account](https://github.com)
3. Fork this repository to your GitHub

## Deployment Steps

### Step 1: Fork and Connect Repository

1. Fork this repository to your GitHub
2. In Railway, create a new project
3. Click "Add a GitHub Repo" and select your fork

### Step 2: Create PostgreSQL Database

1. In Railway project, click "New Service" → "Database" → "PostgreSQL"
2. Wait for the database to provision
3. In the database service, go to "Variables" tab
4. Add: `POSTGRES_DB=fides`
5. Note the connection string (will be used in next step)

### Step 3: Create Redis

1. Click "New Service" → "Database" → "Redis"
2. Wait for Redis to provision
3. In the Redis service, go to "Variables" tab
4. Add environment variables from below

### Step 4: Deploy Fides API

1. Click "New Service" → "GitHub Repo"
2. Select your Fides fork
3. Configure as:

**Service Name:** `fides-api`

**Build Command:**
```bash
uv pip install --python /opt/fides/bin/python -e . --no-deps
```

**Start Command:**
```bash
fides webserver
```

**Environment Variables:**
```
FIDES__CONFIG_PATH=/fides/.fides/fides.toml
FIDES__DATABASE__SERVER=<from Step 2>
FIDES__DATABASE__PORT=5432
FIDES__DATABASE__USER=postgres
FIDES__DATABASE__PASSWORD=<your POSTGRES_PASSWORD>
FIDES__DATABASE__DB=fides
FIDES__REDIS__HOST=<from Step 3 - use service name>
FIDES__REDIS__PORT=6379
FIDES__REDIS__PASSWORD=<your REDIS_PASSWORD>
FIDES__LOGGING__LEVEL=INFO
FIDES__DEV_MODE=false
FIDES__USER__ANALYTICS_OPT_OUT=true
FIDES__SECURITY__APP_ENCRYPTION_KEY=<generate 32-char key>
FIDES__SECURITY__OAUTH_ROOT_CLIENT_ID=fidesadmin
FIDES__SECURITY__OAUTH_ROOT_CLIENT_SECRET=<generate strong secret>
FIDES__SECURITY__DRP_JWT_SECRET=<generate random string>
```

### Step 5: Deploy Celery Worker

1. Click "New Service" → "GitHub Repo"
2. Select your Fides fork

**Service Name:** `worker`

**Build Command:**
```bash
uv pip install --python /opt/fides/bin/python -e . --no-deps
```

**Start Command:**
```bash
fides worker
```

**Environment Variables:** Same as fides-api

### Step 6: Deploy Admin UI

1. Click "New Service" → "GitHub Repo"
2. Select your Fides fork

**Service Name:** `fides-ui`

**Dockerfile:** `Dockerfile.railway`

**Environment Variables:**
```
NEXT_PUBLIC_FIDESCTL_API_SERVER=http://fides-api:8080
NODE_ENV=production
```

### Step 7: Deploy Privacy Center

1. Click "New Service" → "GitHub Repo"
2. Select your Fides fork

**Service Name:** `privacy-center`

**Dockerfile:** `Dockerfile.railway-pc`

**Environment Variables:**
```
NEXT_PUBLIC_FIDESCTL_API_SERVER=http://fides-api:8080
NODE_ENV=production
```

### Step 8: Configure Networking

1. Go to each service settings → "Networking"
2. Make services reachable within the project
3. Set the fides-api, fides-ui, and privacy-center to have public networking if needed

## Generating Secure Secrets

Generate secure random values for these variables:

```bash
# Generate app encryption key (32 characters)
openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32

# Generate OAuth secret (32+ characters)
openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32

# Generate DRP JWT secret (32+ characters)
openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32
```

## Default Credentials

After deployment, access the Admin UI and login with:

- **Username:** `root_user`
- **Password:** `Testpassword1!` (or your custom value)

**Important:** Change these credentials in production!

## Troubleshooting

### Health Check Failures
- Ensure PostgreSQL is fully healthy before fides-api starts
- Check that Redis password matches between services

### Database Connection Issues
- Verify `FIDES__DATABASE__SERVER` matches the PostgreSQL service name
- Ensure `POSTGRES_DB=fides` is set

### Frontend Build Failures
- The admin UI and privacy center require significant build memory
- Consider using Railway's paid tier for builds

### Worker Not Processing Tasks
- Verify Redis connection is working
- Check worker logs for connection errors

## Production Considerations

1. **Enable HTTPS** - Railway provides automatic TLS
2. **Set CORS origins** - Update `fides.toml` with your production domains
3. **Secure credentials** - Use Railway's secret store for all sensitive values
4. **Database backups** - Enable automated backups for PostgreSQL
5. **Monitoring** - Set up monitoring for all services
