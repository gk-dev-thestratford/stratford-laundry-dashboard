# Spec: Reconciliation Phase 1 (accurate matching, explained lines, visible notes, guards)

- **Date:** 2026-11-07
- **Status:** Draft, awaiting sign-off (mock-up: `mockup.html` in this folder)
- **Stack:** web (React + Vite + Tailwind, Supabase)

## Problem
The September 2026 reconciliations showed the matcher pairing invoice lines with the wrong orders. Bathrobe ticket 1691 matched a napkin order, and staff tickets 1563 and 1456 matched the wrong orders. Eight lines dated 01/09 show as "not found" because their orders were created on 31/08. Rejected and expired orders take part in matching. Lines that are legitimately explained (group service washes by the kg, group charges, house use) stay red, so they count as discrepancies. Notes are almost invisible, and the invoice note is lost unless the user saves. Add / Link / Update Price have no guards. Together these produced duplicate orders, top-up lines copied into fake orders, and a napkin price overwritten with a bathrobe charge. Napkin lines look "matched" only because their prices were overwritten, while the piece counts differ.

## Goal
Every invoice line ends in one clear state (matched, explained, or a real discrepancy), with the reason visible. The app should stop creating new damage.

## Non-Goals
- The new links table / Unlink and "one order covers several invoice lines". These are Phase 2; the mock-up previews them only.
- Cleaning up existing data (duplicate top-up copies, duplicate 1341/1389, the napkin 1691 price, the blank-invoice-number reconciliation). That is a separate, approved, id-scoped step.
- Tablet app changes.

## Scope
`src/pages/Reconciliation.tsx` (matcher, row UI, line pop-up, Save dialog, napkin card), `src/lib/lineNotes.ts` (explained types), `src/lib/pdfReport.ts` (Explained section). The invoice note autosave uses the existing `reconciliations`/line-notes storage. If that needs a new column, I will show the SQL first.

## Acceptance Criteria
1. **Given** bathrobe line 1691 and a napkin order with docket 1691, **When** the invoice is reconciled, **Then** the bathrobe line does not match the napkin order (matching only within the same service). Staff 1563 matches the Main Kitchen 2x chef jacket order.
2. **Given** staff/napkin/bathrobe lines dated 01/09 whose orders were created on 31/08, **When** reconciled, **Then** they match. Orders created on the last day of the period that are not on the invoice show as "Probably next invoice", not "In System Only". Rejected and expired orders are never matched or listed.
3. **Given** a line tagged Group / Service wash (kg) / House use / Other, with the account responsible, **When** the page is shown or saved, **Then** the line counts under **Explained**, not under unresolved. The Save dialog and the PDF show it in an "Explained lines" section with the account, the recharged flag and the note.
4. **Given** any line with a note, **Then** the note text shows on the row. Every row has one Note button that never hides "Assign". **Given** an invoice note is typed, **When** the invoice is re-uploaded without saving, **Then** the note is still there.
5. **Given** an unmatched line with a likely order (same service, ±3 days, docket or room/name or amount), **When** Add to System is pressed, **Then** a warning lists the likely orders and offers Link first. Re-linking never leaves two copies of a link marker. **Given** Update Price on a line whose piece counts differ, **Then** the confirmation shows "invoice N pcs / system M pcs" before overwriting.
6. **Given** the napkins invoice, **Then** a weekly table shows invoice pieces, system pieces, the 2,500 minimum, the charged quantity, and **over/under-charged £**. This is £0 when both counts are under the minimum. Line-level piece differences are shown as information, not as mismatches.
7. **Given** an order created by reconciliation from a Minimum top-up line, **Then** it is flagged "Copy of a top-up charge, not a real order" in In System Only.
8. **Given** several lines are ticked, **When** a bulk action is chosen (Explain as…, Link to one order, Challenge, Defer, Add note), **Then** it applies to all selected lines with one note. The note is required for bulk actions, Challenge, Accept/Other and Write off. Every action records who did it and when. "Clear" on a line returns it to unresolved.

9. **Credit note request** (replaces Challenge). **Given** selected invoice lines, **When** "Request credit note" is chosen, **Then** each line gets a reason: Not ours / no order (full line), Wrong price (difference), Wrong quantity (extra pieces × rate), Charged twice, Wrong service or room, or Other (free text). Each line gets an editable credit amount. Net, VAT and total are shown, the message is required, and To/Cc come from Configuration. "Open in email" opens the user's own email program (mailto, as today) with the subject and body filled in. "Download PDF" saves the credit-request PDF to attach. The request is stored with a reference CR-<invoice>-<n>.
10. **Credit tracking**: Requested (days waiting; flagged after the configured chase period, with a reminder email) → Received (credit note number and amount; partial keeps the remainder open) → Closed. Shows the running "Owed by Goldstar £". Credit (negative) lines on later invoices are matched to open requests.
11. **In System Only actions**: Expect on next invoice (renamed from Defer, listed on next month's reconciliation to tick off), Not charged by Goldstar (£0 cost in reports, order kept), Request credit / query, Write off (note required), Delete order (confirm + reason required, logged). All of these are available in bulk.
12. **Open items across months** (Recon History): credits awaiting Goldstar, expected on next invoice, unresolved lines, explained with recharge pending.
13. **Action history** per line (who / what / when) and **sign-off** (Reconciled by, automatic; Approved by accounts, users with permission) on the saved reconciliation, Recon History and the PDF.
14. **Configuration → Goldstar contacts** (To/Cc), chase period, email signature.

Mock-ups: `mockup.html` (first draft) and `mockup-v2-compare.html` (current vs proposed per situation, bulk selection, aligned pop-up, actions table). The v2 pop-up layout is the one to build.

## Edge Cases & Error States
- An invoice with no number: line notes and the invoice note are disabled, with a visible message.
- Line-notes table unavailable: the existing warning stays.
- A week spanning two invoices (first or last week of the month): labelled, no £ verdict.
- A ticket that genuinely appears in two services: shown as a suggestion only, never matched automatically.

## Non-Functional Notes
- No database writes are added by matching. The only new writes are the invoice-note autosave and the explained fields (on existing tables if possible).
- No guest names in exports beyond what the invoice already prints.

## Open Questions
- Service wash by the kg: is "Recharged to guest/group folio (yes/no + folio ref)" the right confirmation for "we have charged them"?
- Top-up copies: confirm these are duplicate copies of real top-up charges (see the chat explanation) before the clean-up step.
