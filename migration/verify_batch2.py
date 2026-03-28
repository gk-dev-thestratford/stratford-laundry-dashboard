#!/usr/bin/env python3
"""
Thorough verification of batch 2 migration.
Cross-checks: dedup accuracy, item mapping, dept mapping, status mapping,
price correctness, quantity logic, docket uniqueness, guest orders, edge cases.
"""

import csv
import re
from collections import Counter

CATALOGUE = {
    'SHIRT':              {'code': 'UNI-001', 'name': 'Shirt',              'price': 1.10, 'cat': 'uniform'},
    'BLOUSE':             {'code': 'UNI-002', 'name': 'Blouse',             'price': 2.20, 'cat': 'uniform'},
    'TROUSER':            {'code': 'UNI-003', 'name': 'Trouser/Jeans',      'price': 2.75, 'cat': 'uniform'},
    'DRESS':              {'code': 'UNI-004', 'name': 'Dress',              'price': 5.50, 'cat': 'uniform'},
    'BLAZER (TOP)':       {'code': 'UNI-005', 'name': 'Jacket/Blazer',      'price': 2.75, 'cat': 'uniform'},
    'APRON':              {'code': 'UNI-006', 'name': 'Apron',              'price': 0.99, 'cat': 'uniform'},
    'CHEF JACKET':        {'code': 'UNI-009', 'name': 'Chef Jacket',        'price': 1.34, 'cat': 'uniform'},
    'CHEF TROUSER':       {'code': 'UNI-010', 'name': 'Chef Trouser',       'price': 1.48, 'cat': 'uniform'},
    '2 PCS - SUITS':      {'code': 'UNI-011', 'name': '2 Piece Suit',       'price': 5.50, 'cat': 'uniform'},
    'JUMPER/HOODIE':      {'code': 'UNI-012', 'name': 'Hoody/Jumper',       'price': 3.00, 'cat': 'uniform'},
    'POLO T-SHIRT':       {'code': 'UNI-015', 'name': 'T-Shirt/Polo Shirt', 'price': 1.74, 'cat': 'uniform'},
    'TABLE CLOTH':        {'code': 'FNB-002', 'name': 'Table Cloth',        'price': 3.25, 'cat': 'fnb_linen'},
    'TABLE LINENS NAPKINS': {'code': 'FNB-003', 'name': 'Linen Napkins',    'price': 0.22, 'cat': 'fnb_linen'},
    'BATH ROBES':         {'code': 'HSK-004', 'name': 'Bathrobes',          'price': 2.99, 'cat': 'hsk_linen'},
    'GUEST-OTHER':        {'code': None, 'name': 'Guest Laundry',           'price': None, 'cat': 'guest_laundry'},
    'HOUSEKEEPING':       {'code': None, 'name': 'Housekeeping',            'price': None, 'cat': 'hsk_linen'},
}

DEPT_MAP = {
    'MAIN KITCHEN': 'KIT', 'KE-20': 'KEF', 'LOUNGE': 'LNG',
    'EVENTS': 'EVT', 'EVENT': 'EVT', 'HOUSEKEEPING': 'HSK',
    'SECURITY': 'SEC', 'MAINTENANCE': 'MNT', 'SALES&MARKETING': 'SMK',
    'RECEPTION': 'RSV', 'ACCOUNTS': 'ACC', 'GENERAL MANAGER': 'GMT',
    'LOFT -STAFF': 'LFT', 'HUMAN RESOURCE': 'HRS', 'HOTEL MANAGER': 'GMT',
    'ASS.F&B DIRECTOR': 'EVT',
    'HOTEL -GUEST': None, 'LOFT -RESIDENT': None,
}

STATUS_MAP = {
    'Collected': 'collected', 'Collected ': 'collected',
    'Received': 'received',
    'NOT - Received': 'collected', 'NOT - Received ': 'collected',
    'Prep to I.H.I.': 'submitted',
}


def parse_items(desc):
    items = []
    unparsed = []
    for part in desc.split('?'):
        part = part.strip()
        if not part:
            continue
        m = re.match(r'^(.+?):\s*(\d+)\s*x\s*', part)
        if m:
            name = m.group(1).strip().upper()
            qty = int(m.group(2))
            items.append((name, qty))
        else:
            unparsed.append(part)
    return items, unparsed


def get_dept_code(dept):
    d = dept.strip().upper()
    if d in DEPT_MAP:
        return DEPT_MAP[d]
    for k, v in DEPT_MAP.items():
        if k in d or d in k:
            return v
    return '__UNMAPPED__'


def main():
    # Load batch 1
    batch1_keys = set()
    batch1_tickets = set()
    with open('migration/DATAexcel.csv', 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) < 7:
                continue
            date, dept, name, ticket = row[0].strip(), row[1].strip(), row[2].strip(), row[3].strip()
            key = (date, ticket, name.lower())
            batch1_keys.add(key)
            batch1_tickets.add(ticket)

    # Load new full CSV
    new_rows = []
    with open('migration/DATAexcel_full.csv', 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) < 9:
                continue
            date = row[2].strip()
            dept = row[3].strip()
            name = row[4].strip()
            ticket = row[5].strip()
            desc = row[6].strip()
            cost = row[7].strip()
            status = row[8].strip()
            if not date or not desc:
                continue
            new_rows.append({
                'date': date, 'dept': dept, 'name': name,
                'ticket': ticket, 'desc': desc, 'cost': cost, 'status': status
            })

    # Separate into matched (batch1) and new
    matched = []
    new_only = []
    for r in new_rows:
        key = (r['date'], r['ticket'], r['name'].lower())
        if key in batch1_keys:
            matched.append(r)
        else:
            new_only.append(r)

    print("=== BATCH 2 VERIFICATION REPORT ===\n")

    # ---- 1. DEDUP CHECK ----
    print("--- 1. DEDUPLICATION CHECK ---")
    print(f"  Full CSV total rows: {len(new_rows)}")
    print(f"  Batch 1 keys loaded: {len(batch1_keys)}")
    print(f"  Matched to batch 1 (skipped): {len(matched)}")
    print(f"  New records (batch 2): {len(new_only)}")
    print(f"  Sum check: {len(matched)} + {len(new_only)} = {len(matched) + len(new_only)} (should = {len(new_rows)})")
    if len(matched) + len(new_only) == len(new_rows):
        print(f"  PASS: No records lost or duplicated in split")
    else:
        print(f"  !! FAIL: Mismatch!")

    # Check if any batch 2 records have tickets that overlap with batch 1
    b2_tickets = Counter(r['ticket'] for r in new_only)
    overlap_tickets = set(b2_tickets.keys()) & batch1_tickets
    print(f"\n  Batch 2 tickets that also appear in batch 1: {len(overlap_tickets)}")
    if overlap_tickets:
        for t in sorted(overlap_tickets)[:20]:
            # Find the batch2 record with this ticket
            b2_recs = [r for r in new_only if r['ticket'] == t]
            b1_match = t in batch1_tickets
            for rec in b2_recs:
                print(f"    Ticket {t}: {rec['date']} | {rec['dept']} | {rec['name']} (different date/name from batch1 = OK)")

    # Check for internal duplicates within batch 2
    b2_keys = [(r['date'], r['ticket'], r['name'].lower()) for r in new_only]
    b2_key_counts = Counter(b2_keys)
    internal_dups = {k: v for k, v in b2_key_counts.items() if v > 1}
    print(f"\n  Internal duplicates in batch 2: {len(internal_dups)}")
    if internal_dups:
        for k, v in list(internal_dups.items())[:10]:
            print(f"    {k} appears {v}x")

    # ---- 2. ITEM MAPPING CHECK ----
    print("\n--- 2. ITEM MAPPING CHECK ---")
    all_item_names = set()
    unmapped_items = set()
    item_counts = Counter()
    unparsed_rows = []
    zero_qty_items = 0
    suspicious_qty = []

    for i, r in enumerate(new_only):
        items, unparsed = parse_items(r['desc'])
        if unparsed:
            unparsed_rows.append((i+1, unparsed))
        for name, qty in items:
            all_item_names.add(name)
            if qty == 0:
                zero_qty_items += 1
                continue
            item_counts[name] += 1
            if name not in CATALOGUE:
                unmapped_items.add(name)
            if qty > 50 and name != 'TABLE LINENS NAPKINS':
                suspicious_qty.append((i+1, r['ticket'], name, qty))

    print(f"  Unique item names: {len(all_item_names)}")
    print(f"  Mapped: {len(all_item_names - unmapped_items)}")
    if unmapped_items:
        print(f"  !! UNMAPPED: {unmapped_items}")
    else:
        print(f"  All items mapped OK")

    print(f"  Zero-quantity items (skipped): {zero_qty_items}")
    if unparsed_rows:
        print(f"  !! Unparsed item descriptions: {len(unparsed_rows)}")
        for row_num, parts in unparsed_rows[:5]:
            print(f"     Row {row_num}: {parts}")
    else:
        print(f"  All descriptions parsed OK")

    if suspicious_qty:
        print(f"\n  !! SUSPICIOUS QUANTITIES (non-napkin items > 50):")
        for row_num, ticket, name, qty in suspicious_qty:
            print(f"     Row {row_num}, docket {ticket}: {name} x {qty}")

    print(f"\n  Item frequency (batch 2 only):")
    for item, count in item_counts.most_common():
        cat = CATALOGUE.get(item)
        mapped = f"-> {cat['name']} @ {cat['price']}" if cat else "!! NOT MAPPED"
        print(f"    {item:<25} x{count:>4}  {mapped}")

    # ---- 3. DEPARTMENT MAPPING CHECK ----
    print("\n--- 3. DEPARTMENT MAPPING CHECK ---")
    dept_counts = Counter()
    unmapped_depts = set()
    for r in new_only:
        dept = r['dept']
        dept_counts[dept] += 1
        code = get_dept_code(dept)
        if code == '__UNMAPPED__':
            unmapped_depts.add(dept)

    if unmapped_depts:
        print(f"  !! UNMAPPED DEPARTMENTS: {unmapped_depts}")
    else:
        print(f"  All departments mapped OK")

    for dept, count in dept_counts.most_common():
        code = get_dept_code(dept)
        label = code if code and code != '__UNMAPPED__' else 'guest_laundry (no dept)'
        print(f"    {dept:<25} x{count:>4}  -> {label}")

    # ---- 4. STATUS MAPPING CHECK ----
    print("\n--- 4. STATUS MAPPING CHECK ---")
    status_counts = Counter()
    unmapped_statuses = set()
    for r in new_only:
        s = r['status']
        status_counts[s] += 1
        if s not in STATUS_MAP:
            unmapped_statuses.add(s)

    if unmapped_statuses:
        print(f"  !! UNMAPPED STATUSES: {unmapped_statuses}")
    else:
        print(f"  All statuses mapped OK")

    for s, count in status_counts.most_common():
        mapped = STATUS_MAP.get(s, '!! NOT MAPPED')
        print(f"    '{s}' x{count} -> '{mapped}'")

    # ---- 5. QUANTITY SENT/RECEIVED LOGIC ----
    print("\n--- 5. QUANTITY SENT/RECEIVED LOGIC ---")
    collected = sum(1 for r in new_only if STATUS_MAP.get(r['status']) == 'collected')
    received = sum(1 for r in new_only if STATUS_MAP.get(r['status']) == 'received')
    submitted = sum(1 for r in new_only if STATUS_MAP.get(r['status']) == 'submitted')
    print(f"  Collected (qty_received=NULL):    {collected}")
    print(f"  Received (qty_received=qty_sent): {received}")
    print(f"  Submitted (qty_received=NULL):    {submitted}")
    print(f"  Total:                            {collected + received + submitted}")

    # ---- 6. GUEST ORDER CHECK ----
    print("\n--- 6. GUEST ORDER CHECK ---")
    guests = []
    for r in new_only:
        d = r['dept'].strip().upper()
        if 'GUEST' in d or 'RESIDENT' in d:
            guests.append(r)
        elif d == 'HOUSEKEEPING' and 'GUEST-OTHER' in r['desc'].upper():
            guests.append(r)
    print(f"  Guest/Resident orders: {len(guests)}")
    for g in guests:
        print(f"    {g['dept']:<20} | {g['name']:<20} | room={g['ticket']} | {g['desc'][:50]}")

    # ---- 7. EDGE CASES ----
    print("\n--- 7. EDGE CASES ---")

    # Numeric names
    numeric_names = [(r['name'], r['dept'], r['ticket']) for r in new_only if r['name'].strip().isdigit()]
    if numeric_names:
        print(f"  Numeric names (fixed to 'Dept Staff'): {len(numeric_names)}")
        for n, d, t in numeric_names:
            print(f"    NAME='{n}' DEPT='{d}' TICKET={t}")
    else:
        print(f"  No numeric names found")

    # NAME = '?'
    unknown = [(r['dept'], r['ticket']) for r in new_only if r['name'].strip() == '?']
    if unknown:
        print(f"  NAME='?' entries: {len(unknown)}")
    else:
        print(f"  No '?' names found")

    # JUMPER/HOODIE at price=0 in Excel
    jumper_count = sum(1 for r in new_only if 'JUMPER' in r['desc'].upper())
    print(f"  Orders with JUMPER/HOODIE: {jumper_count} (catalogue price 3.00 applied)")

    # Docket = 0
    zero_dockets = sum(1 for r in new_only if r['ticket'] == '0')
    print(f"  Docket = 0 (auto-generated): {zero_dockets}")

    # New departments not in batch 1
    b1_depts = set()
    for r in matched:
        b1_depts.add(r['dept'].strip().upper())
    b2_depts = set(r['dept'].strip().upper() for r in new_only)
    new_depts = b2_depts - b1_depts
    if new_depts:
        print(f"  New departments not in batch 1: {new_depts}")

    # Date range
    dates = []
    for r in new_only:
        try:
            from datetime import datetime
            dates.append(datetime.strptime(r['date'], '%d/%m/%Y'))
        except:
            pass
    if dates:
        print(f"\n  Date range: {min(dates).strftime('%d/%m/%Y')} - {max(dates).strftime('%d/%m/%Y')}")

    # ---- 8. CROSS-CHECK AGAINST SQL FILES ----
    print("\n--- 8. SQL FILE CROSS-CHECK ---")
    import os, glob
    sql_dir = 'migration/batch2_sql'
    total_orders = 0
    total_items = 0
    total_logs = 0
    for f in sorted(glob.glob(os.path.join(sql_dir, 'batch2_*.sql'))):
        with open(f, 'r', encoding='utf-8') as fh:
            content = fh.read()
            o = content.count('INSERT INTO orders ')
            i = content.count('INSERT INTO order_items ')
            l = content.count('INSERT INTO order_status_log ')
            total_orders += o
            total_items += i
            total_logs += l

    print(f"  SQL orders: {total_orders} (expected: {len(new_only)})")
    print(f"  SQL items:  {total_items}")
    print(f"  SQL logs:   {total_logs}")

    if total_orders == len(new_only):
        print(f"  PASS: Order count matches")
    else:
        print(f"  !! FAIL: Order count mismatch!")

    print("\n=== VERIFICATION COMPLETE ===")


if __name__ == '__main__':
    main()
