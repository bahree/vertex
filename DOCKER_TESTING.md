# Docker Deployment Testing Guide

This guide will help you test and verify the Docker deployment of Vertex.

## Prerequisites

Before testing, ensure you have:
- Docker installed (version 20.10+)
- Docker Compose installed (version 2.0+)
- Internet connectivity (for pulling base images and dependencies)

## Testing Locally

### 1. Build the Docker Image

```bash
# Navigate to the project directory
cd vertex

# Build the image
docker build -t vertex:test .
```

**Expected Output:**
- The build should complete without errors
- You should see messages about installing dependencies and building the app
- Final message should indicate successful image creation

**Build Time:** Approximately 2-5 minutes depending on your internet speed

### 2. Run with Docker Compose

```bash
# Start the container
docker-compose up -d

# Check if container is running
docker-compose ps
```

**Expected Output:**
```
NAME      IMAGE     COMMAND                  SERVICE   CREATED         STATUS                   PORTS
vertex    vertex    "/docker-entrypoint.…"   vertex    5 seconds ago   Up 3 seconds (healthy)   0.0.0.0:3000->80/tcp
```

### 3. Verify the Application

#### Health Check
```bash
curl http://localhost:3000/health
```

**Expected Output:**
```
healthy
```

#### Access the Web Interface
Open your browser and navigate to:
```
http://localhost:3000
```

**Expected Result:**
- The Vertex game interface should load
- You should see the game canvas and puzzle selector
- No console errors in browser developer tools

### 4. Check Container Logs

```bash
# View logs in real-time
docker-compose logs -f vertex

# View last 50 lines
docker-compose logs --tail=50 vertex
```

**Healthy Logs Should Show:**
- Nginx startup messages
- No error messages
- Access logs when you visit the site

### 5. Test Container Restart

```bash
# Stop the container
docker-compose stop

# Start it again
docker-compose start

# Verify it's running
docker-compose ps
```

## Testing in GitHub Codespaces

### 1. Create a Codespace

1. Go to the repository on GitHub
2. Click the "Code" button
3. Select "Codespaces" tab
4. Click "Create codespace on main"

### 2. Wait for Setup

The devcontainer will automatically:
- Install Node.js 20
- Install pnpm
- Run `pnpm install`
- Enable Docker-in-Docker

**Wait Time:** 2-5 minutes for initial setup

### 3. Test Development Server

```bash
# Start the dev server
pnpm run dev
```

**Expected Output:**
- Vite dev server starts on port 5173
- Port is automatically forwarded
- Click the notification to open in browser

### 4. Test Docker in Codespaces

```bash
# Build and run with Docker Compose
docker-compose up -d

# Check status
docker-compose ps

# Test health endpoint
curl http://localhost:3000/health
```

**Expected Result:**
- Container builds and runs successfully
- Port 3000 is automatically forwarded
- Application is accessible via the forwarded port

## Testing with Caddy Reverse Proxy

### 1. Install Caddy (Ubuntu)

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### 2. Configure Caddy

```bash
# Start Vertex container first
docker-compose up -d

# Copy example Caddyfile
sudo cp Caddyfile.example /etc/caddy/Caddyfile

# Edit for local testing (use :80 configuration block)
sudo nano /etc/caddy/Caddyfile

# Reload Caddy
sudo systemctl reload caddy
```

### 3. Test Reverse Proxy

```bash
# Test direct access to container
curl http://localhost:3000/health

# Test through Caddy (if configured on port 80)
curl http://localhost/health
```

**Expected Result:**
- Both endpoints return "healthy"
- Application is accessible through Caddy
- Headers are properly set by Caddy

## Common Issues and Solutions

### Issue: Port 3000 Already in Use

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:3000: bind: address already in use
```

**Solution:**
```bash
# Check what's using the port
sudo lsof -i :3000

# Option 1: Stop the conflicting service
# Option 2: Change port in docker-compose.yml
# Edit ports section to use different port, e.g., "3001:80"
```

### Issue: Container Exits Immediately

**Solution:**
```bash
# Check logs for errors
docker-compose logs vertex

# Common causes:
# 1. Build failed - rebuild with: docker-compose build --no-cache
# 2. Configuration error - check nginx.conf syntax
# 3. Port conflict - change the port mapping
```

### Issue: Health Check Failing

**Solution:**
```bash
# Check if nginx is running inside container
docker-compose exec vertex ps aux | grep nginx

# Check nginx error logs
docker-compose exec vertex cat /var/log/nginx/error.log

# Test health endpoint directly
docker-compose exec vertex wget -O- http://localhost/health
```

### Issue: Application Not Loading Assets

**Solution:**
```bash
# Check if files were built correctly
docker-compose exec vertex ls -la /usr/share/nginx/html

# Should see:
# - index.html
# - assets/ directory with JS and CSS files
# - Other static assets

# If missing, rebuild:
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Issue: Build Fails with Network Errors

**Error:**
```
npm error network request to https://registry.npmjs.org/... failed
```

**Solution:**
```bash
# This usually indicates:
# 1. Internet connectivity issues - check your connection
# 2. Corporate firewall/proxy - configure npm proxy settings
# 3. Registry is down - wait and try again

# Configure npm proxy if behind corporate firewall:
docker build \
  --build-arg HTTP_PROXY=http://your-proxy:8080 \
  --build-arg HTTPS_PROXY=http://your-proxy:8080 \
  -t vertex .
```

## Performance Testing

### 1. Response Time

```bash
# Test response time
time curl -s http://localhost:3000 > /dev/null

# Should be under 100ms for local requests
```

### 2. Concurrent Requests

```bash
# Install apache bench if needed
sudo apt install apache2-utils

# Test with 100 concurrent requests
ab -n 1000 -c 100 http://localhost:3000/
```

### 3. Memory Usage

```bash
# Check container memory usage
docker stats vertex --no-stream

# Should be under 50MB for this simple application
```

## Production Readiness Checklist

Before deploying to production:

- [ ] Docker image builds successfully without errors
- [ ] Application loads and functions correctly in container
- [ ] Health check endpoint returns 200 OK
- [ ] All static assets load properly
- [ ] Container restarts automatically (restart policy: unless-stopped)
- [ ] Logs are accessible and show no errors
- [ ] Reverse proxy is configured and tested
- [ ] HTTPS is enabled (via Caddy or other reverse proxy)
- [ ] Container resource limits are set if needed
- [ ] Monitoring/alerting is configured for health endpoint
- [ ] Backup strategy is in place if needed

## Deployment Verification

After deploying to production:

```bash
# Verify container is running
docker-compose ps

# Check health
curl https://your-domain.com/health

# Check SSL certificate (if using Caddy with auto-HTTPS)
curl -vI https://your-domain.com 2>&1 | grep -i 'SSL\|TLS'

# Monitor logs for any issues
docker-compose logs -f --tail=100
```

## Rollback Procedure

If issues occur in production:

```bash
# Quick rollback to previous version
docker-compose down
docker tag vertex:previous vertex:latest
docker-compose up -d

# Or pull a specific version
docker pull vertex:v1.0.0
docker tag vertex:v1.0.0 vertex:latest
docker-compose up -d
```

## Support

If you encounter issues not covered in this guide:

1. Check Docker logs: `docker-compose logs`
2. Check nginx logs inside container: `docker-compose exec vertex cat /var/log/nginx/error.log`
3. Verify network connectivity: `docker network inspect vertex_vertex-network`
4. Open an issue on GitHub with:
   - Error messages
   - Docker version: `docker --version`
   - Docker Compose version: `docker-compose --version`
   - Operating system details
