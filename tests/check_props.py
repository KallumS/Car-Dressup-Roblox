# Checks every "PROP|Class.Property" line on stdin against a Roblox API dump.
import json, sys
dump = json.load(open(sys.argv[1]))
classes = {c["Name"]: c for c in dump["Classes"]}

def props(name):
    out = {}
    while name in classes:
        for m in classes[name]["Members"]:
            if m["MemberType"] == "Property":
                out[m["Name"]] = m
        name = classes[name].get("Superclass")
    return out

bad = []
keys = {l.strip()[5:] for l in sys.stdin if l.startswith("PROP|")}
for key in sorted(keys):
    cls, prop = key.split(".", 1)
    if prop.startswith("__"):
        continue
    member = props(cls).get(prop)
    tags = (member or {}).get("Tags") or []
    if member is None or "ReadOnly" in tags or "NotScriptable" in tags or "Deprecated" in tags:
        bad.append(key)
print(f"property audit: {len(keys)} writes checked, {len(bad)} problems {bad if bad else ''}")
sys.exit(1 if bad else 0)
