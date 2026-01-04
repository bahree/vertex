# Vertex

A remake of the [discontined](https://www.nytimes.com/2024/08/08/crosswords/vertex-goodbye.html) New York Times game Vertex, using archived puzzle data from [here](https://github.com/Q726kbXuN/vertex)

## Table of Contents
- [Development](#development)
- [Docker Deployment](#docker-deployment)
- [Reverse Proxy Configuration](#reverse-proxy-configuration)
- [GitHub Codespaces](#github-codespaces)

## Development
You will need to [install](https://pnpm.io/installation) pnpm in order to run and build this locally.

```bash
$ pnpm install
$ pnpm run dev
```

## Docker Deployment

This application can be deployed using Docker and Docker Compose, making it easy to run in containers on Ubuntu or any other platform.

### Prerequisites
- Docker (version 20.10 or later)
- Docker Compose (version 2.0 or later)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bahree/vertex.git
   cd vertex
   ```

2. **Build and run with Docker Compose:**
   
   **Option A: Using the deploy script (recommended):**
   ```bash
   ./deploy.sh up
   ```
   
   **Option B: Using docker-compose directly:**
   ```bash
   docker-compose up -d
   ```

3. **Access the application:**
   Open your browser and navigate to `http://localhost:3000`

> **Note:** The Docker build requires internet access to download dependencies. If you're in a restricted network environment, you may need to configure proxy settings. See [DOCKER_TESTING.md](DOCKER_TESTING.md) for troubleshooting.

### Using the Deploy Script

The `deploy.sh` script provides convenient commands for managing the Docker deployment:

```bash
./deploy.sh build    # Build the Docker image
./deploy.sh up       # Start the container
./deploy.sh down     # Stop the container
./deploy.sh restart  # Restart the container
./deploy.sh logs     # View container logs
./deploy.sh status   # Show container status
./deploy.sh test     # Run health checks
./deploy.sh clean    # Remove container and image
./deploy.sh help     # Show all commands
```

### Docker Commands

**Build the image:**
```bash
docker build -t vertex .
```

**Run the container manually:**
```bash
docker run -d -p 3000:80 --name vertex vertex
```

**Stop the container:**
```bash
docker-compose down
```

**View logs:**
```bash
docker-compose logs -f
```

**Rebuild after changes:**
```bash
docker-compose up -d --build
```

### Health Check

The application includes a health check endpoint at `/health` that returns a 200 status when the service is running properly.

```bash
curl http://localhost:3000/health
```

### Testing and Troubleshooting

For detailed testing instructions, troubleshooting common issues, and deployment verification, see [DOCKER_TESTING.md](DOCKER_TESTING.md).

## Reverse Proxy Configuration

The application is designed to work seamlessly with reverse proxies like Caddy, Nginx, Apache, or Traefik.

### Using Caddy

Caddy is a modern web server with automatic HTTPS. An example configuration is provided in `Caddyfile.example`.

**Basic setup:**

1. **Install Caddy:**
   ```bash
   sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
   sudo apt update
   sudo apt install caddy
   ```

2. **Configure Caddy:**
   ```bash
   # Copy the example configuration
   sudo cp Caddyfile.example /etc/caddy/Caddyfile
   
   # Edit the configuration and replace 'vertex.example.com' with your domain
   sudo nano /etc/caddy/Caddyfile
   
   # Reload Caddy
   sudo systemctl reload caddy
   ```

3. **The application will be accessible at your domain with automatic HTTPS.**

### Using Nginx

Example Nginx configuration:

```nginx
server {
    listen 80;
    server_name vertex.example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
```

### Port Configuration

By default, the Docker container exposes port 3000. You can change this in `docker-compose.yml`:

```yaml
ports:
  - "8080:80"  # Change 8080 to your preferred port
```

## GitHub Codespaces

This repository is configured to work with GitHub Codespaces for instant development environments.

### Getting Started with Codespaces

1. **Open in Codespaces:**
   - Navigate to the repository on GitHub
   - Click the "Code" button
   - Select "Codespaces" tab
   - Click "Create codespace on main" (or your branch)

2. **Wait for setup:**
   The devcontainer will automatically install all dependencies using pnpm.

3. **Start development:**
   ```bash
   pnpm run dev
   ```
   The dev server will start on port 5173 and will be automatically forwarded.

4. **Test Docker in Codespaces:**
   ```bash
   docker-compose up -d
   ```
   The application will be available on port 3000 (also auto-forwarded).

### Codespace Features

- **Pre-configured environment:** Node.js 20 with TypeScript support
- **Docker-in-Docker:** Build and test containers within Codespaces
- **Port forwarding:** Automatic forwarding of ports 5173 (dev) and 3000 (Docker)
- **VS Code extensions:** Pre-installed ESLint, Prettier, and Docker extensions

## Production Deployment

For production deployments:

1. **Use a reverse proxy** (Caddy, Nginx, Traefik) for HTTPS termination
2. **Set up monitoring** using the `/health` endpoint
3. **Configure backups** if needed for any persistent data
4. **Use environment-specific configurations** via Docker Compose overrides
5. **Enable logging** and integrate with your logging infrastructure

### Security Considerations

- The nginx configuration includes security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- Always use HTTPS in production (automatic with Caddy)
- Keep Docker images updated regularly
- Use specific version tags instead of `latest` for production

## Troubleshooting

**Container won't start:**
```bash
docker-compose logs vertex
```

**Port already in use:**
Change the port in `docker-compose.yml` from 3000 to another port.

**Build fails:**
Ensure you have enough disk space and Docker is running properly:
```bash
docker system df
docker system prune
```

## License

GPL-3.0