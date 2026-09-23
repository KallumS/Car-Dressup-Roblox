# Bundles the repo's Luau modules + a mock Roblox runtime into one file the
# plain `luau` CLI can execute.
import os, sys
repo = sys.argv[1]; out = sys.argv[2]; tests = sys.argv[3]
roots = {"ReplicatedStorage/Shared": "src/shared", "ServerScriptService/Server": "src/server", "StarterPlayer/StarterPlayerScripts/Client": "src/client"}
mods = []
for inst, rel in roots.items():
    base = os.path.join(repo, rel)
    for dp, _, files in os.walk(base):
        for f in files:
            if not f.endswith(".luau"): continue
            full = os.path.join(dp, f)
            sub = os.path.relpath(full, base)[:-5]
            parts = [] if sub in ("init", "init.server", "init.client") else sub.split(os.sep)
            if parts and parts[-1] == "init": parts = parts[:-1]
            path = "/".join([inst] + parts)
            src = open(full).read().replace("\nexport type ", "\ntype ")
            if src.startswith("export type "): src = src[7:]
            mods.append((path, src))
with open(out, "w") as o:
    o.write(open(os.path.join(os.path.dirname(__file__), "mock.luau")).read())
    for path, src in mods:
        o.write(f'\nMODULES["{path}"] = function(script)\n{src}\nend\n')
    extras = sys.argv[4:]
    for extra in [e for e in extras if "mock" in e]:
        o.write(open(extra).read())
    o.write(open(tests).read())
    for extra in [e for e in extras if "mock" not in e]:
        o.write(open(extra).read())
print("bundled", len(mods), "modules")
