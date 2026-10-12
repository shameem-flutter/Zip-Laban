# Sip Laban - Sales & Operations Management PWA 🥛

A pixel-perfect Flutter Progressive Web App (PWA) replicating the modern restaurant point-of-sale overview dashboard, connected with Odoo ERP.

## 📱 Features

- **Exact Visual Match**:
  - **Top App Bar**: Outlet branch selector (`Sip Laban Varang...`), sign out / shift handover button, POS screen shortcut, and digital menu link copy button.
  - **Daily Snapshot Card**: Featuring the smooth Bézier curve chart with accent blue wave, glow marker peak, date subtitle, and interactive `"Ready To View"` button opening detailed breakdown.
  - **Sales Overview Section**: Live date filter pill (`1 Oct`), animated sync/refresh button updating live timestamps (`Just now`).
  - **Total Sales Card**: Lilac icon badge, bold amount (`₹ 2,420`), and dual sync indicator (`POS synced 2 Mins ago & Orders synced 1 Hour ago`).
  - **Dine In Card**: Soft cyan icon badge, prominent amount (`₹ 1,370`), `"View More >"` modal trigger, order count (`3 Orders`), Turn Around Time (`0 Min TAT`), and 3-dots action menu.
  - **Pick Up Card**: Soft mint green icon badge, prominent amount (`₹ 1,050`), `"View More >"` modal trigger, order count (`3 Orders`), Average Order Value (`₹ 350 AOV`), and 3-dots action menu.
  - **Bottom Navigation Bar**: Custom bottom navigation with top active blue line indicator over the active tab, supporting **Sales**, **Operation**, and **More**.
- **Interactive Modals & Full Multi-View Support**:
  - **Daily Snapshot Sheet**: Hourly sales trajectory bar chart, best-selling beverages ranking, payment breakdown (UPI 71%, Cash 18%, Card 11%), and report sharing.
  - **Orders Detail Sheet**: Table orders, tokens, preparation time, and reprint KOT shortcuts.
  - **Outlet Branch Switcher**: Instant switching between Varangal, Hitec City, and Banjara Hills.
  - **Live Operations View**: Real-time kitchen queue (KDS), occupied vs. vacant table floor layout, and staff shifts.
  - **Menu & Customers Directories**: Full product and customer records synced with Odoo ERP.
  - **More & PWA Installation**: Add to Home Screen trigger, tax & GST configuration, and offline sync cache.
- **Responsive & PWA Ready**:
  - Runs in standalone mode when added to mobile home screen.
  - Features an interactive device shell on desktop screens with viewport switchers (Mobile Frame / Tablet / Full Screen).

---

## 🚀 Running Locally (Development)

Prerequisites: Flutter SDK `^3.10.4` or later.

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run locally in Chrome
flutter run -d chrome

# 3. Build standalone production web assets
flutter build web --release
```

---

## 🐳 Docker Deployment Guide

The application includes a production-grade multi-stage `Dockerfile` and `compose.yaml` utilizing a lightweight `nginx:1.27-alpine` runtime.

### Local / Workstation Workflow

These commands are executed on your local machine or build server where Docker is installed:

#### 1. Build the Docker Image
```bash
docker build -t sip-laban-pwa:latest .
```

#### 2. Run the Container
```bash
docker run --rm -d -p 8080:80 --name sip-laban-pwa sip-laban-pwa:latest
```

#### 3. Open the Application
Navigate in your web browser to:
```text
http://localhost:8080
```

#### 4. Run Using Docker Compose (Recommended)
```bash
# Build and start container in detached mode
docker compose up -d --build

# Inspect running container status & healthcheck
docker compose ps

# View live application access & error logs
docker compose logs -f

# Stop and remove container
docker compose down
```

---

## 🌐 Deploying to a Linux Production Server

Follow these steps to deploy the application on a Linux server (Ubuntu/Debian):

### 1. Transfer Code to the Server
```bash
# Clone the repository onto the production server
git clone <your-git-repo-url> /opt/laban_pwa
cd /opt/laban_pwa
```

### 2. Configure Firewall
Allow ingress traffic on port `8080` (or `80`/`443` if terminating directly):
```bash
# UFW (Ubuntu)
sudo ufw allow 8080/tcp
sudo ufw reload
```

### 3. Launch via Docker Compose
```bash
# On the remote server
docker compose up -d --build
```

### 4. Configure HTTPS Reverse Proxy (Host Nginx Example)
For production deployments, place the container behind an SSL-terminating reverse proxy (Certbot / Let's Encrypt):

```nginx
# /etc/nginx/sites-available/pos.yourdomain.com
server {
    listen 80;
    server_name pos.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pos.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/pos.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pos.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the configuration and reload Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/pos.yourdomain.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## 🔗 External Odoo ERP Connectivity & CORS

The PWA client communicates directly with the external Odoo ERP server at:
`https://ziplaban.odoo.waslasoft.com`

### Important CORS Requirements:
- The frontend initiates HTTPS calls directly from the user's web browser to the external Odoo instance.
- If your frontend is hosted under a domain other than the Odoo server (e.g., `https://pos.yourdomain.com`), the Odoo server (or the Nginx reverse proxy fronting Odoo) must include the following CORS response headers:
  ```nginx
  add_header 'Access-Control-Allow-Origin' 'https://pos.yourdomain.com' always;
  add_header 'Access-Control-Allow-Credentials' 'true' always;
  add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
  add_header 'Access-Control-Allow-Headers' 'Content-Type, Cookie, Authorization' always;
  ```
- Nginx serving the frontend container **does not proxy API requests to Odoo**; browser requests travel directly to the external Odoo endpoint. Browser security and CORS must be configured properly on the Odoo domain.

---

## 🛠️ Project Structure

- `Dockerfile` - Multi-stage build (Flutter SDK build stage + Nginx Alpine runtime stage)
- `nginx.conf` - Production Nginx web server configuration with SPA routing and cache headers
- `.dockerignore` - Docker build context filtering
- `compose.yaml` - Docker Compose configuration with health check
- `lib/main.dart` - Application entry point, responsive shell, and tab controller
- `lib/theme/` - Color tokens (`app_colors.dart`) and typography (`app_theme.dart`)
- `lib/constants/api_endpoints.dart` - Odoo ERP server endpoints and paths
- `lib/models/` - Data models (orders, products, customers, staff, companies)
- `lib/services/` - Services (auth, sale orders, catalog, CRM, staff, PWA installation)
- `lib/views/` - Main screens (sales, operations, catalog, CRM, settings, login)
- `lib/widgets/` - Reusable components (charts, modals, nav bar, device frame)
- `web/manifest.json` - PWA manifest configuration for standalone install
