"""Validate all nine embedded question assets; optionally verify APK bytes and export."""
import collections, json, pathlib, sys, unicodedata, zipfile
folder=pathlib.Path(sys.argv[1])
def norm(s): return " ".join(unicodedata.normalize("NFC",s).split()).lower()
rows=[]; ids=set(); stems=set(); counts=collections.Counter()
for grade in range(1,10):
    path=folder/f"grade-{grade}.json"
    items=json.loads(path.read_text(encoding="utf-8"))
    assert isinstance(items,list) and len(items)==600, path
    for q in items:
        assert all(isinstance(q[k],str) and q[k].strip() for k in ("id","subject","topic","difficulty","question","explanation")), q["id"]
        assert type(q["grade"]) is int and q["grade"]==grade
        assert q["difficulty"] in ("leicht","mittel","schwer")
        assert "mathematik" not in q["subject"].lower()
        assert len(q["options"])==4 and all(isinstance(x,str) and x.strip() for x in q["options"])
        assert len({norm(x) for x in q["options"]})==4
        assert type(q["correct_index"]) is int and 0<=q["correct_index"]<4
        if "correct_answer" in q: assert q["options"][q["correct_index"]]==q["correct_answer"] or q["topic"]=="Wortarten" and norm(q["options"][q["correct_index"]])==norm(q["correct_answer"])
        assert q["id"] not in ids and norm(q["question"]) not in stems, q["id"]
        ids.add(q["id"]); stems.add(norm(q["question"])); counts[grade]+=1; rows.append(q)
assert len(rows)==5400 and len(ids)==5400 and len(stems)==5400
if len(sys.argv)>2:
    with zipfile.ZipFile(sys.argv[2]) as z:
        for grade in range(1,10):
            name=f"grade-{grade}.json"
            assert z.read(f"assets/bank/{name}")== (folder/name).read_bytes(), name
if len(sys.argv)>3:
    pathlib.Path(sys.argv[3]).write_text(json.dumps(rows,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(f"{len(rows)} questions validated; per grade: {dict(sorted(counts.items()))}")
