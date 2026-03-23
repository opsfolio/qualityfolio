
import os
import re

search_dir = r"d:\QF_SQLPAGE"
pattern = re.compile(r"Select All", re.IGNORECASE)

for root, dirs, files in os.walk(search_dir):
    for file in files:
        if file.endswith((".sql", ".js", ".html")):
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    for i, line in enumerate(f, 1):
                        if pattern.search(line):
                            print(f"{path}:{i}: {line.strip()}")
            except:
                pass
