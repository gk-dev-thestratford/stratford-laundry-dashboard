#!/usr/bin/env python3
"""
Batch 2 Migration: Diff new CSV against batch 1 and generate SQL for missing records.
New CSV has 9 columns: [JUNK_DATE, JUNK_DEPT, DATE, DEPARTMENT, NAME, TICKET, ITEMS, COST, STATUS]
"""

import csv
import re
import os
import uuid
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OLD_CSV = os.path.join(SCRIPT_DIR, "DATAexcel.csv")
NEW_CSV = os.path.join(SCRIPT_DIR, "DATAexcel_full.csv")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "batch2_sql")
MAX_LINES = 5800

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

STATUS_CHAINS = {
    'submitted': ['submitted'],
    'collected': ['submitted', 'approved', 'collected'],
    'received':  ['submitted', 'approved', 'collected', 'received'],
}


def parse_items(desc):
    items = []
    for part in desc.split('?'):
        part = part.strip()
        if not part:
            continue
        m = re.match(r'^(.+?):\s*(\d+)\s*x\s*', part)
        if m:
            name = m.group(1).strip().upper()
            qty = int(m.group(2))
            if qty > 0:
                if qty > 50:
                    print(f"  WARNING: Suspicious qty {qty} for {name}")
                items.append((name, qty))
    return items


def get_dept_code(dept):
    d = dept.strip().upper()
    if d in DEPT_MAP:
        return DEPT_MAP[d]
    for k, v in DEPT_MAP.items():
        if k in d or d in k:
            return v
    return None


def get_order_type(items, dept):
    d = dept.strip().upper()
    if d in ('HOTEL -GUEST', 'LOFT -RESIDENT'):
        return 'guest_laundry'
    cats = set()
    for name, _ in items:
        c = CATALOGUE.get(name)
        if c:
            cats.add(c['cat'])
    if 'hsk_linen' in cats:
        return 'hsk_linen'
    if 'fnb_linen' in cats:
        return 'fnb_linen'
    if 'guest_laundry' in cats:
        return 'guest_laundry'
    return 'uniform'


def esc(s):
    if s is None:
        return 'NULL'
    return "'" + str(s).replace("'", "''") + "'"


def load_batch1_keys():
    """Load keys from batch 1 CSV for dedup."""
    keys = set()
    with open(OLD_CSV, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        next(reader)  # skip header
        for row in reader:
            if len(row) < 7:
                continue
            date, dept, name, ticket = row[0].strip(), row[1].strip(), row[2].strip(), row[3].strip()
            key = (date, ticket, name.lower())
            keys.add(key)
    return keys


def load_new_csv():
    """Load new CSV using columns 2-8 (real data)."""
    rows = []
    with open(NEW_CSV, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        next(reader)  # skip header
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
            rows.append({
                'date': date, 'dept': dept, 'name': name,
                'ticket': ticket, 'desc': desc, 'cost': cost, 'status': status
            })
    return rows


def write_sql_files(orders, all_items, all_logs):
    """Write SQL split into manageable files."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Build all SQL lines
    sections = []

    # Orders
    for o in orders:
        dept_sub = f"(SELECT id FROM departments WHERE code = '{o['dept_code']}')" if o['dept_code'] else 'NULL'
        ts = o['created_at'].strftime('%Y-%m-%d 09:00:00+00')
        lines = [
            f"INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)",
            f"VALUES (",
            f"  '{o['id']}',",
            f"  {esc(o['docket'])},",
            f"  '{o['order_type']}',",
            f"  {dept_sub},",
            f"  {esc(o['staff_name'])},",
            f"  {esc(o['guest_name'])},",
            f"  {esc(o['room_number'])},",
            f"  '{o['status']}',",
            f"  {o['total_price'] if o['total_price'] else 'NULL'},",
            f"  '{ts}',",
            f"  '{ts}'",
            f");",
            f""
        ]
        sections.append(('order', lines))

    # Order items
    for oi in all_items:
        item_sub = f"(SELECT id FROM item_catalogue WHERE code = '{oi['item_code']}')" if oi['item_code'] else 'NULL'
        qr = str(oi['qty_recv']) if oi['qty_recv'] is not None else 'NULL'
        pr = str(oi['price']) if oi['price'] is not None else 'NULL'
        lines = [
            f"INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)",
            f"VALUES (",
            f"  '{oi['id']}',",
            f"  '{oi['order_id']}',",
            f"  {item_sub},",
            f"  {esc(oi['item_name'])},",
            f"  {oi['qty_sent']},",
            f"  {qr},",
            f"  {pr}",
            f");",
            f""
        ]
        sections.append(('item', lines))

    # Status logs
    for sl in all_logs:
        ts = sl['created_at'].strftime('%Y-%m-%d %H:%M:%S+00')
        lines = [
            f"INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)",
            f"VALUES (",
            f"  '{sl['id']}',",
            f"  '{sl['order_id']}',",
            f"  '{sl['status']}',",
            f"  {esc(sl['changed_by'])},",
            f"  {esc(sl['reason'])},",
            f"  '{ts}'",
            f");",
            f""
        ]
        sections.append(('log', lines))

    # Split into files
    file_num = 1
    current_lines = ["BEGIN;", ""]
    current_count = 2

    for (stype, lines) in sections:
        if current_count + len(lines) > MAX_LINES:
            current_lines.append("COMMIT;")
            fname = os.path.join(OUTPUT_DIR, f"batch2_{file_num:02d}.sql")
            with open(fname, 'w', encoding='utf-8') as f:
                f.write('\n'.join(current_lines))
            print(f"  Wrote {fname} ({current_count} lines)")
            file_num += 1
            current_lines = ["BEGIN;", ""]
            current_count = 2

        current_lines.extend(lines)
        current_count += len(lines)

    if current_count > 2:
        current_lines.append("COMMIT;")
        fname = os.path.join(OUTPUT_DIR, f"batch2_{file_num:02d}.sql")
        with open(fname, 'w', encoding='utf-8') as f:
            f.write('\n'.join(current_lines))
        print(f"  Wrote {fname} ({current_count} lines)")


def main():
    print("=== BATCH 2 MIGRATION ===\n")

    # 1. Load batch 1 keys
    batch1_keys = load_batch1_keys()
    print(f"Batch 1 records loaded: {len(batch1_keys)}")

    # 2. Load new CSV
    new_rows = load_new_csv()
    print(f"New CSV total rows: {len(new_rows)}")

    # 3. Filter to only NEW records + deduplicate internal duplicates
    new_records = []
    skipped = 0
    seen_keys = set()
    internal_dups = 0
    for r in new_rows:
        key = (r['date'], r['ticket'], r['name'].lower())
        if key in batch1_keys:
            skipped += 1
        elif key in seen_keys:
            internal_dups += 1
            print(f"  Dedup: skipping internal duplicate {key}")
        else:
            seen_keys.add(key)
            new_records.append(r)

    print(f"Already migrated (skipped): {skipped}")
    print(f"Internal duplicates removed: {internal_dups}")
    print(f"NEW records to migrate: {len(new_records)}")

    if not new_records:
        print("Nothing new to migrate!")
        return

    # 4. Process new records
    orders = []
    all_items = []
    all_logs = []
    auto_docket = 5000

    for i, r in enumerate(new_records):
        name = r['name']
        dept = r['dept']
        ticket = r['ticket']
        status_raw = r['status']
        desc = r['desc']

        # Edge case fixes
        if name.isdigit():
            print(f"  Fix: numeric name '{name}' -> '{dept} Staff'")
            name = f"{dept} Staff"
        if name == '?':
            name = 'Unknown Staff'

        # Fix: Docket 7861 — CHEF JACKET x 222 is a typo, should be 2
        if ticket == '7861' and 'CHEF JACKET : 222' in desc:
            desc = desc.replace('CHEF JACKET : 222 x', 'CHEF JACKET : 2 x')
            print(f"  Fix: docket 7861 CHEF JACKET 222 -> 2 (data entry error)")

        # Fix: Claire oki (Loft-RESIDENT) with BLAZER = staff uniform, not guest
        if 'claire' in name.lower() and 'oki' in name.lower() and dept.strip().upper() == 'LOFT -RESIDENT':
            print(f"  Fix: Claire oki (Loft-RESIDENT + BLAZER) -> staff uniform under LFT")
            dept = 'LOFT -STAFF'

        # Guest reclassification
        is_guest_dept = dept.strip().upper() in ('HOTEL -GUEST', 'LOFT -RESIDENT')
        if dept.strip().upper() == 'HOUSEKEEPING' and 'GUEST-OTHER' in desc.upper():
            # Only reclassify if ALL items are GUEST-OTHER
            items_check = parse_items(desc)
            all_guest = all(n == 'GUEST-OTHER' for n, _ in items_check)
            if all_guest:
                print(f"  Fix: {name} (HOUSEKEEPING + GUEST-OTHER) -> guest_laundry")
                dept = 'Hotel -GUEST'
                is_guest_dept = True

        # Parse date
        try:
            dt = datetime.strptime(r['date'], '%d/%m/%Y')
        except ValueError:
            print(f"  Skip: bad date '{r['date']}'")
            continue

        # Status
        status = STATUS_MAP.get(status_raw)
        if not status:
            print(f"  WARNING: unknown status '{status_raw}', defaulting to 'submitted'")
            status = 'submitted'

        # Items
        items = parse_items(desc)
        if not items:
            continue

        # Order type
        order_type = get_order_type(items, dept)
        dept_code = get_dept_code(dept)
        is_guest = is_guest_dept

        # Docket
        docket = ticket if ticket and ticket != '0' else f"MIG2-{auto_docket}"
        if ticket == '0':
            auto_docket += 1

        # Build order
        order_id = str(uuid.uuid4())
        total = 0.0
        order_items = []

        for item_name, qty in items:
            cat = CATALOGUE.get(item_name)
            if cat and cat['price'] is not None:
                price = cat['price']
                total += price * qty
                order_items.append({
                    'id': str(uuid.uuid4()), 'order_id': order_id,
                    'item_code': cat['code'], 'item_name': cat['name'],
                    'qty_sent': qty,
                    'qty_recv': qty if status == 'received' else None,
                    'price': price,
                })
            else:
                order_items.append({
                    'id': str(uuid.uuid4()), 'order_id': order_id,
                    'item_code': None, 'item_name': cat['name'] if cat else item_name,
                    'qty_sent': qty,
                    'qty_recv': qty if status == 'received' else None,
                    'price': None,
                })

        total = round(total, 2)

        orders.append({
            'id': order_id,
            'docket': docket,
            'order_type': order_type,
            'dept_code': dept_code,
            'staff_name': None if is_guest else name,
            'guest_name': name if is_guest else None,
            'room_number': ticket if is_guest else None,
            'status': status,
            'total_price': total if total > 0 else None,
            'created_at': dt,
        })
        all_items.extend(order_items)

        # Status log
        chain = STATUS_CHAINS.get(status, ['submitted'])
        for j, s in enumerate(chain):
            all_logs.append({
                'id': str(uuid.uuid4()),
                'order_id': order_id,
                'status': s,
                'changed_by': 'Migration Import',
                'reason': 'Migrated from external platform (batch 2)' if s == 'submitted' else None,
                'created_at': dt.replace(hour=9, minute=j*5),
            })

    print(f"\nGenerated: {len(orders)} orders, {len(all_items)} items, {len(all_logs)} status logs")

    # 5. Write SQL files
    print("\nWriting SQL files...")
    write_sql_files(orders, all_items, all_logs)

    # 6. Summary
    print(f"\n=== BATCH 2 COMPLETE ===")
    print(f"New orders: {len(orders)}")
    print(f"Date range: {min(o['created_at'] for o in orders).strftime('%d/%m/%Y')} - {max(o['created_at'] for o in orders).strftime('%d/%m/%Y')}")

    # Status breakdown
    from collections import Counter
    sc = Counter(o['status'] for o in orders)
    for s, c in sc.most_common():
        print(f"  {s}: {c}")


if __name__ == '__main__':
    main()
