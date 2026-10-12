# ==============================================================================
# Stage 1: Flutter Web Compilation
# ==============================================================================
ARG FLUTTER_VERSION=3.38.5
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build

# Set working directory inside build container
WORKDIR /app

# Optimize Docker layer caching: install dependencies before copying source
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full application source code
COPY . .

# Compile Flutter Web for production release
RUN flutter build web --release

# ==============================================================================
# Stage 2: Production Nginx Runtime
# ==============================================================================
FROM nginx:1.27-alpine AS runtime

# Remove default site configuration
RUN rm -rf /etc/nginx/conf.d/default.conf

# Install custom Nginx configuration optimized for Flutter PWA
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled web assets from build stage to Nginx web root
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Container healthcheck using BusyBox wget
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1/ || exit 1

# Start Nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]
