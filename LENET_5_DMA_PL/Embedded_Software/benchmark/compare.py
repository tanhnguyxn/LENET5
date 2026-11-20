"""Compare mean timings of matched CSVs, always relative to PIO."""
import argparse
import csv
from statistics import mean

def read(path):
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    if not rows or any(r["mode"] != rows[0]["mode"] for r in rows):
        raise ValueError(f"{path}: empty or mixed modes")
    return rows[0]["mode"], rows

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("csv", nargs="+")
a = p.parse_args()
runs = dict(read(path) for path in a.csv)
if "pio" not in runs or len(runs) != len(a.csv) or len(runs) < 2:
    p.error("Provide one PIO CSV plus one ZDMA and/or CDMA CSV")
baseline = runs["pio"]
for mode, rows in runs.items():
    if len(rows) != len(baseline) or any(
        any(x[key] != y[key] for key in ("index","label","pred"))
        for x,y in zip(baseline, rows)
    ):
        raise ValueError(f"{mode}: image sequence or predictions differ")
print("metric,mode,mean_us,speedup_vs_pio")
for k in ("upload_us","start_done_us","read_us","total_us"):
    reference = mean(float(r[k]) for r in baseline)
    for mode, rows in runs.items():
        value = mean(float(r[k]) for r in rows)
        ratio = f"{reference/value:.3f}" if value else "NA"
        print(f"{k},{mode},{value:.3f},{ratio}")
