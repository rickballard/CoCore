#!/usr/bin/env python3
import json, math, sys, argparse, pathlib
def geom_weighted(components, weights):
    s = sum(weights.values())
    if s <= 0: raise ValueError("weights sum must be > 0")
    w = {k: v/s for k,v in weights.items()}
    score = 1.0
    for k, wk in w.items():
        if k not in components: raise ValueError(f"component '{k}' missing")
        x = float(components[k])
        if not (0.0 <= x <= 1.0): raise ValueError(f"component '{k}' out of range: {x}")
        score *= x ** wk
    return score
def calc_record(rec):
    weights = rec.get("weights", {})
    comps   = rec.get("outputs", {}).get("components", {})
    base = geom_weighted(comps, weights)
    penalty = rec.get("penalty", 1.0)
    try: penalty = float(penalty)
    except: penalty = 1.0
    penalty = max(0.0, min(1.0, penalty))
    return base, base*penalty
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--tol", type=float, default=0.05)
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--strict", action="store_true")
    args = ap.parse_args()
    ok = True
    for f in args.files:
        p = pathlib.Path(f)
        rec = json.loads(p.read_text(encoding="utf-8"))
        base, computed = calc_record(rec)
        stored = rec.get("outputs", {}).get("score")
        diff = None if stored is None else abs(float(stored) - computed)
        print(f"[{p}] base={base:.6f} computed={computed:.6f} stored={stored}")
        if args.write:
            rec.setdefault("outputs", {})["score"] = round(computed, 6)
            p.write_text(json.dumps(rec, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        if stored is not None and (diff is None or diff > args.tol): ok = False
    if not ok and args.strict: sys.exit(1)
    print("OK" if ok else "DIFF>tol"); sys.exit(0 if ok else 1)
if __name__ == "__main__": main()
