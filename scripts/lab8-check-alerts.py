import json,sys,urllib.request
u=sys.argv[1]
with urllib.request.urlopen(u, timeout=5) as r:
    d=json.load(r)
alerts=d.get("data",{}).get("alerts",[])
if not alerts:
    # also try rules API for state
    print("alerts: none")
else:
    for a in alerts:
        print(a["labels"].get("alertname"), a["state"])
