#!/bin/bash
# verify_cpnl.sh — manually verify dashboard C PNL vs formula
# Usage: ./verify_cpnl.sh

echo "Fetching live positions from Redis..."
echo

redis-cli -n 1 GET dashboard:positions:latest2 | python3 -c "
import json, sys

data = json.load(sys.stdin)
print(f'As of : {data[\"as_of\"]}')
print(f'Source: {data.get(\"source\",\"?\")}  |  EOD date: {data.get(\"eod_date\",\"?\")}')
print()

rows = []
for st in data['positions']:
    for e in st['expiries']:
        qty  = e['qty_overnight']
        pc   = e['prev_close']
        ltp  = e['ltp']
        dash = qty * (ltp - pc)   # recalc from raw fields
        rows.append((st['sym'], qty, pc, ltp, dash))

print(f\"{'Symbol':<14} {'Qty_ON':>7} {'PrevClose':>10} {'LTP':>10} {'Calc C PNL':>12}  Status\")
print('-' * 65)

total = 0
issues = 0
for sym, qty, pc, ltp, calc in rows:
    if qty == 0:
        continue
    total += calc
    if calc > 0:
        status = '🟢'
    elif calc < 0:
        status = '🔴'
    else:
        status = '  '
    print(f'{sym:<14} {qty:>7.0f} {pc:>10.2f} {ltp:>10.2f} {calc:>+12,.0f}  {status}')

print('-' * 65)
print(f'  {\"TOTAL C PNL\":<40} {total:>+12,.0f}')
print()

# Compare with dashboard header
import subprocess
raw = subprocess.run(['redis-cli','-n','1','GET','dashboard:positions:latest2'],
                    capture_output=True, text=True)
d2 = json.loads(raw.stdout)
positions_list = d2['positions']
dash_total = sum(
    e['qty_overnight'] * (e['ltp'] - e['prev_close'])
    for st in positions_list
    for e in st['expiries']
)
print(f'  Formula total   = {total:>+12,.2f}')
print(f'  Dashboard total = {dash_total:>+12,.2f}')
diff = total - dash_total
print(f'  Difference      = {diff:>+12,.2f}  {\"✅ OK\" if abs(diff) < 100 else \"⚠️ CHECK\"}')
"
