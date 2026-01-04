#!/bin/bash

# Vertex Docker Deployment Script
# This script helps you build and deploy Vertex using Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed (either standalone or plugin)
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

print_success "Docker and Docker Compose are installed"

# Parse command line arguments
COMMAND=${1:-"up"}

case $COMMAND in
    build)
        print_info "Building Docker image..."
        docker build -t vertex:latest .
        print_success "Image built successfully"
        ;;
    
    up|start)
        print_info "Starting Vertex container..."
        $DOCKER_COMPOSE_CMD up -d
        
        # Wait for container to be healthy
        print_info "Waiting for container to be healthy..."
        sleep 5
        
        # Check if container is running
        if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
            print_success "Container is running"
            
            # Test health endpoint
            if curl -s http://localhost:3000/health > /dev/null 2>&1; then
                print_success "Health check passed"
                echo ""
                print_success "Vertex is now running at http://localhost:3000"
            else
                print_error "Health check failed"
                echo "Check logs with: $DOCKER_COMPOSE_CMD logs"
            fi
        else
            print_error "Container failed to start"
            echo "Check logs with: $DOCKER_COMPOSE_CMD logs"
            exit 1
        fi
        ;;
    
    down|stop)
        print_info "Stopping Vertex container..."
        $DOCKER_COMPOSE_CMD down
        print_success "Container stopped"
        ;;
    
    restart)
        print_info "Restarting Vertex container..."
        $DOCKER_COMPOSE_CMD restart
        sleep 3
        print_success "Container restarted"
        ;;
    
    logs)
        print_info "Showing container logs..."
        $DOCKER_COMPOSE_CMD logs -f
        ;;
    
    status)
        print_info "Container status:"
        $DOCKER_COMPOSE_CMD ps
        ;;
    
    test)
        print_info "Running tests..."
        
        # Check if container is running
        if ! $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
            print_error "Container is not running. Start it with: ./deploy.sh up"
            exit 1
        fi
        
        # Test health endpoint
        echo "Testing health endpoint..."
        if curl -s http://localhost:3000/health | grep -q "healthy"; then
            print_success "Health check passed"
        else
            print_error "Health check failed"
            exit 1
        fi
        
        # Test main page
        echo "Testing main page..."
        if curl -s http://localhost:3000 | grep -q "Vertex"; then
            print_success "Main page loads correctly"
        else
            print_error "Main page test failed"
            exit 1
        fi
        
        print_success "All tests passed!"
        ;;
    
    clean)
        print_info "Cleaning up Docker resources..."
        $DOCKER_COMPOSE_CMD down -v
        docker rmi vertex:latest 2>/dev/null || true
        print_success "Cleanup complete"
        ;;
    
    help|*)
        echo "Vertex Docker Deployment Script"
        echo ""
        echo "Usage: ./deploy.sh [command]"
        echo ""
        echo "Commands:"
        echo "  build    - Build the Docker image"
        echo "  up       - Start the container (default)"
        echo "  down     - Stop and remove the container"
        echo "  restart  - Restart the container"
        echo "  logs     - View container logs"
        echo "  status   - Show container status"
        echo "  test     - Run health checks"
        echo "  clean    - Remove container and image"
        echo "  help     - Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./deploy.sh build    # Build the image"
        echo "  ./deploy.sh up       # Start the container"
        echo "  ./deploy.sh test     # Test the deployment"
        echo "  ./deploy.sh logs     # View logs"
        ;;
esac
