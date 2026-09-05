import os
plan_path = os.path.join(os.path.expanduser(chr(126)), chr(46)+"claude", "plans", "import-subjectsegmentation-dynamic-clover-agent-a481a5b294954e2b5.md")
content = ""
# Will be populated by sections
sections = []
# Section 1
sections.append("# Vivid Mask Toning Integration Plan

")
with open(plan_path, "w", encoding="utf-8") as out:
    out.write("
".join([s for s in sections]))
print("Done", os.path.getsize(plan_path))
