#!/usr/bin/env python3
"""Verifica que cada consulta de un dashboard de Grafana devuelva datos.

Resuelve las variables de plantilla contra Prometheus/Loki reales, sustituye
los builtins ($__rate_interval...) y ejecuta cada target como consulta
instantánea. Uso: verificar_dashboard.py dashboard.json [--set=var=valor] [--max=N]
"""
import json, re, sys, time, urllib.parse, urllib.request

PROM = "http://localhost:9090"
LOKI = "http://localhost:3100"
verbose = "--verbose" in sys.argv


def get(url, params=None):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=30) as r:
        return json.load(r)


def prom_q(expr, t=None):
    return get(PROM + "/api/v1/query", {"query": expr})


def label_values(expr, label):
    # expr puede ser "" (todas las series), un metric o un selector
    if expr:
        d = get(PROM + "/api/v1/series", {"match[]": expr})
        return sorted({s[label] for s in d["data"] if label in s})
    return get(PROM + f"/api/v1/label/{label}/values")["data"]


def fmt_result(r):
    lab = ",".join(f'{k}="{v}"' for k, v in r["metric"].items() if k != "__name__")
    return f'{r["metric"].get("__name__", "")}{{{lab}}} {r["value"][1]} {int(r["value"][0])*1000}'


BUILTIN = {
    "__rate_interval": "2m", "__interval": "1m", "__range": "1h", "__range_s": "3600",
    "__interval_ms": "60000", "__range_ms": "3600000", "__auto_interval": "1m",
    "__from": str(int((time.time() - 3600) * 1000)), "__to": str(int(time.time() * 1000)),
    "__dashboard": "check", "__org": "1",
}


def subst(text, vars_):
    if not isinstance(text, str):
        return text
    # Como el datasource de Prometheus de Grafana: variable multivalor/All con
    # `=`/`!=` -> `=~`/`!~`
    for n in MULTI:
        text = re.sub(r'(?<![=!~<>])(!?)=\s*"(\$\{?' + n + r'\}?)"', lambda m: ('!~' if m.group(1) else '=~') + '"' + m.group(2) + '"', text)
    allv = {**BUILTIN, **vars_}
    # ${var:fmt}
    def m1(m):
        n = m.group(1)
        return allv.get(n, m.group(0))
    text = re.sub(r"\$\{(\w+)(?::\w+)?\}", m1, text)
    text = re.sub(r"\[\[(\w+)(?::\w+)?\]\]", m1, text)
    for n in sorted(allv, key=len, reverse=True):
        text = re.sub(r"\$" + re.escape(n) + r"(?!\w)", lambda _m, n=n: allv[n], text)
    return text


MULTI = set()


def resolve_vars(d):
    out, notes = {}, []
    for v in d.get("templating", {}).get("list", []):
        n, t = v["name"], v["type"]
        val = None
        if t == "datasource":
            val = "ds"
        elif t in ("interval",):
            opts = [o["value"] for o in v.get("options", [])] or str(v.get("query", "5m")).split(",")
            val = next((o for o in opts if o not in ("auto",)), "5m")
        elif t == "custom":
            opts = [o["value"] for o in v.get("options", [])] or str(v.get("query", "")).split(",")
            cur = v.get("current", {}).get("value")
            val = cur if isinstance(cur, str) and cur else (opts[0] if opts else "")
        elif t == "constant":
            val = v.get("query", "")
        elif t == "textbox":
            val = v.get("query", "") or v.get("current", {}).get("value", "")
        elif t == "query":
            q = v.get("query")
            q = q.get("query") if isinstance(q, dict) else q
            q = subst(q or "", out)
            vals = []
            try:
                dsr = json.dumps(v.get("datasource"))
                if "loki" in dsr.lower() or "DS_LOKI" in dsr:
                    m = re.match(r"label_values\((?:.*,\s*)?(\w+)\)", q)
                    if m:
                        vals = get(LOKI + f"/loki/api/v1/label/{m.group(1)}/values")["data"]
                else:
                    m = re.match(r"label_values\((.*),\s*(\w+)\)$", q, re.S)
                    m0 = re.match(r"label_values\((\w+)\)$", q)
                    mq = re.match(r"query_result\((.*)\)$", q, re.S)
                    if m:
                        vals = label_values(m.group(1).strip(), m.group(2))
                    elif m0:
                        vals = label_values("", m0.group(1))
                    elif mq:
                        res = prom_q(mq.group(1))["data"]["result"]
                        txt = [fmt_result(r) for r in res]
                        rx = v.get("regex")
                        if rx:
                            rx = rx.strip("/")
                            for s in txt:
                                mm = re.search(rx, s)
                                if mm:
                                    vals.append(mm.group(1) if mm.groups() else mm.group(0))
                        else:
                            vals = txt
                    elif q.startswith("metrics(") or q.startswith("label_names("):
                        vals = []
                    elif q and re.match(r"^[\w:{}=~!\",.\s-]+$", q):
                        # «series query» (tipo 4 del editor de variables de Grafana):
                        # devuelve las series como texto; la regex extrae el valor
                        series = get(PROM + "/api/v1/series", {"match[]": q})["data"]
                        txt = [s_.get("__name__", "") + "{" + ",".join(f'{k}="{v_}"' for k, v_ in s_.items() if k != "__name__") + "}" for s_ in series]
                        rx = v.get("regex")
                        if rx:
                            for s_ in txt:
                                mm = re.search(rx.strip("/"), s_)
                                if mm:
                                    vals.append(mm.group(1) if mm.groups() else mm.group(0))
                        else:
                            vals = txt
            except Exception as e:
                notes.append(f"var {n}: error resolviendo '{q[:60]}': {e}")
            rx = v.get("regex")
            if rx and t == "query" and not q.startswith("query_result") and not re.match(r"^[\w:]+(\{.*\})?$", q):
                try:
                    vals = [x for x in vals if re.search(rx.strip("/"), x)]
                except re.error:
                    pass
            if not vals:
                notes.append(f"var {n}: SIN VALORES ({q[:70]})")
                val = ""
            elif v.get("multi") and v.get("includeAll"):
                val = v.get("allValue") or ".+"
                MULTI.add(n)
            else:
                val = vals[0]
        out[n] = val if val is not None else ""
    return out, notes


def flatten(d):
    ps = []
    def walk(items):
        for p in items:
            if p.get("type") == "row":
                walk(p.get("panels", []))
            else:
                ps.append(p)
                if p.get("panels"):
                    walk(p["panels"])
    walk(d.get("panels", []))
    for r in d.get("rows", []):
        walk(r.get("panels", []))
    return ps


def ds_kind(p, t):
    for x in (t.get("datasource"), p.get("datasource")):
        s = json.dumps(x) if x else ""
        if "loki" in s.lower() or "LOKI" in s:
            return "loki"
        if "tempo" in s.lower():
            return "tempo"
        if s and "grafana" in s.lower() and "prom" not in s.lower():
            return "grafana"
    return "prom"


def main():
    d = json.load(open(sys.argv[1]))
    vars_, notes = resolve_vars(d)
    for a in sys.argv:
        if a.startswith('--set='):
            k, v = a[6:].split('=', 1); vars_[k] = v
    print(f"# {d['title']}  (vars: " + ", ".join(f"{k}={str(v)[:24]!r}" for k, v in vars_.items() if not k.startswith('ds')) + ")")
    for n in notes:
        print("  NOTA", n)
    ok = empty = err = 0
    seen, shown = set(), 0
    panel_res = {}
    MAXL = int(next((a.split('=')[1] for a in sys.argv if a.startswith('--max=')), 12))
    for p in flatten(d):
        if p.get("type") in ("text", "news", "dashlist", "row", "welcome", "alertlist"):
            continue
        for t in p.get("targets", []):
            expr = t.get("expr") or t.get("query") or ""
            if not expr or t.get("hide"):
                continue
            kind = ds_kind(p, t)
            if kind in ("tempo", "grafana"):
                continue
            e = subst(expr, vars_)
            state, detail = "OK", ""
            try:
                if kind == "loki":
                    now = int(time.time() * 1e9)
                    r = get(LOKI + "/loki/api/v1/query_range", {"query": e, "limit": 5, "start": now - 3600 * 10**9, "end": now})
                    n = len(r["data"]["result"])
                else:
                    r = prom_q(e)
                    res = r["data"]["result"]
                    n = len(res)
                    if n and all(x.get("value", ["", "NaN"])[1] in ("NaN",) for x in res if "value" in x):
                        state, detail = "NaN", ""
                if n == 0:
                    state = "VACÍO"
            except urllib.error.HTTPError as ex:
                state, detail = "ERROR", ex.read().decode()[:160].replace("\n", " ")
            except Exception as ex:
                state, detail = "ERROR", str(ex)[:160]
            if state == "OK":
                ok += 1
            elif state == "VACÍO" or state == "NaN":
                empty += 1
            else:
                err += 1
            panel_res.setdefault((p.get('id'), p.get('title','?')), []).append((state, e, detail))
            key = (p.get('title'), e)
            if False:
                print(f"  [{state}] {p.get('title','?')[:44]!r}: {e[:110]}{(' -> ' + detail) if detail else ''}")
    bad = 0
    partial = 0
    for (pid, title), res in panel_res.items():
        states = [r[0] for r in res]
        if all(x != "OK" for x in states):
            bad += 1
            if shown < MAXL:
                shown += 1
                print(f"  [PANEL SIN DATOS] #{pid} {title[:50]!r} ({states[0]}) {res[0][1][:90]} {res[0][2][:100]}")
        elif any(x != "OK" for x in states):
            partial += 1
    dump = next((a.split('=',1)[1] for a in sys.argv if a.startswith('--dump=')), None)
    if dump:
        json.dump([{"id": pid, "title": t, "state": res[0][0]} for (pid, t), res in panel_res.items() if all(x[0] != "OK" for x in res)], open(dump, "w"), ensure_ascii=False, indent=1)
    print(f"  RESUMEN: {len(panel_res)} paneles con consultas: {len(panel_res)-bad} con datos, {bad} SIN datos; {partial} con alguna serie vacía (parcial)  [consultas: {ok} OK/{empty} vacías/{err} error]\n")


main()
