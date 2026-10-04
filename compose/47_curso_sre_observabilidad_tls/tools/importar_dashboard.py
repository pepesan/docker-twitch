#!/usr/bin/env python3
"""Normaliza un dashboard de grafana.com para provisionarlo y quita los
paneles sin datos que no pueden funcionar en este stack.

importar_dashboard.py origen.json destino.json --dump=vacios.json [--keep=1,2] [--drop=3,4]
  --keep: ids de paneles sin datos que se conservan (solo están inactivos)
  --drop: ids adicionales a quitar
"""
import json, sys, re

src, dst = sys.argv[1], sys.argv[2]
arg = lambda n: next((a.split("=", 1)[1] for a in sys.argv if a.startswith(n + "=")), "")
keep = {int(x) for x in arg("--keep").split(",") if x and x != "all"}
extra = {int(x) for x in arg("--drop").split(",") if x}
empty = json.load(open(arg("--dump"))) if arg("--dump") else []
keepall = "all" in arg("--keep").split(",")
drop = (set() if keepall else ({e["id"] for e in empty} - keep)) | extra

d = json.load(open(src))
varnames = {v["name"] for v in d.get("templating", {}).get("list", [])}
DS = {"prometheus": ("prometheus", "Prometheus"), "loki": ("loki", "Loki")}

def fix_ds(o):
    if isinstance(o, dict):
        for k, v in list(o.items()):
            if k == "datasource":
                if isinstance(v, str):
                    m = re.fullmatch(r"\$\{(DS_[\w-]+)\}", v)
                    if m and m.group(1) not in varnames:
                        o[k] = "Loki" if "LOKI" in v.upper() else "Prometheus"
                elif isinstance(v, dict):
                    u = v.get("uid", "")
                    m = re.fullmatch(r"\$\{(DS_[\w-]+)\}", u or "")
                    if m and m.group(1) not in varnames:
                        v["uid"] = "loki" if "LOKI" in u.upper() else "prometheus"
                        v["type"] = "loki" if "LOKI" in u.upper() else "prometheus"
            fix_ds(o[k])
    elif isinstance(o, list):
        for x in o:
            fix_ds(x)

removed = []
def prune(items):
    out = []
    for p in items:
        if p.get("id") in drop and p.get("type") != "row":
            removed.append(p.get("title", "?"))
            continue
        if p.get("panels"):
            p["panels"] = prune(p["panels"])
        out.append(p)
    return out

d["panels"] = prune(d.get("panels", []))
for r in d.get("rows", []):
    r["panels"] = prune(r.get("panels", []))
# filas vacías fuera (formato plano: una fila sin paneles hasta la siguiente fila)
flat = d["panels"]
res, i = [], 0
while i < len(flat):
    p = flat[i]
    if p.get("type") == "row" and not p.get("panels"):
        j = i + 1
        while j < len(flat) and flat[j].get("type") != "row":
            j += 1
        if j == i + 1:      # fila sin ningún panel debajo
            removed.append(f"[fila] {p.get('title')}")
            i = j
            continue
    res.append(p); i += 1
d["panels"] = res
d.pop("__inputs", None); d.pop("__requires", None); d.pop("__elements", None)
d["id"] = None
fix_ds(d)
json.dump(d, open(dst, "w"), indent=1, ensure_ascii=False)
print(f"{d['title']}: quitados {len(removed)} paneles")
for t in sorted(set(removed)): print("  -", t[:70])
