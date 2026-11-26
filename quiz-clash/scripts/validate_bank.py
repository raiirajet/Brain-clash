"""Validate the embedded bank; the current source is explicitly a 27-item demo."""
import collections, json, pathlib, sys
rows=json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert isinstance(rows,list) and rows, "Empty bank"
ids=set()
stems=set()
counts=collections.Counter()
for q in rows:
    assert all(isinstance(q[k],str) and q[k].strip() for k in ("id","subject","topic","difficulty","question","explanation"))
    assert type(q["grade"]) is int and 1<=q["grade"]<=9
    assert q["difficulty"] in ("leicht","mittel","schwer")
    assert len(q["options"]) in (2,4)
    assert all(isinstance(x,str) and x.strip() for x in q["options"])
    assert len(set(x.strip().casefold() for x in q["options"]))==len(q["options"])
    assert type(q["correct_index"]) is int and 0<=q["correct_index"]<len(q["options"])
    assert q["id"] not in ids
    key=(q["grade"],q["subject"].casefold(),q["question"].strip().casefold())
    assert key not in stems
    ids.add(q["id"]);stems.add(key);counts[q["grade"]]+=1
assert set(counts)==set(range(1,10))
print(f"{len(rows)} questions validated; per grade: {dict(sorted(counts.items()))}")
