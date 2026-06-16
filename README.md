# EOD vs Dropcopy Validation

## Purpose

Validate overnight positions generated in EOD files against Dropcopy EOD positions.

The script compares all non-zero positions and sends an HTML email report showing:

* Token
* Symbol
* Dropcopy Quantity
* EOD Quantity
* Status

## Key Fixes

### Zero Quantity Handling

Previous logic generated false mismatches such as:

| Token | Dropcopy | EOD | Status      |
| ----- | -------- | --- | ----------- |
| 62802 | MISSING  | 0   | MISSING_EOD |

This occurred because Dropcopy skipped zero positions while EOD included them.

The updated logic ignores zero quantities on both sides:

* EOD `qty_overnight == 0` → skipped
* Dropcopy `net_qty == 0` → skipped

This removes false:

* MISSING_EOD
* ONLY_EOD
* MISMATCH

records caused by zero positions.

---

## Email Output

The report is sent as an HTML email and includes:

* Validation summary
* Total positions checked
* Total issues found
* Color-coded status
* Structured table format

### Status Values

| Status      | Meaning                                |
| ----------- | -------------------------------------- |
| OK          | Position matches                       |
| MISSING_EOD | Present in Dropcopy but missing in EOD |
| ONLY_EOD    | Present in EOD but missing in Dropcopy |
| MISMATCH    | Quantity mismatch                      |

---

## Execution

Manual run:

```bash
/home/report/devstudio/Prashant/Live_Dashboard/venv/bin/python3 \
validate_eod_vs_dropcopy_final_table.py 20260612
```

---

## Cron

```cron
30 21 * * 1-5 cd /home/report/devstudio/Prashant/Live_Dashboard/Prod && \
/home/report/devstudio/Prashant/Live_Dashboard/venv/bin/python3 \
validate_eod_vs_dropcopy_final_table.py $(date +\%Y\%m\%d) \
>> validate_eod_vs_dropcopy_final_table.log 2>&1
```

---

## Success Criteria

Validation passes when:

* Every non-zero Dropcopy position exists in EOD.
* Quantities match exactly.
* No stale Dropcopy file is detected.
* Email report is generated successfully.

Result:

```text
Total checked: 17
Issues: 0
Status: SUCCESS
```
