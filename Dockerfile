# Multi-stage build for Vertex application
# Stage 1: Build the application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
# Note: Using npm in Docker for broader compatibility, while local development uses pnpm
# npm is bundled with Node.js and doesn't require additional installation steps
COPY package.json ./

# Install dependencies using npm
RUN npm install

# Copy source files
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy built files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
