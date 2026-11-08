# Tasks: Reconciliation Phase 1 (approved 2026-11-08)

Each batch is verified (tsc + build + matcher regression harness + visible Playwright run on the September invoices, read-only unless stated), then committed, pushed to `main` and checked live on GitHub Pages.

## Batch 1: code only, no DB changes (AC 1, 2, 3 (existing tags), 4 (row notes), 5, 6, 7)
1. Matcher: docket matches only within the same order_type (`sectionTypeToOrderType`); among several candidates pick the best by items, date and amount (not the first).
2. Fetch window: period start − 3 days. Orders created on the period's last day and not invoiced → "Probably next invoice" (not counted as In System Only).
3. Exclude rejected / expired orders from matching and In System Only.
4. Flag orders created by reconciliation from a Minimum top-up line ("Copy of a top-up charge").
5. Explained outcome: line notes of type group / house / other (and service_wash once the migration exists) count as Explained. New stat card; unresolved totals exclude them; Save dialog split; PDF "Explained lines" section; Excel column.
6. Row notes: note text shown on the row (who + when); Note button on every row; "Assign room / group" stays visible on no-room lines that only have a note.
7. Guards: Add to System warns when a likely same-service order exists ("Link instead"); never offered for top-up lines; Update Price confirmation shows invoice vs system pieces; re-link replaces this line's old ref token instead of appending a copy.
8. Napkins weekly: "Charge by our count" and "Over / under £" columns + month verdict; line rows show "pieces: invoice N · ours M".

## Batch 2: needs migration 2026-11-08 (AC 3 service wash fields, 4 autosave, 8, 11, 13)
9. One "Resolve…" pop-up (link / room missing / group / service wash / house / other / note) with aligned fields: who pays, charged on to them, folio, kg.
10. Select several lines + bulk actions (explain, link to one order, add note) with required note.
11. Invoice note autosave (reconciliation_drafts).
12. Action history (reconciliation_actions) + per-line history tooltip.
13. In System Only: Expect on next invoice / Not charged by Goldstar (£0 via orders.not_charged_at, computeOrderCost) / Write off (note) / Delete (reason + confirm, logged); bulk.
14. Expected from last month panel (open expect_next resolutions, ticked off when found).
15. Sign-off: Reconciled by (auto) + Approved by accounts (Recon History, PDF).

## Batch 3: needs migration (AC 9, 10, 12, 14)
16. Credit note request modal (reasons, auto amounts, VAT, To/Cc from supplier_contacts, mailto + PDF download), stored with reference.
17. Credit notes panel: owed total, status flow, record credit note, reminder email; credit lines on later invoices matched.
18. Open items across months (Recon History).
19. Configuration: Goldstar contacts card + chase days + signature.
