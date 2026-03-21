# The Stratford Laundry App — Development Phases

**Target:** Android tablet (10-inch, landscape primary) + Web Dashboard
**Platforms:** Android, Web only (no iOS/Linux/macOS)
**Approach:** Screen-by-screen MVP, then polish

---

## PHASE 1: App Shell & Home Screen
**Goal:** Bootable app with branding, navigation, and responsive layout

- [x] Flutter project setup
- [ ] Remove unused platforms (iOS, Linux, macOS)
- [ ] Project folder structure (screens, widgets, models, services, config, theme)
- [ ] The Stratford Hotel theming (dark navy #1B2A4A, gold #C9A84C, typography)
- [ ] Responsive layout scaffold (landscape primary, portrait adaptive)
- [ ] **Screen 1: Home Screen**
  - Hotel branding / logo area
  - Two main buttons: "New Laundry Order" + "Admin Login"
  - Date/time display
  - Online/offline status indicator (placeholder)
- [ ] Basic navigation (GoRouter or Navigator 2.0)
- [ ] Test on Android emulator (tablet 10-inch landscape)

**Deliverable:** App launches, shows branded home screen, buttons navigate forward

---

## PHASE 2: Staff Order Flow — Screens 2-5
**Goal:** Staff can create and submit a laundry order (local only, no backend yet)

### Screen 2: Order Type Selection
- [ ] Three cards: Staff Uniform | Department Linen | Guest/Resident Laundry
- [ ] Selection determines form fields + item catalogue for next steps
- [ ] Back navigation to Home

### Screen 3: Order Details Form
- [ ] **Uniform / Linen path:**
  - Docket number (numeric keypad)
  - Department dropdown (hardcoded list from spec)
  - Staff name (text input)
  - Email (optional, with helper text)
  - Notes (optional)
- [ ] **Guest / Resident path:**
  - Docket number
  - Department auto-set (Guest / Loft Resident toggle)
  - Room number
  - Guest name
  - Bag count (numeric stepper)
  - Notes
- [ ] Form validation
- [ ] Back / Next navigation

### Screen 4: Item Selection
- [ ] **Uniforms:** Grid/list of items with quantity steppers + prices + running total
- [ ] **HSK Linens:** Grid/list filtered items, quantity steppers, no prices
- [ ] **F&B Linens:** Grid/list filtered items, quantity steppers, no prices
- [ ] **Guest:** Skip this screen (bag count already captured)
- [ ] Hardcoded item catalogues from spec (placeholder prices TBC)

### Screen 5: Review & Submit
- [ ] Full order summary display
- [ ] Total cost (uniforms only)
- [ ] Edit / Go Back button
- [ ] Submit button
- [ ] Success confirmation with docket number
- [ ] Return to home after submission

**Deliverable:** Complete order creation flow working end-to-end (data stored locally in memory/state)

---

## PHASE 3: Data Layer — Models & Local Storage
**Goal:** Orders persist locally, ready for Supabase sync later

- [ ] Dart data models: Department, CatalogueItem, Order, OrderItem, OrderStatusLog, AdminUser
- [ ] Local SQLite database setup (drift or sqflite)
- [ ] CRUD operations for orders
- [ ] Order list retrieval with filters
- [ ] Seed data: departments + item catalogues inserted on first launch
- [ ] Orders created in Phase 2 now save to SQLite
- [ ] State management setup (Riverpod)

**Deliverable:** Orders persist across app restarts

---

## PHASE 4: Admin Panel — Screens 6-8
**Goal:** Admin can log in with PIN and manage orders

### Screen 6: Admin Login
- [ ] Admin name selection (list of names)
- [ ] PIN entry pad (4 or 6 digit)
- [ ] PIN validation against hashed PINs (local)
- [ ] Auto-lock timeout (5 min default)
- [ ] Error handling (wrong PIN, locked out)

### Screen 7: Admin Dashboard
- [ ] Tab navigation: Pending | Approved | In Progress | Completed | All Orders
- [ ] Order cards: docket #, date, name, department, item count, status badge
- [ ] Tap to expand/view order detail
- [ ] Search & filter (by department, status, date)
- [ ] Status badge colour coding

### Screen 8: Order Detail & Actions
- [ ] Full order detail view
- [ ] Action buttons per status:
  - submitted → Approve / Reject (with reason)
  - approved → Mark as Collected
  - collected → Mark as In Processing
  - in_processing → Mark as Received (item-by-item count)
  - received → Mark as Completed
- [ ] Status change confirmation dialogs
- [ ] Status change log display (timeline)
- [ ] All changes logged with admin user + timestamp

**Deliverable:** Full admin workflow functional locally

---

## PHASE 5: Supabase Integration
**Goal:** App connects to Supabase, syncs data online

- [ ] Supabase project setup (database, auth, RLS)
- [ ] Run SQL schema creation (all tables from spec Section 9)
- [ ] Configure RLS policies
- [ ] `supabase_flutter` package integration
- [ ] Config file with Supabase URL + anon key
- [ ] Online order submission (INSERT to Supabase)
- [ ] Admin reads orders from Supabase
- [ ] Status updates write to Supabase
- [ ] Seed production data (departments, items, admin users)

**Deliverable:** App works fully online with Supabase

---

## PHASE 6: Offline Sync
**Goal:** App works without internet, syncs when reconnected

- [ ] Connectivity monitoring
- [ ] Sync queue table in SQLite
- [ ] Offline writes queued locally
- [ ] On reconnect: push queued changes, pull latest
- [ ] Conflict resolution (last-write-wins)
- [ ] Sync status indicator (green/amber/red)
- [ ] Offline admin login (cached hashed PINs)
- [ ] Cache departments + catalogue locally

**Deliverable:** App fully functional offline with reliable sync

---

## PHASE 7: Email Notifications & PDF
**Goal:** Staff get email updates on order status changes

- [ ] Supabase Edge Functions for each trigger:
  - Order submitted confirmation
  - Order approved
  - Order rejected (with reason)
  - Items collected
  - Items received (with PDF attachment)
- [ ] Email templates (branded)
- [ ] PDF report generation (items sent vs received vs outstanding)
- [ ] SMTP configuration

**Deliverable:** Automated emails sent on status changes

---

## PHASE 8: Web Dashboard (Separate Repo)
**Goal:** React SPA on GitHub Pages for management visibility

- [ ] React + Vite + Tailwind + shadcn/ui project scaffold
- [ ] Supabase JS client + email auth
- [ ] Login page (The Stratford branding)
- [ ] Main orders table (all columns, sorting, pagination)
- [ ] Month quick-filters (Jan-Dec + All) + department/status/search filters
- [ ] Order detail slide-out panel (view + edit)
- [ ] Create new order form
- [ ] Bulk operations (select, bulk delete with safety, bulk status update)
- [ ] Excel export (SheetJS)
- [ ] Reports view (charts with Recharts)
- [ ] Settings/admin panel
- [ ] GitHub Pages deployment (CI/CD workflow)
- [ ] HashRouter for GitHub Pages compatibility

**Deliverable:** Full web dashboard live on GitHub Pages

---

## PHASE 9: Testing & Deployment
**Goal:** Production-ready release

- [ ] End-to-end testing on target 10-inch tablet
- [ ] Landscape + portrait layout testing
- [ ] Offline sync testing (disconnect/reconnect)
- [ ] APK build, signing, distribution
- [ ] Cross-browser testing for web dashboard
- [ ] User training / handover documentation

---

## Current Status

**Phases 1–7: COMPLETE** (Flutter app MVP + Supabase schema + Edge Functions)
**Active:** Ready for Android emulator testing & screen-by-screen polish
**Next:** Phase 8 — Web Dashboard (separate React repo) | Phase 9 — Testing & Deployment
