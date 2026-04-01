-- Migration 032: Ensure chat_keys table exists
CREATE TABLE IF NOT EXISTS chat_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    keyword TEXT NOT NULL,
    response TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
