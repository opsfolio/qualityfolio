import requests
import sqlite3
import time
import os  # ✅ Add os for basename
import sys
from dotenv import load_dotenv

load_dotenv()
repo = os.environ.get("GITHUB_REPOSITORY")

if not repo:
    print("❌ Error: GITHUB_REPOSITORY environment variable is not set. Please provide it in your .env file.")
    sys.exit(1)

start_date = os.environ.get("GITHUB_START_DATE")
if not start_date:
    print("❌ Error: GITHUB_START_DATE environment variable is not set. Please provide it in your .env file.")
    sys.exit(1)

DB = "resource-surveillance.sqlite.db"

conn = sqlite3.connect(DB)
cur = conn.cursor()

# Defensive cleanup: if github_commits exists as a TABLE (erroneously created), drop it
cur.execute("SELECT type FROM sqlite_master WHERE name='github_commits'")
row = cur.fetchone()
if row and row[0] == 'table':
    print("🧹 Dropping erroneously created github_commits table")
    cur.execute("DROP TABLE github_commits")
    conn.commit()

# Ensure minimal github_commits view exists if singer didn't run
cur.execute("""
    CREATE VIEW IF NOT EXISTS github_commits AS 
    SELECT NULL AS id, NULL AS sha, '{}' AS "commit", NULL AS html_url, '[]' AS files WHERE 1=0
""")

if start_date:
    cur.execute("""
        SELECT sha 
        FROM github_commits 
        WHERE json_extract("commit", '$.author.date') >= ?
    """, (start_date,))
else:
    cur.execute("SELECT sha FROM github_commits")

all_commits = [row[0] for row in cur.fetchall()]

print(f"{len(all_commits)} commits to process...")

for commit_sha in all_commits:
    print(f"\nProcessing commit: {commit_sha}")

    try:
        url = f"https://api.github.com/repos/{repo}/commits/{commit_sha}"
        
        headers = {}
        github_token = os.environ.get("GITHUB_ACCESS_TOKEN")
        if github_token:
            headers["Authorization"] = f"Bearer {github_token}"
            
        res = requests.get(url, headers=headers)

        if res.status_code != 200:
            print(f"❌ Failed to fetch commit {commit_sha}: {res.status_code} - {res.text}")
            continue

        data = res.json()

    except Exception as e:
        print(f"❌ Exception fetching commit {commit_sha}: {e}")
        continue

    files = data.get("files", [])
    if not files:
        print(f"No files in commit {commit_sha}")
        continue

    for f in files:
        try:
            full_path = f.get("filename", "")
            filename = os.path.basename(full_path)  # ✅ Extract only the file name

            # Only .md files
            if not filename.lower().endswith(".md"):
                continue

            raw_url = f.get("raw_url")
            if not raw_url:
                print(f"⚠️ Missing raw_url for {filename}")
                continue

            # 🔥 Proper response check
            file_res = requests.get(raw_url)

            if file_res.status_code != 200:
                print(f"❌ Failed to fetch file {filename}: {file_res.status_code}")
                continue

            content = file_res.text

            # Check duplicate
            cur.execute("""
                SELECT 1 FROM commit_files 
                WHERE commit_sha = ? AND filename = ?
            """, (commit_sha, filename))

            if cur.fetchone():
                print(f"⏭️ Skipping duplicate: {filename}")
                continue

            # Insert
            cur.execute("""
                INSERT INTO commit_files (
                    commit_sha, filename, status, additions, deletions, patch, file_details
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                commit_sha,
                filename,
                f.get("status"),
                f.get("additions"),
                f.get("deletions"),
                f.get("patch", ""),
                content
            ))

            print(f"✅ Saved: {filename}")

        except Exception as e:
            # 🔥 Critical: NEVER break the loop
            print(f"❌ Error processing file {f.get('filename')}: {e}")
            continue

    time.sleep(0.5)

conn.commit()
conn.close()

print("\n✅ All commits processed.")