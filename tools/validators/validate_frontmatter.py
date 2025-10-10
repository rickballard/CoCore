import sys, yaml
req = ["title","version","authors","urn","layer","tags","maturity","readiness","jurisdictions","congruence_ref","provenance_ref","warning_gate"]
raw = open(sys.argv[1], "r", encoding="utf-8").read()
parts = raw.split("---")
if len(parts) < 3:
    print("MISSING: YAML front matter"); raise SystemExit(1)
doc = yaml.safe_load(parts[1])
missing = [k for k in req if k not in doc]
if missing:
    print("MISSING:", ",".join(missing)); raise SystemExit(1)
print("OK")
