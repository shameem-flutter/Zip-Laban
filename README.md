# Sip Laban - Sales & Operations Management PWA 🥛

A pixel-perfect Flutter Progressive Web App (PWA) replicating the modern restaurant point-of-sale overview dashboard.

## 📱 Features

- **Exact Visual Match**:
  - **Top App Bar**: Outlet branch selector (`Sip Laban Varang...`), sign out / shift handover button, POS screen shortcut, and digital menu link copy button.
  - **Daily Snapshot Card**: Featuring the smooth Bézier curve chart with accent blue wave, glow marker peak, date subtitle, and interactive `"Ready To View"` button opening detailed breakdown.
  - **Sales Overview Section**: Live date filter pill (`1 Oct`), animated sync/refresh button updating live timestamps (`Just now`).
  - **Total Sales Card**: Lilac icon badge, bold amount (`₹ 2,420`), and dual sync indicator (`POS synced 2 Mins ago & Orders synced 1 Hour ago`).
  - **Dine In Card**: Soft cyan icon badge, prominent amount (`₹ 1,370`), `"View More >"` modal trigger, order count (`3 Orders`), Turn Around Time (`0 Min TAT`), and 3-dots action menu.
  - **Pick Up Card**: Soft mint green icon badge, prominent amount (`₹ 1,050`), `"View More >"` modal trigger, order count (`3 Orders`), Average Order Value (`₹ 350 AOV`), and 3-dots action menu.
  - **Bottom Navigation Bar**: Custom bottom navigation with top active blue line indicator over the active tab, supporting **Sales**, **Operation**, **AI Agent**, and **More**.
- **Interactive Modals & Full Multi-View Support**:
  - **Daily Snapshot Sheet**: Hourly sales trajectory bar chart, best-selling beverages ranking, payment breakdown (UPI 71%, Cash 18%, Card 11%), and report sharing.
  - **Orders Detail Sheet**: Table orders, tokens, preparation time, and reprint KOT shortcuts.
  - **POS Quick Station Modal**: Sunmi/terminal connection status, Bluetooth ESC/POS printer test.
  - **Outlet Branch Switcher**: Instant switching between Varangal, Hitec City, and Banjara Hills.
  - **Live Operations View**: Real-time kitchen queue (KDS), occupied vs. vacant table floor layout, and staff shifts.
  - **AI Store Agent View**: AI copilot for sales forecasting, inventory stock alerts, and rush-hour preparation.
  - **More & PWA Installation**: Add to Home Screen trigger, tax & GST configuration, and offline sync cache.
- **Responsive & PWA Ready**:
  - Runs in standalone mode when added to mobile home screen.
  - Features an interactive device shell on desktop screens with viewport switchers (Mobile Frame / Tablet / Full Screen).

## 🚀 Running Locally

```bash
# 1. Get dependencies
flutter pub get

# 2. Run in Chrome / Web
flutter run -d chrome

# 3. Or build production PWA bundle
flutter build web --pwa-strategy=offline-first
```

## 🛠️ Project Structure

- `lib/main.dart` - Application entry point, responsive shell, and tab controller
- `lib/theme/` - Color tokens (`app_colors.dart`) and typography (`app_theme.dart`)
- `lib/models/sales_model.dart` - Outlets, channels, snapshot, and order models
- `lib/views/sales_view.dart` - Primary Sales Overview screen matching reference design
- `lib/views/operation_view.dart` - Kitchen Display System (KDS) & table map
- `lib/views/ai_agent_view.dart` - Restaurant AI Copilot & predictive assistant
- `lib/views/more_view.dart` - Store settings, hardware printers, and PWA install prompt
- `lib/widgets/custom_curve_chart.dart` - CustomPainter for the smooth snapshot curve
- `lib/widgets/custom_bottom_nav_bar.dart` - Bottom bar with top active line indicator
- `lib/widgets/responsive_frame.dart` - Device mockup frame for desktop & mobile
- `web/manifest.json` - PWA manifest configuration for standalone install
